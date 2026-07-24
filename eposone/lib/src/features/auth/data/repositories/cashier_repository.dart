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

  /// Todos los cajeros locales no borrados (activos e inactivos).
  Future<List<Cashier>> listAll() async {
    return _isar.cashiers
        .filter()
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

  Future<void> saveCashier(Cashier cashier) =>
      _isar.writeTxn(() => _isar.cashiers.put(cashier));

  Future<Cashier> createCashier({
    required String name,
    required String pin,
    CashierRole role = CashierRole.cashier,
  }) async {
    final cashier = Cashier.create(
      name: name.trim(),
      pinHash: hashPin(pin),
      role: role,
    );
    await saveCashier(cashier);
    return cashier;
  }

  Future<void> updateCashier({
    required String localId,
    String? name,
    CashierRole? role,
    bool? active,
  }) async {
    final existing = await getById(localId);
    if (existing == null) throw StateError('Cajero no encontrado');
    await saveCashier(
      existing
          .copyWith(
            name: name?.trim(),
            role: role,
            active: active,
          )
          .markAsModified(),
    );
  }

  Future<void> changePin({
    required String localId,
    required String newPin,
  }) async {
    if (newPin.length < 4) {
      throw ArgumentError('El PIN debe tener al menos 4 dígitos');
    }
    final existing = await getById(localId);
    if (existing == null) throw StateError('Cajero no encontrado');
    await saveCashier(
      existing.copyWith(pinHash: hashPin(newPin)).markAsModified(),
    );
  }

  Future<void> deactivate(String localId) async {
    final existing = await getById(localId);
    if (existing == null) return;
    await saveCashier(existing.copyWith(active: false).markAsModified());
  }

  Future<void> softDelete(String localId) async {
    final existing = await getById(localId);
    if (existing == null) return;
    await saveCashier(existing.markAsDeleted());
  }
}
