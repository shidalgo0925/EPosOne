import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'cash_movement.g.dart';

enum CashMovementType {
  income,
  withdrawal,
  deposit,
  adjustment,
}

String cashMovementTypeLabel(CashMovementType type) => switch (type) {
      CashMovementType.income => 'Entrada',
      CashMovementType.withdrawal => 'Retiro',
      CashMovementType.deposit => 'Depósito',
      CashMovementType.adjustment => 'Ajuste',
    };

/// Movimiento de tesorería asociado a un turno de caja.
@collection
class CashMovement extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String cashRegisterId;
  @enumerated
  final CashMovementType type;
  final double amount;
  final String reason;
  final String? notes;
  final String? cashierId;
  final String? cashierName;
  final DateTime movementDate;

  const CashMovement({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.cashRegisterId,
    required this.type,
    required this.amount,
    required this.reason,
    this.notes,
    this.cashierId,
    this.cashierName,
    required this.movementDate,
  });

  bool get isInflow =>
      type == CashMovementType.income ||
      (type == CashMovementType.adjustment && amount > 0);

  bool get isOutflow =>
      type == CashMovementType.withdrawal ||
      type == CashMovementType.deposit ||
      (type == CashMovementType.adjustment && amount < 0);

  double get signedAmount => isOutflow ? -amount.abs() : amount.abs();

  @override
  CashMovement markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  CashMovement markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  CashMovement markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  CashMovement copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? cashRegisterId,
    CashMovementType? type,
    double? amount,
    String? reason,
    String? notes,
    String? cashierId,
    String? cashierName,
    DateTime? movementDate,
  }) =>
      CashMovement(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        cashRegisterId: cashRegisterId ?? this.cashRegisterId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        reason: reason ?? this.reason,
        notes: notes ?? this.notes,
        cashierId: cashierId ?? this.cashierId,
        cashierName: cashierName ?? this.cashierName,
        movementDate: movementDate ?? this.movementDate,
      );

  factory CashMovement.create({
    required String cashRegisterId,
    required CashMovementType type,
    required double amount,
    required String reason,
    String? notes,
    String? cashierId,
    String? cashierName,
  }) {
    final now = DateTime.now();
    return CashMovement(
      localId: now.millisecondsSinceEpoch.toString(),
      cashRegisterId: cashRegisterId,
      type: type,
      amount: amount.abs(),
      reason: reason,
      notes: notes,
      cashierId: cashierId,
      cashierName: cashierName,
      movementDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }
}
