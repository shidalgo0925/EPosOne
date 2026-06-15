import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'predefined_ticket.g.dart';

/// Nombre predefinido reutilizable (Mesa 1, Barra 2, Ticket 001…).
@collection
class PredefinedTicket extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String name;
  final String? groupName;
  final bool isActive;
  final int sortOrder;

  const PredefinedTicket({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.name,
    this.groupName,
    this.isActive = true,
    this.sortOrder = 0,
  });

  @override
  PredefinedTicket markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  PredefinedTicket markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  PredefinedTicket markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  PredefinedTicket copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? name,
    String? groupName,
    bool clearGroupName = false,
    bool? isActive,
    int? sortOrder,
  }) =>
      PredefinedTicket(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        name: name ?? this.name,
        groupName: clearGroupName ? null : (groupName ?? this.groupName),
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  factory PredefinedTicket.create({
    required String name,
    String? groupName,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return PredefinedTicket(
      localId: now.millisecondsSinceEpoch.toString(),
      name: name,
      groupName: groupName,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }
}
