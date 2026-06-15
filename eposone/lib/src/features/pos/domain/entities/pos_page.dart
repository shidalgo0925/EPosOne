import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'pos_page.g.dart';

@collection
class PosPage extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String name;
  final int sortOrder;
  final bool isActive;

  const PosPage({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  @override
  PosPage markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  PosPage markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  PosPage markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  PosPage copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? name,
    int? sortOrder,
    bool? isActive,
  }) =>
      PosPage(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
      );

  factory PosPage.create({required String name, int sortOrder = 0}) {
    final now = DateTime.now();
    return PosPage(
      localId: now.millisecondsSinceEpoch.toString(),
      name: name,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }
}
