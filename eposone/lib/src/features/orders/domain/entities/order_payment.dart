import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';

part 'order_payment.g.dart';

/// Pago asociado a un pedido (local).
///
/// Shape HTTP definitivo = contrato Hito 3 (pendiente de recepción).
@collection
class OrderPayment extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String orderLocalId;
  final String methodCode;
  final double amount;
  final String? currency;
  final String? notes;
  final bool isPartial;
  final DateTime paidAt;

  const OrderPayment({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.orderLocalId,
    required this.methodCode,
    required this.amount,
    this.currency,
    this.notes,
    this.isPartial = false,
    required this.paidAt,
  });

  @override
  OrderPayment markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: En1DateTimeService.nowUtc());

  @override
  OrderPayment markAsSynced(String serverId) => copyWith(
        serverId: serverId,
        syncStatus: SyncStatus.synced,
        updatedAt: En1DateTimeService.nowUtc(),
      );

  @override
  OrderPayment markAsDeleted() => copyWith(
        deletedAt: En1DateTimeService.nowUtc(),
        syncStatus: SyncStatus.modified,
        updatedAt: En1DateTimeService.nowUtc(),
      );

  OrderPayment copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? orderLocalId,
    String? methodCode,
    double? amount,
    String? currency,
    String? notes,
    bool? isPartial,
    DateTime? paidAt,
  }) =>
      OrderPayment(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        orderLocalId: orderLocalId ?? this.orderLocalId,
        methodCode: methodCode ?? this.methodCode,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        notes: notes ?? this.notes,
        isPartial: isPartial ?? this.isPartial,
        paidAt: paidAt ?? this.paidAt,
      );

  factory OrderPayment.create({
    required String orderLocalId,
    required String methodCode,
    required double amount,
    String? currency,
    String? notes,
    bool isPartial = false,
  }) {
    final now = En1DateTimeService.nowUtc();
    return OrderPayment(
      localId: '${orderLocalId}_pay_${now.microsecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      orderLocalId: orderLocalId,
      methodCode: methodCode,
      amount: amount,
      currency: currency,
      notes: notes,
      isPartial: isPartial,
      paidAt: now,
    );
  }
}
