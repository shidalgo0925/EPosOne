import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'modifier.g.dart';

@collection
class Modifier extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String groupId;
  final String name;
  final double priceDelta;
  final bool isDefault;
  final int sortOrder;

  const Modifier({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.groupId,
    required this.name,
    this.priceDelta = 0,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  @override
  Modifier markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  Modifier markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  Modifier markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  Modifier copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? groupId,
    String? name,
    double? priceDelta,
    bool? isDefault,
    int? sortOrder,
  }) =>
      Modifier(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        groupId: groupId ?? this.groupId,
        name: name ?? this.name,
        priceDelta: priceDelta ?? this.priceDelta,
        isDefault: isDefault ?? this.isDefault,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  factory Modifier.create({
    required String groupId,
    required String name,
    double priceDelta = 0,
    bool isDefault = false,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return Modifier(
      localId: '${groupId}_${now.microsecondsSinceEpoch}',
      groupId: groupId,
      name: name,
      priceDelta: priceDelta,
      isDefault: isDefault,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }
}
