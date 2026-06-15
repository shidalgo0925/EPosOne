import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/inventory/domain/entities/stock_adjustment.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';

part 'stock_adjustment_repository.g.dart';

@riverpod
StockAdjustmentRepository stockAdjustmentRepository(StockAdjustmentRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return StockAdjustmentRepository(db);
}

class StockAdjustmentRepository {
  final Isar _isar;
  StockAdjustmentRepository(this._isar);

  Future<List<Product>> getLowStockProducts() async {
    final products = await _isar.products.filter().isDeletedEqualTo(false).isActiveEqualTo(true).findAll();
    final low = products
        .where((p) => p.minStockAlert != null && p.stock <= p.minStockAlert!)
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
    return low;
  }

  Future<int> countLowStockProducts() async {
    final list = await getLowStockProducts();
    return list.length;
  }

  Future<List<StockAdjustment>> getRecent({int limit = 50}) async {
    final items = await _isar.stockAdjustments.filter().isDeletedEqualTo(false).findAll();
    items.sort((a, b) => b.adjustmentDate.compareTo(a.adjustmentDate));
    return items.take(limit).toList();
  }

  Future<StockAdjustment> adjustStock({
    required String productId,
    required double newStock,
    required StockAdjustmentType type,
    String? reason,
    String? cashierId,
    String? cashierName,
  }) async {
    if (newStock < 0) {
      throw StateError('El stock no puede ser negativo');
    }

    final product = await _isar.products.filter().localIdEqualTo(productId).findFirst();
    if (product == null || product.isDeleted) {
      throw StateError('Producto no encontrado');
    }

    final clampedStock = newStock.clamp(0, double.infinity).toDouble();
    final adjustment = StockAdjustment.create(
      productId: product.localId,
      productName: product.name,
      previousStock: product.stock,
      newStock: clampedStock,
      type: type,
      reason: reason,
      cashierId: cashierId,
      cashierName: cashierName,
    );

    final updatedProduct = product.copyWith(stock: clampedStock, updatedAt: DateTime.now()).markAsModified();

    await _isar.writeTxn(() async {
      await _isar.stockAdjustments.put(adjustment);
      await _isar.products.put(updatedProduct);
    });

    return adjustment;
  }
}
