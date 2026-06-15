import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'coupon.g.dart';

enum CouponDiscountType {
  percent,
  fixed,
}

String couponDiscountTypeLabel(CouponDiscountType type) => switch (type) {
      CouponDiscountType.percent => 'Porcentaje',
      CouponDiscountType.fixed => 'Monto fijo',
    };

@collection
class Coupon extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String code;
  final String? description;
  @enumerated
  final CouponDiscountType discountType;
  final double value;
  final double? minPurchase;
  final DateTime? expiresAt;
  final bool isActive;
  final int maxUses;
  final int useCount;

  const Coupon({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.code,
    this.description,
    required this.discountType,
    required this.value,
    this.minPurchase,
    this.expiresAt,
    this.isActive = true,
    this.maxUses = 0,
    this.useCount = 0,
  });

  bool get isUnlimitedUses => maxUses <= 0;

  @override
  Coupon markAsModified() => copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  Coupon markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  Coupon markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  Coupon copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? code,
    String? description,
    CouponDiscountType? discountType,
    double? value,
    double? minPurchase,
    DateTime? expiresAt,
    bool? isActive,
    int? maxUses,
    int? useCount,
  }) =>
      Coupon(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        code: code ?? this.code,
        description: description ?? this.description,
        discountType: discountType ?? this.discountType,
        value: value ?? this.value,
        minPurchase: minPurchase ?? this.minPurchase,
        expiresAt: expiresAt ?? this.expiresAt,
        isActive: isActive ?? this.isActive,
        maxUses: maxUses ?? this.maxUses,
        useCount: useCount ?? this.useCount,
      );

  factory Coupon.create({
    required String code,
    String? description,
    required CouponDiscountType discountType,
    required double value,
    double? minPurchase,
    DateTime? expiresAt,
    int maxUses = 0,
  }) {
    final now = DateTime.now();
    return Coupon(
      localId: now.microsecondsSinceEpoch.toString(),
      code: code.trim().toUpperCase(),
      description: description,
      discountType: discountType,
      value: value,
      minPurchase: minPurchase,
      expiresAt: expiresAt,
      maxUses: maxUses,
      createdAt: now,
      updatedAt: now,
    );
  }

  double calculateDiscount(double subtotalAfterLineDiscounts) {
    if (discountType == CouponDiscountType.percent) {
      return (subtotalAfterLineDiscounts * (value / 100)).clamp(0, subtotalAfterLineDiscounts);
    }
    return value.clamp(0, subtotalAfterLineDiscounts);
  }
}
