import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'product_modifier_link.g.dart';

@collection
class ProductModifierLink extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String productId;
  final String groupId;
  final int sortOrder;

  const ProductModifierLink({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.productId,
    required this.groupId,
    this.sortOrder = 0,
  });

  @override
  ProductModifierLink markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  ProductModifierLink markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  ProductModifierLink markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  ProductModifierLink copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? productId,
    String? groupId,
    int? sortOrder,
  }) =>
      ProductModifierLink(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        productId: productId ?? this.productId,
        groupId: groupId ?? this.groupId,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  factory ProductModifierLink.create({
    required String productId,
    required String groupId,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return ProductModifierLink(
      localId: '${productId}_${groupId}',
      productId: productId,
      groupId: groupId,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }
}
