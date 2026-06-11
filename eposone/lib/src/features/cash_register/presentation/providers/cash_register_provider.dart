import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';

/// Provider de caja abierta actual
final currentCashRegisterProvider = FutureProvider<CashRegister?>((ref) async {
  final isar = await ref.read(databaseProvider.future);
  return CashRegisterRepository(isar).getOpenRegister();
});

/// Provider de historial de cajas
final cashRegisterHistoryProvider = FutureProvider<List<CashRegister>>((ref) async {
  final isar = await ref.read(databaseProvider.future);
  return CashRegisterRepository(isar).getAllRegisters(limit: 20);
});

/// Provider de resumen de ventas del turno actual
final cashRegisterSalesSummaryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, registerId) async {
  final isar = await ref.read(databaseProvider.future);
  final saleRepo = SaleRepository(isar);
  final total = await saleRepo.getTotalSalesForCashRegister(registerId);
  final count = await saleRepo.getSaleCountForCashRegister(registerId);
  return {'total': total, 'count': count};
});

/// Notifier para operaciones de caja
class CashRegisterNotifier extends StateNotifier<AsyncValue<void>> {
  final CashRegisterRepository _repo;
  CashRegisterNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> open(double openingAmount, {String? openedBy, String? notes}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.openRegister(openingAmount, openedBy: openedBy, notes: notes);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> close({
    required String registerId,
    required double closingAmount,
    required double expectedAmount,
    String? closedBy,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.closeRegister(
        registerId: registerId,
        closingAmount: closingAmount,
        expectedAmount: expectedAmount,
        closedBy: closedBy,
        notes: notes,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final cashRegisterNotifierProvider = StateNotifierProvider<CashRegisterNotifier, AsyncValue<void>>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (isar) => CashRegisterNotifier(CashRegisterRepository(isar)),
    loading: () => throw StateError('Database not initialized'),
    error: (e, _) => throw StateError('Database error: $e'),
  );
});