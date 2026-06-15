import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';

part 'sync_operation.g.dart';

@collection
class SyncOperation extends SyncEntity {
  Id get isarId => localId.hashCode;

  @enumerated
  final SyncEntityKind entityKind;
  final String? entityLocalId;
  @enumerated
  final SyncDirection direction;
  @enumerated
  final SyncOperationStatus operationStatus;
  final int attemptCount;
  final String? errorMessage;
  final DateTime? processedAt;

  const SyncOperation({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.entityKind,
    this.entityLocalId,
    required this.direction,
    this.operationStatus = SyncOperationStatus.pending,
    this.attemptCount = 0,
    this.errorMessage,
    this.processedAt,
  });

  @override
  SyncOperation markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  SyncOperation markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  SyncOperation markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  SyncOperation copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncEntityKind? entityKind,
    String? entityLocalId,
    SyncDirection? direction,
    SyncOperationStatus? operationStatus,
    int? attemptCount,
    String? errorMessage,
    DateTime? processedAt,
  }) =>
      SyncOperation(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        entityKind: entityKind ?? this.entityKind,
        entityLocalId: entityLocalId ?? this.entityLocalId,
        direction: direction ?? this.direction,
        operationStatus: operationStatus ?? this.operationStatus,
        attemptCount: attemptCount ?? this.attemptCount,
        errorMessage: errorMessage ?? this.errorMessage,
        processedAt: processedAt ?? this.processedAt,
      );

  factory SyncOperation.enqueuePush({
    required SyncEntityKind entityKind,
    required String entityLocalId,
  }) {
    final now = DateTime.now();
    return SyncOperation(
      localId: now.microsecondsSinceEpoch.toString(),
      entityKind: entityKind,
      entityLocalId: entityLocalId,
      direction: SyncDirection.push,
      operationStatus: SyncOperationStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory SyncOperation.enqueueCatalogPull() {
    final now = DateTime.now();
    return SyncOperation(
      localId: now.microsecondsSinceEpoch.toString(),
      entityKind: SyncEntityKind.catalogPull,
      direction: SyncDirection.pull,
      operationStatus: SyncOperationStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }
}
