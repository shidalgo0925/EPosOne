import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/data/adapters/en1_api_adapter.dart';

/// Simula push/pull EN1 para desarrollo offline-first.
class StubEn1Adapter implements En1ApiAdapter {
  @override
  Future<En1PushResult> pushSale({
    required BusinessConfig config,
    required Sale sale,
    required List<SaleItem> items,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _assertReady(config);
    return En1PushResult(serverId: 'EN1-SALE-${sale.localId}');
  }

  @override
  Future<En1PushResult> pushCustomer({
    required BusinessConfig config,
    required Customer customer,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _assertReady(config);
    return En1PushResult(serverId: 'EN1-CUS-${customer.localId}');
  }

  @override
  Future<En1CatalogPayload> pullCatalog({required BusinessConfig config}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _assertReady(config);

    final now = DateTime.now();
    final category = Category(
      localId: 'en1_stub_cat_demo',
      serverId: 'EN1-CAT-DEMO',
      syncStatus: SyncStatus.synced,
      name: 'EN1 Cloud',
      sortOrder: 999,
      createdAt: now,
      updatedAt: now,
    );

    final product = Product(
      localId: 'en1_stub_prod_demo',
      serverId: 'EN1-PROD-DEMO',
      syncStatus: SyncStatus.synced,
      name: 'Producto demo EN1',
      description: 'Sincronizado desde EN1 (stub)',
      price: 9.99,
      stock: 99,
      categoryId: category.localId,
      barcode: 'EN1-DEMO-001',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    return En1CatalogPayload(categories: [category], products: [product]);
  }

  void _assertReady(BusinessConfig config) {
    if (config.en1BranchId == null || config.en1BranchId!.trim().isEmpty) {
      throw StateError('Configure el ID de sucursal EN1');
    }
  }
}
