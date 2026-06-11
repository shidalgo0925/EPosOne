import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';

part 'cash_register_repository.g.dart';

@riverpod
CashRegisterRepository cashRegisterRepository(CashRegisterRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return CashRegisterRepository(db);
}

class CashRegisterRepository {
  final Isar _isar;
  CashRegisterRepository(this._isar);

  Future<CashRegister?> getOpenRegister() async {
    return _isar.cashRegisters
        .filter()
        .statusEqualTo(CashRegisterStatus.open)
        .isDeletedEqualTo(false)
        .findFirst();
  }

  Future<List<CashRegister>> getAllRegisters({int limit = 50}) async {
    return _isar.cashRegisters
        .filter()
        .isDeletedEqualTo(false)
        .sortByOpenDateDesc()
        .limit(limit)
        .findAll();
  }

  Future<CashRegister?> getRegisterById(String localId) async {
    return _isar.cashRegisters.filter().localIdEqualTo(localId).findFirst();
  }

  Future<void> saveRegister(CashRegister register) => _isar.writeTxn(() => _isar.cashRegisters.put(register));

  Future<void> openRegister(double openingAmount, {String? openedBy, String? notes}) async {
    final existing = await getOpenRegister();
    if (existing != null) throw Exception('Ya hay una caja abierta');
    final register = CashRegister.create(openingAmount: openingAmount, openedBy: openedBy, notes: notes);
    await saveRegister(register);
  }

  Future<void> closeRegister({
    required String registerId,
    required double closingAmount,
    required double expectedAmount,
    String? closedBy,
    String? notes,
  }) async {
    final register = await getRegisterById(registerId);
    if (register == null) throw Exception('Caja no encontrada');
    if (!register.isOpen) throw Exception('La caja ya está cerrada');
    final closed = register.close(
      closingAmount: closingAmount,
      expectedAmount: expectedAmount,
      closedBy: closedBy,
      notes: notes,
    );
    await saveRegister(closed);
  }
}