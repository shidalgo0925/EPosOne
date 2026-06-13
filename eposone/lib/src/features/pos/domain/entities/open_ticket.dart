import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'open_ticket.g.dart';

@collection
class OpenTicket extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String? label;
  final String? customerId;
  final String? cashierId;
  final String? cashRegisterId;
  final double? discountPercent;
  final DateTime savedAt;

  const OpenTicket({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    this.label,
    this.customerId,
    this.cashierId,
    this.cashRegisterId,
    this.discountPercent,
    required this.savedAt,
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
    String? customerId,
    String? cashierId,
    String? cashRegisterId,
    double? discountPercent,
    DateTime? savedAt,
  }) =>
      OpenTicket(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        label: label ?? this.label,
        customerId: customerId ?? this.customerId,
        cashierId: cashierId ?? this.cashierId,
        cashRegisterId: cashRegisterId ?? this.cashRegisterId,
        discountPercent: discountPercent ?? this.discountPercent,
        savedAt: savedAt ?? this.savedAt,
      );

  factory OpenTicket.create({
    String? label,
    String? customerId,
    String? cashierId,
    String? cashRegisterId,
    double? discountPercent,
  }) {
    final now = DateTime.now();
    return OpenTicket(
      localId: now.millisecondsSinceEpoch.toString(),
      label: label,
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
