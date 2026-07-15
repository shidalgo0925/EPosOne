import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';

part 'open_ticket.g.dart';

enum OpenTicketStatus { open, cancelled }

@collection
class OpenTicket extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String? label;
  final String? comment;
  final String? predefinedSlotId;
  final String? customerId;
  final String? cashierId;
  final String? cashRegisterId;
  final double? discountPercent;
  final DateTime savedAt;
  @enumerated
  final OpenTicketStatus status;
  @enumerated
  final OrderType orderType;

  /// Pedido Order Domain (Hito 3) vinculado a este ticket local.
  final String? linkedOrderLocalId;

  const OpenTicket({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    this.label,
    this.comment,
    this.predefinedSlotId,
    this.customerId,
    this.cashierId,
    this.cashRegisterId,
    this.discountPercent,
    required this.savedAt,
    this.status = OpenTicketStatus.open,
    this.orderType = OrderType.generic,
    this.linkedOrderLocalId,
  });

  @override
  OpenTicket markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  OpenTicket markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  OpenTicket markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  OpenTicket copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? label,
    String? comment,
    String? predefinedSlotId,
    bool clearPredefinedSlot = false,
    String? customerId,
    String? cashierId,
    String? cashRegisterId,
    double? discountPercent,
    DateTime? savedAt,
    OpenTicketStatus? status,
    OrderType? orderType,
    String? linkedOrderLocalId,
    bool clearLinkedOrder = false,
  }) =>
      OpenTicket(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        label: label ?? this.label,
        comment: comment ?? this.comment,
        predefinedSlotId: clearPredefinedSlot ? null : (predefinedSlotId ?? this.predefinedSlotId),
        customerId: customerId ?? this.customerId,
        cashierId: cashierId ?? this.cashierId,
        cashRegisterId: cashRegisterId ?? this.cashRegisterId,
        discountPercent: discountPercent ?? this.discountPercent,
        savedAt: savedAt ?? this.savedAt,
        status: status ?? this.status,
        orderType: orderType ?? this.orderType,
        linkedOrderLocalId:
            clearLinkedOrder ? null : (linkedOrderLocalId ?? this.linkedOrderLocalId),
      );

  factory OpenTicket.create({
    String? label,
    String? comment,
    String? predefinedSlotId,
    String? customerId,
    String? cashierId,
    String? cashRegisterId,
    double? discountPercent,
    OrderType orderType = OrderType.generic,
  }) {
    final now = DateTime.now();
    return OpenTicket(
      localId: now.millisecondsSinceEpoch.toString(),
      label: label,
      comment: comment,
      predefinedSlotId: predefinedSlotId,
      customerId: customerId,
      cashierId: cashierId,
      cashRegisterId: cashRegisterId,
      discountPercent: discountPercent,
      savedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }
}
