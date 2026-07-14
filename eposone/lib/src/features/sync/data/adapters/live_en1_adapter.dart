import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_api.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/data/adapters/en1_api_adapter.dart';

/// Adapter live Hito 2: pull catálogo real desde EN1.
/// Push venta/cliente queda fuera de alcance (Hito 3).
class LiveEn1Adapter implements En1ApiAdapter {
  LiveEn1Adapter({En1BootstrapApi? api}) : _api = api ?? En1BootstrapApi();

  final En1BootstrapApi _api;

  @override
  Future<En1PushResult> pushSale({
    required BusinessConfig config,
    required Sale sale,
    required List<SaleItem> items,
  }) async {
    throw StateError(
      'Push de ventas a EN1 aún no está en Hito 2. Usa Descargar catálogo EN1.',
    );
  }

  @override
  Future<En1PushResult> pushCustomer({
    required BusinessConfig config,
    required Customer customer,
  }) async {
    throw StateError(
      'Push de clientes a EN1 aún no está en Hito 2.',
    );
  }

  @override
  Future<En1CatalogPayload> pullCatalog({required BusinessConfig config}) async {
    final base = config.en1ApiUrl?.trim() ?? '';
    final token = config.en1ApiToken?.trim() ?? '';
    if (base.isEmpty || token.isEmpty) {
      throw StateError('Configura URL y Token API EN1 antes de descargar el catálogo.');
    }

    final remotes = await _api.fetchProducts(apiBaseUrl: base, accessToken: token);
    final now = DateTime.now();
    final categories = <Category>[];
    final products = <Product>[];
    final catIds = <String, String>{};
    var order = 0;

    for (final remote in remotes) {
      final catName = remote.category?.trim();
      String? catId;
      if (catName != null && catName.isNotEmpty) {
        catId = catIds.putIfAbsent(catName, () {
          final id = 'en1_cat_${_slug(catName)}';
          categories.add(Category(
            localId: id,
            serverId: id,
            syncStatus: SyncStatus.synced,
            name: catName,
            sortOrder: order++,
            createdAt: now,
            updatedAt: now,
          ));
          return id;
        });
      }

      products.add(Product(
        localId: 'en1_${remote.productRef}',
        serverId: remote.productRef,
        syncStatus: SyncStatus.synced,
        createdAt: now,
        updatedAt: now,
        name: remote.name,
        barcode: remote.barcode,
        sku: remote.productRef,
        description: remote.description,
        price: remote.unitPrice,
        cost: remote.costPrice,
        stock: 0,
        categoryId: catId,
        isActive: remote.isActive,
        minStockAlert: remote.minStock,
      ));
    }

    // Saldos (best-effort)
    try {
      final balances = await _api.fetchStockBalances(
        apiBaseUrl: base,
        accessToken: token,
      );
      final byRef = {for (final b in balances) b.productRef: b.available};
      for (var i = 0; i < products.length; i++) {
        final avail = byRef[products[i].sku];
        if (avail != null) {
          products[i] = products[i].copyWith(stock: avail);
        }
      }
    } catch (_) {}

    return En1CatalogPayload(categories: categories, products: products);
  }

  String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
