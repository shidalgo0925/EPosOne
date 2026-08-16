import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_api.dart';
import 'package:eposone/src/features/platform/data/en1_cashier_catalog_store.dart';
import 'package:eposone/src/features/platform/data/installation_lifecycle.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/en1_bootstrap_models.dart';
import 'package:eposone/src/features/platform/domain/provisioning_config.dart';
import 'package:eposone/src/features/licensing/domain/license_service.dart';
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
  static const _prefsLastErrorKey = 'en1_bootstrap_last_error_v1';
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
    'cerveza',
    'cocteles',
    'cócteles',
    'vinos y espumantes',
    'vinos',
    'vino',
    'licores',
    'licor',
    'bebidas',
    'bebida',
    'batidos',
    'smoothie',
    'cafes',
    'cafés',
    'cafe',
    'café',
    'tragos',
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

  Future<String?> lastBootstrapError() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsLastErrorKey);
  }

  Future<void> _clearBootstrapError() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsLastErrorKey);
  }

  Future<void> _saveBootstrapError(Object e) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLastErrorKey, e.toString());
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
      final knownCashiersVersion =
          await En1CashierCatalogStore.getCashiersVersion();
      final payload = await _api.fetchBootstrap(
        apiBaseUrl: base,
        accessToken: token,
        knownCashiersVersion: knownCashiersVersion,
      );
      final products = payload.products;
      var emptyCatalogAllowed = false;
      if (products.isEmpty) {
        final existingProducts = await _isar.products
            .filter()
            .localIdStartsWith('en1_')
            .isDeletedEqualTo(false)
            .count();
        if (existingProducts == 0) {
          // Org nueva / catálogo aún vacío en EN1: no bloquear onboarding.
          emptyCatalogAllowed = true;
          report(
            'catalog',
            'Sin productos aún · continuando con licencia y cajeros…',
          );
          debugPrint(
            '[EN1 Bootstrap] Catálogo vacío (org nueva). Bootstrap continúa.',
          );
        } else {
          report('catalog', 'Catálogo sin cambios · actualizando cajeros…');
        }
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

      report('categories', 'Guardando categorías…',
          current: 0, total: uniqueCats.length);
      await _isar.writeTxn(() async {
        var order = 0;
        for (final name in uniqueCats) {
          final localId = 'en1_cat_${_slug(name)}';
          final existing = await _isar.categorys
              .filter()
              .localIdEqualTo(localId)
              .findFirst();
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

      report('products', 'Guardando productos…',
          current: 0, total: products.length);
      await _isar.writeTxn(() async {
        for (final remote in products) {
          final catId = catForName(remote.category)?.localId;
          final localId = 'en1_${remote.productRef}';
          final existing = await _isar.products
                  .filter()
                  .localIdEqualTo(localId)
                  .findFirst() ??
              await _isar.products
                  .filter()
                  .skuEqualTo(remote.productRef)
                  .findFirst();

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
          // Bootstrap = catálogo de venta: activo salvo Inactivo explícito en EN1.
          final active = remote.isActive;
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
            isActive: active,
            minStockAlert: remote.minStock,
          );
          await _isar.products.put(product);
          if (!active) {
            debugPrint(
              '[EN1 Bootstrap] Producto inactivo omitible en POS: ${remote.name} '
              '(status=${remote.status}, ref=${remote.productRef})',
            );
          }
        }
      });
      report('products', 'Productos guardados',
          current: products.length, total: products.length);

      final withImages = products
          .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
          .toList();
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
            final p = await _isar.products
                .filter()
                .localIdEqualTo('en1_${remote.productRef}')
                .findFirst();
            if (p != null) {
              await _isar.products
                  .put(p.copyWith(imagePath: dest, updatedAt: DateTime.now()));
            }
          });
        } else {
          imageFail++;
        }
      }

      report('cashiers', 'Guardando cajeros…');
      await En1CashierCatalogStore.saveFromBootstrap(
        cashiersVersion: payload.cashiersVersion,
        cashiers: payload.cashiers,
      );

      report('license', 'Actualizando licencia…');
      await LicenseService().applyFromBootstrap(payload.license);

      report('pos', 'Configurando menú POS…');
      // Usar categorías EN1 ya en DB (incluye las de este pull) para no dejar huecos.
      final allEn1Cats = await _isar.categorys
          .filter()
          .localIdStartsWith('en1_')
          .isDeletedEqualTo(false)
          .findAll();
      await _rebuildPosPagesForEn1(
        allEn1Cats.isNotEmpty ? allEn1Cats : categoryByName.values.toList(),
      );

      // Desactivar seed Istmo local
      report('cleanup', 'Desactivando catálogo local Istmo…');
      await _isar.writeTxn(() async {
        final istmo =
            await _isar.products.filter().localIdStartsWith('istmo_').findAll();
        for (final p in istmo) {
          if (p.isActive) {
            await _isar.products
                .put(p.copyWith(isActive: false, updatedAt: DateTime.now()));
          }
        }
      });

      final prefs = await SharedPreferences.getInstance();
      final completedAt = DateTime.now();
      await prefs.setBool(_prefsDoneKey, true);
      await prefs.setString(_prefsAtKey, completedAt.toIso8601String());
      if (meta.isNotEmpty) {
        await prefs.setString(_prefsMetaKey, jsonEncode(meta));
      }

      await InstallationLifecycle.onBootstrapPersisted();

      final stockUpdated = stockByRef.length;
      final result = En1BootstrapResult(
        productsUpserted: products.length,
        categoriesUpserted: categoryCount,
        imagesDownloaded: imageOk,
        stockUpdated: stockUpdated,
        imageFailures: imageFail,
        completedAt: completedAt,
        message: emptyCatalogAllowed
            ? 'Dispositivo listo. Aún no hay productos en el catálogo — '
                'puede abrir caja y cargarlos desde EN1.'
            : 'Bootstrap EN1: ${products.length} productos · $imageOk imágenes · $stockUpdated saldos',
      );
      report('done', result.message, current: 1, total: 1);
      debugPrint('[EN1 Bootstrap] ${result.message}');

      if (recordInSyncHistory) {
        await _recordSyncHistory(
          success: true,
          detail: '${products.length} prod · $imageOk img',
        );
      }
      await _clearBootstrapError();
      return result;
    } catch (e) {
      await _saveBootstrapError(e);
      if (recordInSyncHistory) {
        await _recordSyncHistory(
            success: false, detail: null, error: e.toString());
      }
      rethrow;
    }
  }

  /// Menú POS: páginas Comida + Bar desde categorías EN1 (como seed Istmo).
  /// EN1 no envía “páginas” en bootstrap — se reconstruyen en local.
  ///
  /// Importante: además de categorías, se agregan **productos** a cada página
  /// (si solo hay categorías y el categoryId no cuadra, el grid queda vacío).
  Future<void> _rebuildPosPagesForEn1(List<Category> en1Categories) async {
    final now = DateTime.now();
    final cats = [...en1Categories]
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));

    final comida = <Category>[];
    final bar = <Category>[];
    for (final cat in cats) {
      final bucket = _pageBucketForCategory(cat.name);
      if (bucket == 'bar') {
        bar.add(cat);
      } else {
        comida.add(cat);
      }
    }
    if (comida.isEmpty && bar.isNotEmpty) {
      comida.addAll(bar);
      bar.clear();
    }

    final catById = {for (final c in cats) c.localId: c};
    for (final p in await _isar.products
        .filter()
        .localIdStartsWith('en1_')
        .isDeletedEqualTo(false)
        .findAll()) {
      final cid = p.categoryId;
      if (cid == null || catById.containsKey(cid)) continue;
      final missing = await _isar.categorys
          .filter()
          .localIdEqualTo(cid)
          .isDeletedEqualTo(false)
          .findFirst();
      if (missing != null) catById[cid] = missing;
    }

    // Menú POS = EN1 ACTIVE. INACTIVE permanece en Isar (tickets/ventas
    // históricas) pero no se reactiva ni se pone en Comida/Bar.
    final en1All = await _isar.products
        .filter()
        .localIdStartsWith('en1_')
        .isDeletedEqualTo(false)
        .findAll();
    final en1Products = en1All.where((p) => p.isActive).toList();
    final inactiveCount = en1All.length - en1Products.length;
    if (inactiveCount > 0) {
      debugPrint(
        '[EN1 Bootstrap] $inactiveCount producto(s) INACTIVE omitidos del menú POS',
      );
    }

    final comidaCatIds = {for (final c in comida) c.localId};
    final barCatIds = {for (final c in bar) c.localId};

    final comidaProducts = <Product>[];
    final barProducts = <Product>[];
    for (final p in en1Products) {
      final cid = p.categoryId;
      final nameHint = p.name.toLowerCase();
      final looksDrink = RegExp(
        r'batido|smoothie|jugo|refresco|cerveza|vino|coctel|cocktail|bebida|latte|cafe|café',
      ).hasMatch(nameHint);

      if (cid != null && barCatIds.contains(cid)) {
        barProducts.add(p);
      } else if (cid != null && comidaCatIds.contains(cid)) {
        comidaProducts.add(p);
        // Bebida mal clasificada en categoría de comida → también en Bar.
        if (looksDrink) barProducts.add(p);
      } else if (cid != null && catById.containsKey(cid)) {
        if (_pageBucketForCategory(catById[cid]!.name) == 'bar' || looksDrink) {
          barProducts.add(p);
        } else {
          comidaProducts.add(p);
        }
      } else if (looksDrink) {
        barProducts.add(p);
      } else {
        comidaProducts.add(p);
      }
    }

    // Dedup por localId
    Map<String, Product> uniq(List<Product> list) {
      final m = <String, Product>{};
      for (final p in list) {
        m.putIfAbsent(p.localId, () => p);
      }
      return m;
    }

    final comidaU = uniq(comidaProducts).values.toList();
    final barU = uniq(barProducts).values.toList();

    // Asegurar categorías en cada página aunque el pull venga raro:
    // toda categoría referenciada por productos de la página entra al menú.
    List<Category> catsForProducts(List<Product> prods, List<Category> seeded) {
      final byId = {for (final c in seeded) c.localId: c};
      for (final p in prods) {
        final cid = p.categoryId;
        if (cid == null || byId.containsKey(cid)) continue;
        final fromDb = catById[cid];
        if (fromDb != null) byId[cid] = fromDb;
      }
      final list = byId.values.toList()
        ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
      return list;
    }

    final comidaCatsFinal = catsForProducts(comidaU, comida);
    final barCatsFinal = catsForProducts(barU, bar);

    await _isar.writeTxn(() async {
      // Desactivar seed Istmo + páginas EN1 previas (se recrean abajo).
      for (final prefix in ['istmo_', 'en1_page_']) {
        final pages =
            await _isar.posPages.filter().localIdStartsWith(prefix).findAll();
        for (final p in pages) {
          if (p.isActive) {
            await _isar.posPages
                .put(p.copyWith(isActive: false, updatedAt: now));
          }
        }
      }

      Future<void> upsertPage({
        required String pageId,
        required String name,
        required int sortOrder,
        required List<Category> pageCats,
        required List<Product> pageProducts,
      }) async {
        final existing =
            await _isar.posPages.filter().localIdEqualTo(pageId).findFirst();
        final active = pageCats.isNotEmpty || pageProducts.isNotEmpty;
        await _isar.posPages.put(
          PosPage(
            localId: pageId,
            serverId: pageId,
            syncStatus: SyncStatus.synced,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            name: name,
            sortOrder: sortOrder,
            isActive: active,
          ),
        );

        // Hard-delete ítems previos (soft-delete dejaba menús vacíos tras re-sync).
        final oldItems =
            await _isar.posPageItems.filter().pageIdEqualTo(pageId).findAll();
        if (oldItems.isNotEmpty) {
          await _isar.posPageItems
              .deleteAll(oldItems.map((e) => e.isarId).toList());
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
        for (final p in pageProducts) {
          await _isar.posPageItems.put(
            PosPageItem(
              localId: 'en1_pi_${pageId}_prod_${p.localId}',
              serverId: 'en1_pi_${pageId}_prod_${p.localId}',
              syncStatus: SyncStatus.synced,
              createdAt: now,
              updatedAt: now,
              pageId: pageId,
              itemType: PosPageItemType.product,
              refId: p.localId,
              sortOrder: sort++,
            ),
          );
        }
      }

      await upsertPage(
        pageId: _en1PageComida,
        name: 'Comida',
        sortOrder: 0,
        pageCats: comidaCatsFinal,
        pageProducts: comidaU,
      );
      await upsertPage(
        pageId: _en1PageBar,
        name: 'Bar',
        sortOrder: 1,
        pageCats: barCatsFinal,
        pageProducts: barU,
      );
    });

    debugPrint(
      '[EN1 Bootstrap] Páginas POS: Comida=${comidaCatsFinal.length} cats/${comidaU.length} prods · '
      'Bar=${barCatsFinal.length} cats/${barU.length} prods',
    );
  }

  /// Repara Comida/Bar desde catálogo EN1 ya local (sin red).
  /// Útil tras actualizar APK si las páginas quedaron vacías.
  Future<int> repairEn1PosPagesFromLocal() async {
    final cats = await _isar.categorys
        .filter()
        .localIdStartsWith('en1_')
        .isDeletedEqualTo(false)
        .findAll();
    await _rebuildPosPagesForEn1(cats);
    final pages = await _isar.posPages
        .filter()
        .localIdStartsWith('en1_page_')
        .isActiveEqualTo(true)
        .findAll();
    return pages.length;
  }

  String _pageBucketForCategory(String name) {
    final n = name
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    if (_barCategoryHints.any((h) => n.contains(h) || h.contains(n)))
      return 'bar';
    if (_comidaCategoryHints.any((h) => n.contains(h) || h.contains(n)))
      return 'comida';
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
      operationStatus:
          success ? SyncOperationStatus.completed : SyncOperationStatus.failed,
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
      String? orgTimezone;
      if (org is Map) {
        orgId = org['id']?.toString();
        orgName = org['name']?.toString();
        orgTimezone = org['timezone']?.toString();
      }
      final branchRef = branch is Map ? branch['ref']?.toString() : null;
      final branchName = branch is Map ? branch['name']?.toString() : null;
      final posRef = pos is Map ? pos['ref']?.toString() : null;
      final posName = pos is Map ? pos['name']?.toString() : null;
      final registerRef = register is Map ? register['ref']?.toString() : null;
      final registerName =
          register is Map ? register['name']?.toString() : null;

      final timezone =
          orgTimezone ?? cfg['timezone']?.toString() ?? current.timezone;

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
        timezone: timezone,
        configVersion:
            (cfg['config_version'] as num?)?.toInt() ?? current.configVersion,
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
