import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_movement.dart';

part 'cash_movement_repository.g.dart';

@riverpod
CashMovementRepository cashMovementRepository(CashMovementRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return CashMovementRepository(db);
}

class CashMovementRepository {
  final Isar _isar;
  CashMovementRepository(this._isar);

  Future<List<CashMovement>> getByRegister(String cashRegisterId) async {
    return _isar.cashMovements
        .filter()
        .cashRegisterIdEqualTo(cashRegisterId)
        .isDeletedEqualTo(false)
        .sortByMovementDateDesc()
        .findAll();
  }

  Future<CashMovement> save(CashMovement movement) async {
    await _isar.writeTxn(() => _isar.cashMovements.put(movement));
    return movement;
  }

  Future<double> getTotalInflow(String cashRegisterId) async {
    final movements = await getByRegister(cashRegisterId);
    return movements.where((m) => m.isInflow).fold<double>(0, (s, m) => s + m.amount.abs());
  }

  Future<double> getTotalOutflow(String cashRegisterId) async {
    final movements = await getByRegister(cashRegisterId);
    return movements.where((m) => m.isOutflow).fold<double>(0, (s, m) => s + m.amount.abs());
  }
}
