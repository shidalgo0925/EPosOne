import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/premium/domain/entities/coupon.dart';

part 'coupon_repository.g.dart';

@riverpod
CouponRepository couponRepository(CouponRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return CouponRepository(db);
}

class CouponRepository {
  final Isar _isar;
  CouponRepository(this._isar);

  Future<List<Coupon>> getAll({bool activeOnly = false}) async {
    var query = _isar.coupons.filter().isDeletedEqualTo(false);
    if (activeOnly) query = query.isActiveEqualTo(true);
    final list = await query.findAll();
    list.sort((a, b) => a.code.compareTo(b.code));
    return list;
  }

  Future<Coupon?> getById(String localId) async {
    return _isar.coupons.filter().localIdEqualTo(localId).findFirst();
  }

  Future<Coupon?> getByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    return _isar.coupons.filter().codeEqualTo(normalized).isDeletedEqualTo(false).findFirst();
  }

  Future<Coupon> validateForCart({
    required String code,
    required double subtotalAfterLineDiscounts,
  }) async {
    final coupon = await getByCode(code);
    if (coupon == null) throw StateError('Cupón no encontrado');
    if (!coupon.isActive) throw StateError('Cupón inactivo');
    if (coupon.expiresAt != null && DateTime.now().isAfter(coupon.expiresAt!)) {
      throw StateError('Cupón vencido');
    }
    if (!coupon.isUnlimitedUses && coupon.useCount >= coupon.maxUses) {
      throw StateError('Cupón agotado');
    }
    if (coupon.minPurchase != null && subtotalAfterLineDiscounts < coupon.minPurchase!) {
      throw StateError('Compra mínima ${coupon.minPurchase!.toStringAsFixed(2)} no alcanzada');
    }
    return coupon;
  }

  Future<void> save(Coupon coupon) => _isar.writeTxn(() => _isar.coupons.put(coupon));

  Future<void> delete(String localId) async {
    final coupon = await getById(localId);
    if (coupon != null) {
      await _isar.writeTxn(() => _isar.coupons.put(coupon.markAsDeleted()));
    }
  }

  Future<void> recordUse(String localId) async {
    final coupon = await getById(localId);
    if (coupon == null) return;
    await save(coupon.copyWith(useCount: coupon.useCount + 1).markAsModified());
  }
}
