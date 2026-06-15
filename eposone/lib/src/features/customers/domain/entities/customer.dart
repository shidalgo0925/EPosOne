import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'customer.g.dart';

@collection
class Customer extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String name;
  final String? phone;
  final String? email;
  final String? document; // cédula, RUC, etc.
  final String? address;
  final String? notes;
  final int loyaltyPoints;

  const Customer({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.name,
    this.phone,
    this.email,
    this.document,
    this.address,
    this.notes,
    this.loyaltyPoints = 0,
  });

  @override
  Customer markAsModified() => copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  Customer markAsSynced(String serverId) => copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  Customer markAsDeleted() => copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  Customer copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? name,
    String? phone,
    String? email,
    String? document,
    String? address,
    String? notes,
    int? loyaltyPoints,
  }) =>
      Customer(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        document: document ?? this.document,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      );

  factory Customer.create({
    required String name,
    String? phone,
    String? email,
    String? document,
    String? address,
    String? notes,
  }) =>
      Customer(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: phone,
        email: email,
        document: document,
        address: address,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  String get displayName => name.isNotEmpty ? name : (document ?? phone ?? 'Cliente ocasional');
}