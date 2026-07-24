import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/cash_register/data/cash_shift_sync_service.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_movement_repository.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_movement.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/cash_register/domain/shift_summary.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';

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
  final Ref _ref;
  final CashRegisterRepository _repo;

  CashRegisterNotifier(this._ref, this._repo) : super(const AsyncValue.data(null));

  Future<void> open(
    double openingAmount, {
    String? openedBy,
    String? notes,
    String? cashierId,
    int? cashierContactId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final register = await _repo.openRegister(
        openingAmount,
        openedBy: openedBy,
        notes: notes,
        cashierId: cashierId,
        cashierContactId: cashierContactId,
      );
      await _enqueueCashShiftSync(register.localId);
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
      await _enqueueCashShiftSync(registerId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _enqueueCashShiftSync(String registerLocalId) async {
    final isar = await _ref.read(databaseProvider.future);
    final config = await BusinessConfigRepository(isar).getConfig();
    if (!config.isEn1SyncReady) return;

    final sync = SyncRepository(isar);
    final shiftSync = CashShiftSyncService(isar: isar, syncRepository: sync);
    await shiftSync.enqueueIfReady(registerLocalId, config);
    try {
      await sync.runSyncCycle();
    } catch (_) {
      // Cola offline: se reintenta en "Sincronizar ahora".
    }
  }
}

final cashRegisterNotifierProvider = StateNotifierProvider<CashRegisterNotifier, AsyncValue<void>>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (isar) => CashRegisterNotifier(ref, CashRegisterRepository(isar)),
    loading: () => throw StateError('Database not initialized'),
    error: (e, _) => throw StateError('Database error: $e'),
  );
});

class CashMovementActions {
  final Ref _ref;
  CashMovementActions(this._ref);

  Future<CashMovement> addMovement({
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
    return movement;
  }

  void _invalidate(String registerId) {
    _ref.invalidate(cashMovementsProvider(registerId));
    _ref.invalidate(shiftSummaryProvider(registerId));
    _ref.invalidate(cashRegisterSalesSummaryProvider(registerId));
  }
}

final cashMovementActionsProvider = Provider<CashMovementActions>((ref) => CashMovementActions(ref));
