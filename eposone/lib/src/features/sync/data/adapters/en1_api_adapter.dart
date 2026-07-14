import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/sync/data/adapters/live_en1_adapter.dart';
import 'package:eposone/src/features/sync/data/adapters/stub_en1_adapter.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/domain/entities/en1_sync_mode.dart';

class En1PushResult {
  final String serverId;
  const En1PushResult({required this.serverId});
}

class En1CatalogPayload {
  final List<Category> categories;
  final List<Product> products;

  const En1CatalogPayload({
    required this.categories,
    required this.products,
  });
}

abstract class En1ApiAdapter {
  Future<En1PushResult> pushSale({
    required BusinessConfig config,
    required Sale sale,
    required List<SaleItem> items,
  });

  Future<En1PushResult> pushCustomer({
    required BusinessConfig config,
    required Customer customer,
  });

  Future<En1CatalogPayload> pullCatalog({required BusinessConfig config});
}

En1ApiAdapter createEn1Adapter(En1SyncMode mode) {
  switch (mode) {
    case En1SyncMode.stub:
      return StubEn1Adapter();
    case En1SyncMode.live:
      return LiveEn1Adapter();
    case En1SyncMode.none:
      throw StateError('EN1 sync desactivado');
  }
}
