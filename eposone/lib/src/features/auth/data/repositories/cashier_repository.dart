import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/utils/pin_hash.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';

part 'cashier_repository.g.dart';

@riverpod
CashierRepository cashierRepository(CashierRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return CashierRepository(db);
}

class CashierRepository {
  final Isar _isar;
  CashierRepository(this._isar);

  Future<List<Cashier>> getActiveCashiers() async {
    return _isar.cashiers
        .filter()
        .activeEqualTo(true)
        .isDeletedEqualTo(false)
        .sortByName()
        .findAll();
  }

  Future<int> countCashiers() async {
    return _isar.cashiers.filter().isDeletedEqualTo(false).count();
  }

  Future<Cashier?> getById(String localId) async {
    return _isar.cashiers.filter().localIdEqualTo(localId).findFirst();
  }

  Future<Cashier?> verifyPin(String pin) async {
    final hash = hashPin(pin);
    return _isar.cashiers
        .filter()
        .pinHashEqualTo(hash)
        .activeEqualTo(true)
        .isDeletedEqualTo(false)
        .findFirst();
  }

  Future<void> saveCashier(Cashier cashier) =>
      _isar.writeTxn(() => _isar.cashiers.put(cashier));
}
