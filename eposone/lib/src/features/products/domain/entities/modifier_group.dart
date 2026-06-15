import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'modifier_group.g.dart';

@collection
class ModifierGroup extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String name;
  /// Mínimo de opciones a elegir (0 = opcional).
  final int minSelect;
  /// Máximo de opciones (1 = elección única, ej. tamaño).
  final int maxSelect;
  final int sortOrder;

  const ModifierGroup({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.name,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.sortOrder = 0,
  });

  bool get isRequired => minSelect > 0;
  bool get isSingleChoice => maxSelect <= 1;

  @override
  ModifierGroup markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  ModifierGroup markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  ModifierGroup markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  ModifierGroup copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? name,
    int? minSelect,
    int? maxSelect,
    int? sortOrder,
  }) =>
      ModifierGroup(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        name: name ?? this.name,
        minSelect: minSelect ?? this.minSelect,
        maxSelect: maxSelect ?? this.maxSelect,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  factory ModifierGroup.create({
    required String name,
    int minSelect = 0,
    int maxSelect = 1,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return ModifierGroup(
      localId: now.millisecondsSinceEpoch.toString(),
      name: name,
      minSelect: minSelect,
      maxSelect: maxSelect,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }
}
