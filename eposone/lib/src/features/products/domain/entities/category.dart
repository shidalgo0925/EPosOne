import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'category.g.dart';

@collection
class Category extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String name;
  final String? color; // para UI
  final String? icon; // para UI
  final int? sortOrder;

  const Category({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.name,
    this.color,
    this.icon,
    this.sortOrder,
  });

  @override
  Category markAsModified() => copyWith(
        syncStatus: SyncStatus.modified,
        updatedAt: DateTime.now(),
      );

  @override
  Category markAsSynced(String serverId) => copyWith(
        serverId: serverId,
        syncStatus: SyncStatus.synced,
        updatedAt: DateTime.now(),
      );

  @override
  Category markAsDeleted() => copyWith(
        deletedAt: DateTime.now(),
        syncStatus: SyncStatus.modified,
        updatedAt: DateTime.now(),
      );

  Category copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? name,
    String? color,
    String? icon,
    int? sortOrder,
  }) =>
      Category(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        name: name ?? this.name,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  factory Category.create({required String name, String? color, String? icon, int? sortOrder}) => Category(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        color: color,
        icon: icon,
        sortOrder: sortOrder,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}