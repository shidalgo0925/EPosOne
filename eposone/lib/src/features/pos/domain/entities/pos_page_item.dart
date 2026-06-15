import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'pos_page_item.g.dart';

enum PosPageItemType { product, category }

@collection
class PosPageItem extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String pageId;
  @enumerated
  final PosPageItemType itemType;
  final String refId;
  final int sortOrder;

  const PosPageItem({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.pageId,
    required this.itemType,
    required this.refId,
    this.sortOrder = 0,
  });

  @override
  PosPageItem markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  PosPageItem markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  PosPageItem markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  PosPageItem copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? pageId,
    PosPageItemType? itemType,
    String? refId,
    int? sortOrder,
  }) =>
      PosPageItem(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        pageId: pageId ?? this.pageId,
        itemType: itemType ?? this.itemType,
        refId: refId ?? this.refId,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  factory PosPageItem.create({
    required String pageId,
    required PosPageItemType itemType,
    required String refId,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return PosPageItem(
      localId: '${pageId}_${itemType.name}_${refId}_$now',
      pageId: pageId,
      itemType: itemType,
      refId: refId,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }
}
