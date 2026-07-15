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
import 'package:eposone/src/features/pos/domain/entities/pos_page.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page_item.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_operation.dart';

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
  static const _en1PageComida = 'en1_page_comida';
  static const _en1PageBar = 'en1_page_bar';

  /// Categorías típicas Itsmo/Istmo → página Comida vs Bar (UX POS).
  static const _comidaCategoryHints = {
    'entradas',
    'platos fuertes',
    'platos',
    'pizzas',
    'acompanamientos',
    'acompañamientos',
    'postres',
    'comida',
  };
  static const _barCategoryHints = {
    'cervezas istmo',
    'cervezas',
    'cocteles',
    'cócteles',
    'vinos y espumantes',
    'vinos',
    'licores',
    'bebidas',
    'bar',
  };

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
  ///
  /// [recordInSyncHistory]: si true, escribe [SyncOperation] completada/fallida.
  /// Usar false cuando la cola de sync ya gestiona la operación.
  Future<En1BootstrapResult> runBootstrap({
    String? apiBaseUrl,
    String? accessToken,
    En1BootstrapProgressCallback? onProgress,
    bool recordInSyncHistory = true,
  }) async {
    void report(String phase, String label, {int current = 0, int total = 0}) {
      onProgress?.call(En1BootstrapProgress(
        phase: phase,
        label: label,
        current: current,
        total: total,
      ));
    }

    try {
      final provisioned = await ProvisioningStore.loadConfig();
      final base = (apiBaseUrl ?? provisioned?.apiBaseUrl ?? '').trim();
      final token = (accessToken ?? provisioned?.accessToken ?? '').trim();
      if (base.isEmpty || token.isEmpty) {
        throw En1BootstrapException(
          'Dispositivo no provisionado. Conecta EasyNodeOne (Device Token requerido).',
        );
      }

      report('fetch', 'Consultando catálogo EN1…');
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

      report('categories', 'Guardando categorías…', current: 0, total: uniqueCats.length);
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

      Category? catForName(String? raw) {
        if (raw == null || raw.trim().isEmpty) return null;
        final direct = categoryByName[raw];
        if (direct != null) return direct;
        final lower = raw.toLowerCase().trim();
        for (final e in categoryByName.entries) {
          if (e.key.toLowerCase().trim() == lower) return e.value;
        }
        return null;
      }

      report('products', 'Guardando productos…', current: 0, total: products.length);
      await _isar.writeTxn(() async {
        var i = 0;
        for (final remote in products) {
          i++;
          final catId = catForName(remote.category)?.localId;
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
            // Siempre vendible en POS si EN1 lo devolvió en bootstrap (salvo inactive explícito).
            isActive: remote.isActive,
            minStockAlert: remote.minStock,
          );
          await _isar.products.put(product);
          if (i % 10 == 0 || i == products.length) {
            // Progress outside writeTxn would be smoother; coarse updates ok.
          }
        }
      });
      report('products', 'Productos guardados', current: products.length, total: products.length);

      final withImages = products.where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty).toList();
      var imgIndex = 0;
      for (final remote in withImages) {
        imgIndex++;
        report(
          'images',
          'Descargando imágenes ($imgIndex/${withImages.length})…',
          current: imgIndex,
          total: withImages.length,
        );
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

      report('pos', 'Configurando menú POS…');
      await _rebuildPosPagesForEn1(categoryByName.values.toList());

      // Desactivar seed Istmo local
      report('cleanup', 'Desactivando catálogo local Istmo…');
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
      report('done', result.message, current: 1, total: 1);
      debugPrint('[EN1 Bootstrap] ${result.message}');

      if (recordInSyncHistory) {
        await _recordSyncHistory(
          success: true,
          detail: '${products.length} prod · $imageOk img',
        );
      }
      return result;
    } catch (e) {
      if (recordInSyncHistory) {
        await _recordSyncHistory(success: false, detail: null, error: e.toString());
      }
      rethrow;
    }
  }

  /// Menú POS: páginas Comida + Bar desde categorías EN1 (como seed Istmo).
  /// EN1 no envía “páginas” en bootstrap — se reconstruyen en local.
  Future<void> _rebuildPosPagesForEn1(List<Category> en1Categories) async {
    final now = DateTime.now();
    final cats = [...en1Categories]..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));

    final comida = <Category>[];
    final bar = <Category>[];
    for (final cat in cats) {
      final bucket = _pageBucketForCategory(cat.name);
      if (bucket == 'bar') {
        bar.add(cat);
      } else {
        // Default comida (incluye categorías desconocidas).
        comida.add(cat);
      }
    }
    // Si todo cayó en un solo lado, balancear: sin hints → todo en Comida.
    if (comida.isEmpty && bar.isNotEmpty) {
      comida.addAll(bar);
      bar.clear();
    }

    await _isar.writeTxn(() async {
      // Desactivar seed Istmo + página única legacy EN1.
      for (final prefix in ['istmo_', 'en1_page_']) {
        final pages = await _isar.posPages.filter().localIdStartsWith(prefix).findAll();
        for (final p in pages) {
          if (p.isActive) {
            await _isar.posPages.put(p.copyWith(isActive: false, updatedAt: now));
          }
        }
      }

      Future<void> upsertPage({
        required String pageId,
        required String name,
        required int sortOrder,
        required List<Category> pageCats,
        bool forceActive = false,
      }) async {
        final existing = await _isar.posPages.filter().localIdEqualTo(pageId).findFirst();
        await _isar.posPages.put(
          PosPage(
            localId: pageId,
            serverId: pageId,
            syncStatus: SyncStatus.synced,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            name: name,
            sortOrder: sortOrder,
            isActive: forceActive || pageCats.isNotEmpty,
          ),
        );

        final oldItems = await _isar.posPageItems.filter().pageIdEqualTo(pageId).findAll();
        for (final item in oldItems) {
          if (!item.isDeleted) {
            await _isar.posPageItems.put(item.markAsDeleted());
          }
        }

        var sort = 0;
        for (final cat in pageCats) {
          await _isar.posPageItems.put(
            PosPageItem(
              localId: 'en1_pi_${pageId}_${cat.localId}',
              serverId: 'en1_pi_${pageId}_${cat.localId}',
              syncStatus: SyncStatus.synced,
              createdAt: now,
              updatedAt: now,
              pageId: pageId,
              itemType: PosPageItemType.category,
              refId: cat.localId,
              sortOrder: sort++,
            ),
          );
        }
      }

      final en1Products = await _isar.products
          .filter()
          .localIdStartsWith('en1_')
          .isActiveEqualTo(true)
          .findAll();

      await upsertPage(
        pageId: _en1PageComida,
        name: 'Comida',
        sortOrder: 0,
        pageCats: comida,
        forceActive: en1Products.isNotEmpty,
      );
      await upsertPage(
        pageId: _en1PageBar,
        name: 'Bar',
        sortOrder: 1,
        pageCats: bar,
      );

      // Productos EN1 sin categoría → ítems en Comida.
      var prodSort = 1000;
      for (final p in en1Products) {
        if (p.categoryId != null && p.categoryId!.isNotEmpty) continue;
        await _isar.posPageItems.put(
          PosPageItem(
            localId: 'en1_pi_prod_${p.localId}',
            serverId: 'en1_pi_prod_${p.localId}',
            syncStatus: SyncStatus.synced,
            createdAt: now,
            updatedAt: now,
            pageId: _en1PageComida,
            itemType: PosPageItemType.product,
            refId: p.localId,
            sortOrder: prodSort++,
          ),
        );
      }

      // Sin categorías EN1: volcar todos los productos activos en Comida.
      if (comida.isEmpty && bar.isEmpty && en1Products.isNotEmpty) {
        for (final p in en1Products) {
          await _isar.posPageItems.put(
            PosPageItem(
              localId: 'en1_pi_prod_all_${p.localId}',
              serverId: 'en1_pi_prod_all_${p.localId}',
              syncStatus: SyncStatus.synced,
              createdAt: now,
              updatedAt: now,
              pageId: _en1PageComida,
              itemType: PosPageItemType.product,
              refId: p.localId,
              sortOrder: prodSort++,
            ),
          );
        }
      }
    });

    debugPrint(
      '[EN1 Bootstrap] Páginas POS: Comida=${comida.length} cats · Bar=${bar.length} cats',
    );
  }

  String _pageBucketForCategory(String name) {
    final n = name
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    if (_barCategoryHints.any((h) => n.contains(h) || h.contains(n))) return 'bar';
    if (_comidaCategoryHints.any((h) => n.contains(h) || h.contains(n))) return 'comida';
    // Heurística: cerveza/vino/licor/cóctel → bar
    if (RegExp(r'cerv|vino|licor|coctel|cocktail|bebida|bar').hasMatch(n)) {
      return 'bar';
    }
    return 'comida';
  }

  Future<void> _recordSyncHistory({
    required bool success,
    String? detail,
    String? error,
  }) async {
    final now = DateTime.now();
    final op = SyncOperation(
      localId: 'boot_${now.microsecondsSinceEpoch}',
      entityKind: SyncEntityKind.catalogPull,
      entityLocalId: detail,
      direction: SyncDirection.pull,
      operationStatus: success ? SyncOperationStatus.completed : SyncOperationStatus.failed,
      attemptCount: 1,
      errorMessage: error,
      processedAt: now,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    );
    await _isar.writeTxn(() => _isar.syncOperations.put(op));
  }

  Future<void> _mergeBootstrapConfig(
    ProvisioningConfig current,
    Map<String, dynamic> cfg,
    String apiBaseUrl,
  ) async {
    try {
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
