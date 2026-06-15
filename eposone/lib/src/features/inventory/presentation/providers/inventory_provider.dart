import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/features/inventory/data/repositories/stock_adjustment_repository.dart';
import 'package:eposone/src/features/inventory/domain/entities/stock_adjustment.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';

final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  if (ref.watch(businessConfigProvider)?.trackInventory != true) return [];
  final repo = ref.watch(stockAdjustmentRepositoryProvider);
  return repo.getLowStockProducts();
});

final lowStockCountProvider = FutureProvider<int>((ref) async {
  if (ref.watch(businessConfigProvider)?.trackInventory != true) return 0;
  final repo = ref.watch(stockAdjustmentRepositoryProvider);
  return repo.countLowStockProducts();
});

final stockAdjustmentsHistoryProvider = FutureProvider<List<StockAdjustment>>((ref) async {
  final repo = ref.watch(stockAdjustmentRepositoryProvider);
  return repo.getRecent();
});
