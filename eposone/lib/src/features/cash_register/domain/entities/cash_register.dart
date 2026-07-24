import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';

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

  /// Cajero que abrió el turno (id local Isar o `en1_cashier_<contactId>`).
  final String? openedByCashierId;

  /// EN1 `cashier_contact_id` al abrir (null en Standalone puro).
  final int? openedByCashierContactId;

  /// Cajero actual del turno (puede cambiar sin cerrar caja).
  final String? currentCashierId;
  final int? currentCashierContactId;
  final String? currentCashierName;

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
    this.openedByCashierId,
    this.openedByCashierContactId,
    this.currentCashierId,
    this.currentCashierContactId,
    this.currentCashierName,
  });

  bool get isOpen => status == CashRegisterStatus.open;

  @override
  CashRegister markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: En1DateTimeService.nowUtc());

  @override
  CashRegister markAsSynced(String serverId) => copyWith(
      serverId: serverId,
      syncStatus: SyncStatus.synced,
      updatedAt: En1DateTimeService.nowUtc());

  @override
  CashRegister markAsDeleted() => copyWith(
      deletedAt: En1DateTimeService.nowUtc(),
      syncStatus: SyncStatus.modified,
      updatedAt: En1DateTimeService.nowUtc());

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
    String? openedByCashierId,
    int? openedByCashierContactId,
    String? currentCashierId,
    int? currentCashierContactId,
    String? currentCashierName,
    bool clearOpenedByContactId = false,
    bool clearCurrentContactId = false,
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
        openedByCashierId: openedByCashierId ?? this.openedByCashierId,
        openedByCashierContactId: clearOpenedByContactId
            ? null
            : (openedByCashierContactId ?? this.openedByCashierContactId),
        currentCashierId: currentCashierId ?? this.currentCashierId,
        currentCashierContactId: clearCurrentContactId
            ? null
            : (currentCashierContactId ?? this.currentCashierContactId),
        currentCashierName: currentCashierName ?? this.currentCashierName,
      );

  factory CashRegister.create({
    required double openingAmount,
    String? openedBy,
    String? notes,
    String? openedByCashierId,
    int? openedByCashierContactId,
    String? currentCashierName,
  }) {
    final now = En1DateTimeService.nowUtc();
    return CashRegister(
      // = client_shift_id (idempotencia EN1 Cash Shift HTTP v1.0)
      localId: const Uuid().v4(),
      openDate: now,
      openingAmount: openingAmount,
      openedBy: openedBy,
      notes: notes,
      openedByCashierId: openedByCashierId,
      openedByCashierContactId: openedByCashierContactId,
      currentCashierId: openedByCashierId,
      currentCashierContactId: openedByCashierContactId,
      currentCashierName: currentCashierName ?? openedBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  CashRegister assignCurrentCashier({
    required String cashierId,
    required String cashierName,
    int? cashierContactId,
  }) =>
      copyWith(
        currentCashierId: cashierId,
        currentCashierName: cashierName,
        currentCashierContactId: cashierContactId,
        clearCurrentContactId: cashierContactId == null,
        updatedAt: En1DateTimeService.nowUtc(),
      ).markAsModified();

  CashRegister close({
    required double closingAmount,
    required double expectedAmount,
    String? closedBy,
    String? notes,
  }) =>
      copyWith(
        closeDate: En1DateTimeService.nowUtc(),
        closingAmount: closingAmount,
        expectedAmount: expectedAmount,
        difference: closingAmount - expectedAmount,
        status: CashRegisterStatus.closed,
        closedBy: closedBy,
        notes: notes ?? this.notes,
        syncStatus: SyncStatus.modified,
        updatedAt: En1DateTimeService.nowUtc(),
      );
}
