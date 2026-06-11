import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'cash_register.g.dart';

enum CashRegisterStatus { open, closed }

@collection
class CashRegister extends SyncEntity {
  Id get isarId => localId.hashCode;

  final DateTime openDate;
  final DateTime? closeDate;
  final double openingAmount;
  final double? closingAmount;
  final double? expectedAmount;
  final double? difference;
  @enumerated
  final CashRegisterStatus status;
  final String? openedBy;
  final String? closedBy;
  final String? notes;

  const CashRegister({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.openDate,
    this.closeDate,
    required this.openingAmount,
    this.closingAmount,
    this.expectedAmount,
    this.difference,
    this.status = CashRegisterStatus.open,
    this.openedBy,
    this.closedBy,
    this.notes,
  });

  bool get isOpen => status == CashRegisterStatus.open;

  @override
  CashRegister markAsModified() => copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  CashRegister markAsSynced(String serverId) => copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  CashRegister markAsDeleted() => copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  CashRegister copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? openDate,
    DateTime? closeDate,
    double? openingAmount,
    double? closingAmount,
    double? expectedAmount,
    double? difference,
    CashRegisterStatus? status,
    String? openedBy,
    String? closedBy,
    String? notes,
  }) =>
      CashRegister(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        openDate: openDate ?? this.openDate,
        closeDate: closeDate ?? this.closeDate,
        openingAmount: openingAmount ?? this.openingAmount,
        closingAmount: closingAmount ?? this.closingAmount,
        expectedAmount: expectedAmount ?? this.expectedAmount,
        difference: difference ?? this.difference,
        status: status ?? this.status,
        openedBy: openedBy ?? this.openedBy,
        closedBy: closedBy ?? this.closedBy,
        notes: notes ?? this.notes,
      );

  factory CashRegister.create({
    required double openingAmount,
    String? openedBy,
    String? notes,
  }) =>
      CashRegister(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        openDate: DateTime.now(),
        openingAmount: openingAmount,
        openedBy: openedBy,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  CashRegister close({
    required double closingAmount,
    required double expectedAmount,
    String? closedBy,
    String? notes,
  }) =>
      copyWith(
        closeDate: DateTime.now(),
        closingAmount: closingAmount,
        expectedAmount: expectedAmount,
        difference: closingAmount - expectedAmount,
        status: CashRegisterStatus.closed,
        closedBy: closedBy,
        notes: notes ?? this.notes,
        updatedAt: DateTime.now(),
      );
}