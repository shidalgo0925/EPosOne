import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_movement_repository.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_movement.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/cash_register/domain/shift_summary.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

final currentCashRegisterProvider = FutureProvider<CashRegister?>((ref) async {
  final isar = await ref.read(databaseProvider.future);
  return CashRegisterRepository(isar).getOpenRegister();
});

final cashRegisterHistoryProvider = FutureProvider<List<CashRegister>>((ref) async {
  final isar = await ref.read(databaseProvider.future);
  return CashRegisterRepository(isar).getAllRegisters(limit: 20);
});

final shiftSummaryProvider = FutureProvider.family<ShiftSummary, String>((ref, registerId) async {
  final isar = await ref.read(databaseProvider.future);
  final registerRepo = CashRegisterRepository(isar);
  final saleRepo = SaleRepository(isar);
  final moveRepo = CashMovementRepository(isar);

  final register = await registerRepo.getRegisterById(registerId);
  if (register == null) {
    throw StateError('Turno no encontrado');
  }

  final completed = await saleRepo.getSalesForCashRegister(registerId, status: SaleStatus.completed);
  final refunded = await saleRepo.getSalesForCashRegister(registerId, status: SaleStatus.refunded);
  final movements = await moveRepo.getByRegister(registerId);

  return computeShiftSummary(
    openingAmount: register.openingAmount,
    completedSales: completed,
    refundedSales: refunded,
    movements: movements,
  );
});

/// Compatibilidad — resumen simple para código legacy.
final cashRegisterSalesSummaryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, registerId) async {
  final summary = await ref.watch(shiftSummaryProvider(registerId).future);
  return {'total': summary.grossSales, 'count': summary.saleCount};
});

final cashMovementsProvider = FutureProvider.family<List<CashMovement>, String>((ref, registerId) async {
  final isar = await ref.read(databaseProvider.future);
  return CashMovementRepository(isar).getByRegister(registerId);
});

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

class CashMovementActions {
  final Ref _ref;
  CashMovementActions(this._ref);

  Future<void> addMovement({
    required String cashRegisterId,
    required CashMovementType type,
    required double amount,
    required String reason,
    String? notes,
  }) async {
    if (amount <= 0) throw ArgumentError('El monto debe ser mayor a cero');
    if (reason.trim().isEmpty) throw ArgumentError('Indica un motivo');

    final session = _ref.read(posSessionProvider);
    final isar = await _ref.read(databaseProvider.future);
    final movement = CashMovement.create(
      cashRegisterId: cashRegisterId,
      type: type,
      amount: amount,
      reason: reason.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      cashierId: session?.cashierId,
      cashierName: session?.cashierName,
    );
    await CashMovementRepository(isar).save(movement);
    _invalidate(cashRegisterId);
  }

  void _invalidate(String registerId) {
    _ref.invalidate(cashMovementsProvider(registerId));
    _ref.invalidate(shiftSummaryProvider(registerId));
    _ref.invalidate(cashRegisterSalesSummaryProvider(registerId));
  }
}

final cashMovementActionsProvider = Provider<CashMovementActions>((ref) => CashMovementActions(ref));
