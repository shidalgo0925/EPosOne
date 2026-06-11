import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

/// Provider de historial de ventas
final salesHistoryProvider = FutureProvider<List<Sale>>((ref) async {
  final isar = await ref.read(databaseProvider.future);
  return SaleRepository(isar).getAllSales();
});

/// Provider de ventas filtradas por fecha
final salesByDateProvider = FutureProvider.family<List<Sale>, ({DateTime from, DateTime to})>((ref, range) async {
  final isar = await ref.read(databaseProvider.future);
  return SaleRepository(isar).getAllSales(from: range.from, to: range.to);
});

/// Provider de detalle de venta
final saleDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, saleId) async {
  final isar = await ref.read(databaseProvider.future);
  final repo = SaleRepository(isar);
  final sale = await repo.getSaleById(saleId);
  final items = await repo.getSaleItems(saleId);
  return {'sale': sale, 'items': items};
});

/// Notifier para operaciones de venta
class SalesNotifier extends StateNotifier<AsyncValue<void>> {
  final SaleRepository _repo;
  SalesNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> cancelSale(String localId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.cancelSale(localId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final salesNotifierProvider = StateNotifierProvider<SalesNotifier, AsyncValue<void>>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (isar) => SalesNotifier(SaleRepository(isar)),
    loading: () => throw StateError('Database not initialized'),
    error: (e, _) => throw StateError('Database error: $e'),
  );
});