import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_api.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/en1_bootstrap_models.dart';
import 'package:eposone/src/features/platform/domain/provisioning_config.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';

/// Device Bootstrap Hito 2: `GET /api/v1/devices/bootstrap` + persistencia local.
///
/// No toca pantallas del POS Core; no usa `/api/eposone/*` (BackOffice).
class En1BootstrapRepository {
  En1BootstrapRepository({
    required Isar isar,
    En1BootstrapApi? api,
  })  : _isar = isar,
        _api = api ?? En1BootstrapApi();

  final Isar _isar;
  final En1BootstrapApi _api;

  static const _prefsDoneKey = 'en1_bootstrap_done_v1';
  static const _prefsMetaKey = 'en1_bootstrap_product_meta_v1';
  static const _prefsAtKey = 'en1_bootstrap_completed_at_v1';
  static const _prefsConfigKey = 'en1_bootstrap_config_json_v1';

  Future<bool> isBootstrapDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsDoneKey) == true;
  }

  Future<DateTime?> lastBootstrapAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Device Token del register + Base URL del provisioning.
  Future<En1BootstrapResult> runBootstrap({
    String? apiBaseUrl,
    String? accessToken,
  }) async {
    final provisioned = await ProvisioningStore.loadConfig();
    final base = (apiBaseUrl ?? provisioned?.apiBaseUrl ?? '').trim();
    final token = (accessToken ?? provisioned?.accessToken ?? '').trim();
    if (base.isEmpty || token.isEmpty) {
      throw En1BootstrapException(
        'Dispositivo no provisionado. Conecta EasyNodeOne (Device Token requerido).',
      );
    }

    final payload = await _api.fetchBootstrap(
      apiBaseUrl: base,
      accessToken: token,
    );
    final products = payload.products;
    if (products.isEmpty) {
      throw En1BootstrapException(
        'EN1 bootstrap no devolvió productos. Verifica Device Token y org Itsmo (org 5).',
      );
    }

    // Config del bootstrap (opcional)
    if (payload.config != null && provisioned != null) {
      await _mergeBootstrapConfig(provisioned, payload.config!, base);
    }
    final prefsEarly = await SharedPreferences.getInstance();
    if (payload.config != null) {
      await prefsEarly.setString(_prefsConfigKey, jsonEncode(payload.config));
    }

    final docs = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docs.path}/en1_product_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final categoryByName = <String, Category>{};
    var categoryCount = 0;
    var imageOk = 0;
    var imageFail = 0;
    final meta = <String, Map<String, dynamic>>{};
    final stockByRef = <String, double>{
      for (final b in payload.stockBalances) b.productRef: b.available,
    };
    for (final p in products) {
      if (p.stockAvailable != null) {
        stockByRef.putIfAbsent(p.productRef, () => p.stockAvailable!);
      }
    }

    final uniqueCats = products
        .map((p) => p.category?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    await _isar.writeTxn(() async {
      var order = 0;
      for (final name in uniqueCats) {
        final localId = 'en1_cat_${_slug(name)}';
        final existing = await _isar.categorys.filter().localIdEqualTo(localId).findFirst();
        final now = DateTime.now();
        final cat = Category(
          localId: localId,
          serverId: localId,
          syncStatus: SyncStatus.synced,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          name: name,
          sortOrder: order++,
        );
        await _isar.categorys.put(cat);
        categoryByName[name] = cat;
        categoryCount++;
      }
    });

    await _isar.writeTxn(() async {
      for (final remote in products) {
        final catId = remote.category != null ? categoryByName[remote.category!]?.localId : null;
        final localId = 'en1_${remote.productRef}';
        final existing =
            await _isar.products.filter().localIdEqualTo(localId).findFirst() ??
                await _isar.products.filter().skuEqualTo(remote.productRef).findFirst();

        meta[remote.productRef] = {
          'tracks_inventory': remote.tracksInventory,
          'uom': remote.uom,
          'purchase_uom': remote.purchaseUom,
          'pack_factor': remote.packFactor,
          'max_stock': remote.maxStock,
          'product_type': remote.productType,
          'image_url': remote.imageUrl,
          'currency': remote.currency,
        };

        final stock = stockByRef[remote.productRef] ?? existing?.stock ?? 0;
        final now = DateTime.now();
        final product = Product(
          localId: localId,
          serverId: remote.productRef,
          syncStatus: SyncStatus.synced,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          name: remote.name,
          barcode: remote.barcode,
          sku: remote.productRef,
          description: remote.description,
          price: remote.unitPrice,
          cost: remote.costPrice,
          stock: stock,
          categoryId: catId,
          imagePath: existing?.imagePath,
          isActive: remote.isActive,
          minStockAlert: remote.minStock,
        );
        await _isar.products.put(product);
      }
    });

    for (final remote in products) {
      if (remote.imageUrl == null || remote.imageUrl!.isEmpty) continue;
      final ext = _extFromUrl(remote.imageUrl!);
      final dest = '${imagesDir.path}/${remote.productRef}$ext';
      final ok = await _api.downloadImage(
        apiBaseUrl: base,
        imageUrl: remote.imageUrl!,
        destPath: dest,
      );
      if (ok) {
        imageOk++;
        await _isar.writeTxn(() async {
          final p =
              await _isar.products.filter().localIdEqualTo('en1_${remote.productRef}').findFirst();
          if (p != null) {
            await _isar.products.put(p.copyWith(imagePath: dest, updatedAt: DateTime.now()));
          }
        });
      } else {
        imageFail++;
      }
    }

    // Desactivar seed Istmo local
    await _isar.writeTxn(() async {
      final istmo = await _isar.products.filter().localIdStartsWith('istmo_').findAll();
      for (final p in istmo) {
        if (p.isActive) {
          await _isar.products.put(p.copyWith(isActive: false, updatedAt: DateTime.now()));
        }
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final completedAt = DateTime.now();
    await prefs.setBool(_prefsDoneKey, true);
    await prefs.setString(_prefsAtKey, completedAt.toIso8601String());
    await prefs.setString(_prefsMetaKey, jsonEncode(meta));

    final stockUpdated = stockByRef.length;
    final result = En1BootstrapResult(
      productsUpserted: products.length,
      categoriesUpserted: categoryCount,
      imagesDownloaded: imageOk,
      stockUpdated: stockUpdated,
      imageFailures: imageFail,
      completedAt: completedAt,
      message:
          'Bootstrap EN1: ${products.length} productos · $imageOk imágenes · $stockUpdated saldos',
    );
    debugPrint('[EN1 Bootstrap] ${result.message}');
    return result;
  }

  Future<void> _mergeBootstrapConfig(
    ProvisioningConfig current,
    Map<String, dynamic> cfg,
    String apiBaseUrl,
  ) async {
    try {
      // Reutiliza parser de register/config si la forma es compatible.
      // Aquí solo actualizamos nombres/currency ligeros vía ProvisioningConfig copy.
      final org = cfg['organization'];
      final branch = cfg['branch'];
      final pos = cfg['pos'];
      final register = cfg['register'];
      final businessName = cfg['business_name']?.toString();

      String? orgId;
      String? orgName;
      if (org is Map) {
        orgId = org['id']?.toString();
        orgName = org['name']?.toString();
      }
      final branchRef = branch is Map ? branch['ref']?.toString() : null;
      final branchName = branch is Map ? branch['name']?.toString() : null;
      final posRef = pos is Map ? pos['ref']?.toString() : null;
      final posName = pos is Map ? pos['name']?.toString() : null;
      final registerRef = register is Map ? register['ref']?.toString() : null;
      final registerName = register is Map ? register['name']?.toString() : null;

      final updated = current.copyWith(
        apiBaseUrl: apiBaseUrl,
        organizationId: orgId ?? current.organizationId,
        organizationName: orgName ?? current.organizationName,
        branchRef: branchRef ?? current.branchRef,
        branchName: branchName ?? current.branchName,
        posRef: posRef ?? current.posRef,
        posName: posName ?? current.posName,
        registerRef: registerRef ?? current.registerRef,
        registerName: registerName ?? current.registerName,
        businessName: businessName ?? current.businessName,
        currency: cfg['currency']?.toString() ?? current.currency,
        timezone: cfg['timezone']?.toString() ?? current.timezone,
        configVersion: (cfg['config_version'] as num?)?.toInt() ?? current.configVersion,
      );
      await ProvisioningStore.saveConfig(updated);
    } catch (e) {
      debugPrint('[EN1 Bootstrap] merge config skipped: $e');
    }
  }

  String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  String _extFromUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext.length > 5) return '.jpg';
    return ext;
  }
}

class En1BootstrapException implements Exception {
  final String message;
  En1BootstrapException(this.message);
  @override
  String toString() => message;
}
