import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'cashier.g.dart';

enum CashierRole { admin, cashier }

@collection
class Cashier extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String name;
  final String pinHash;
  @enumerated
  final CashierRole role;
  final bool active;

  const Cashier({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.name,
    required this.pinHash,
    this.role = CashierRole.cashier,
    this.active = true,
  });

  @override
  Cashier markAsModified() => copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  Cashier markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  Cashier markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  Cashier copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? name,
    String? pinHash,
    CashierRole? role,
    bool? active,
  }) =>
      Cashier(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        name: name ?? this.name,
        pinHash: pinHash ?? this.pinHash,
        role: role ?? this.role,
        active: active ?? this.active,
      );

  factory Cashier.create({
    required String name,
    required String pinHash,
    CashierRole role = CashierRole.cashier,
  }) =>
      Cashier(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        pinHash: pinHash,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
