import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:uuid/uuid.dart';

part 'order_event.g.dart';

/// Evento local del ciclo de vida del Pedido (outbox hacia EN1).
@collection
class OrderEvent extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String orderLocalId;
  final String eventType;
  final DateTime occurredAt;
  final String? actorId;
  /// Snapshot JSON compatible con payload del contrato.
  final String? payloadJson;
  final bool syncedToEn1;

  const OrderEvent({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.orderLocalId,
    required this.eventType,
    required this.occurredAt,
    this.actorId,
    this.payloadJson,
    this.syncedToEn1 = false,
  });

  @override
  OrderEvent markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: En1DateTimeService.nowUtc());

  @override
  OrderEvent markAsSynced(String serverId) => copyWith(
        serverId: serverId,
        syncStatus: SyncStatus.synced,
        syncedToEn1: true,
        updatedAt: En1DateTimeService.nowUtc(),
      );

  @override
  OrderEvent markAsDeleted() => copyWith(
        deletedAt: En1DateTimeService.nowUtc(),
        syncStatus: SyncStatus.modified,
        updatedAt: En1DateTimeService.nowUtc(),
      );

  OrderEvent copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? orderLocalId,
    String? eventType,
    DateTime? occurredAt,
    String? actorId,
    String? payloadJson,
    bool? syncedToEn1,
  }) =>
      OrderEvent(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        orderLocalId: orderLocalId ?? this.orderLocalId,
        eventType: eventType ?? this.eventType,
        occurredAt: occurredAt ?? this.occurredAt,
        actorId: actorId ?? this.actorId,
        payloadJson: payloadJson ?? this.payloadJson,
        syncedToEn1: syncedToEn1 ?? this.syncedToEn1,
      );

  factory OrderEvent.record({
    required String orderLocalId,
    required String eventType,
    String? actorId,
    String? payloadJson,
    String? eventId,
  }) {
    final now = En1DateTimeService.nowUtc();
    return OrderEvent(
      localId: eventId ?? const Uuid().v4(),
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      orderLocalId: orderLocalId,
      eventType: eventType,
      occurredAt: now,
      actorId: actorId,
      payloadJson: payloadJson,
      syncedToEn1: false,
    );
  }
}

/// Tipos `event.type` del contrato v1.0 (no inventar fuera de Spec).
abstract final class OrderEventTypes {
  static const created = 'pedido.creado';
  static const updated = 'pedido.actualizado';
  static const productAdded = 'producto.agregado';
  static const productRemoved = 'producto.eliminado';
  static const qtyChanged = 'cantidad.modificada';
  static const sent = 'pedido.enviado';
  static const paid = 'pedido.cobrado';
  static const voided = 'pedido.anulado';
  static const returned = 'pedido.devuelto';
}
