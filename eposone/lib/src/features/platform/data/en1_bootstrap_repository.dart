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
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';

/// Device Bootstrap Hito 2: pull catálogo + imágenes + stock desde EN1.
///
/// No toca pantallas del POS Core; escribe en Isar y prefs de plataforma.
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

  /// Ejecuta el flujo completo del contrato Hito 2 v0.1.
  /// [apiBaseUrl]/[accessToken] opcionales: fallback si no hay ProvisioningStore.
  Future<En1BootstrapResult> runBootstrap({
    String? apiBaseUrl,
    String? accessToken,
  }) async {
    final config = await ProvisioningStore.loadConfig();
    final base = (apiBaseUrl ?? config?.apiBaseUrl ?? '').trim();
    final token = (accessToken ?? config?.accessToken ?? '').trim();
    if (base.isEmpty || token.isEmpty) {
      throw En1BootstrapException(
        'Dispositivo no provisionado. Conecta EasyNodeOne o guarda URL + token en EN1 Cloud.',
      );
    }

    final products = await _api.fetchProducts(
      apiBaseUrl: base,
      accessToken: token,
    );
    if (products.isEmpty) {
      throw En1BootstrapException(
        'EN1 no devolvió productos. Verifica org Itsmo (appdev) y permisos del token.',
      );
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

    // Categorías
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

    // Productos
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
          stock: existing?.stock ?? 0,
          categoryId: catId,
          imagePath: existing?.imagePath,
          isActive: remote.isActive,
          minStockAlert: remote.minStock,
        );
        await _isar.products.put(product);
      }
    });

    // Imágenes (fuera de txn pesada)
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
          final p = await _isar.products.filter().localIdEqualTo('en1_${remote.productRef}').findFirst();
          if (p != null) {
            await _isar.products.put(p.copyWith(imagePath: dest, updatedAt: DateTime.now()));
          }
        });
      } else {
        imageFail++;
      }
    }

    // Stock
    var stockUpdated = 0;
    try {
      final balances = await _api.fetchStockBalances(
        apiBaseUrl: base,
        accessToken: token,
      );
      await _isar.writeTxn(() async {
        for (final b in balances) {
          final p = await _isar.products
                  .filter()
                  .localIdEqualTo('en1_${b.productRef}')
                  .findFirst() ??
              await _isar.products.filter().skuEqualTo(b.productRef).findFirst();
          if (p == null) continue;
          await _isar.products.put(
            p.copyWith(stock: b.available, updatedAt: DateTime.now()),
          );
          stockUpdated++;
        }
      });
    } catch (e) {
      debugPrint('[EN1 Bootstrap] stock-balances opcional falló: $e');
    }

    // Desactivar seed Istmo local (ya no es fuente activa)
    await _isar.writeTxn(() async {
      final istmo = await _isar.products.filter().localIdStartsWith('istmo_').findAll();
      for (final p in istmo) {
        if (p.isActive) {
          await _isar.products.put(p.copyWith(isActive: false, updatedAt: DateTime.now()));
        }
      }
      final istmoCats =
          await _isar.categorys.filter().localIdStartsWith('istmo_').findAll();
      for (final c in istmoCats) {
        // categorías sin soft-delete de activo; se dejan
        debugPrint('[EN1 Bootstrap] categoría Istmo retenida: ${c.localId}');
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final completedAt = DateTime.now();
    await prefs.setBool(_prefsDoneKey, true);
    await prefs.setString(_prefsAtKey, completedAt.toIso8601String());
    await prefs.setString(_prefsMetaKey, jsonEncode(meta));

    final result = En1BootstrapResult(
      productsUpserted: products.length,
      categoriesUpserted: categoryCount,
      imagesDownloaded: imageOk,
      stockUpdated: stockUpdated,
      imageFailures: imageFail,
      completedAt: completedAt,
      message:
          'Catálogo EN1: ${products.length} productos · $imageOk imágenes · $stockUpdated saldos',
    );
    debugPrint('[EN1 Bootstrap] ${result.message}');
    return result;
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
