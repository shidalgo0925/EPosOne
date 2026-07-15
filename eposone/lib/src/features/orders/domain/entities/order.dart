import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'order.g.dart';

/// Pedido local (dominio Hito 3B).
///
/// Campos = modelo operativo local. Mapeo HTTP **solo** tras
/// `Doc/EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`.
@collection
class Order extends SyncEntity {
  Id get isarId => localId.hashCode;

  /// Número / etiqueta visible en POS (mesa, ticket, etc.).
  final String? localNumber;

  /// Referencias de jerarquía (desde provisioning); no inventar schema EN1.
  final String? organizationId;
  final String? branchRef;
  final String? posRef;
  final String? registerRef;
  final String? tableRef;

  final String? customerId;
  final String? cashierId;
  final String? notes;

  /// Estado interno opaco hasta alinear con contrato (`draft`, `open`, …).
  final String lifecycleStatus;

  final double subtotal;
  final double taxAmount;
  final double discount;
  final double tipAmount;
  final double total;

  /// true = aún editable en este POS (ownership local).
  final bool isOpen;

  /// Hito 3B.1: hay cambios locales pendientes de sync EN1.
  final bool dirty;

  const Order({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    this.localNumber,
    this.organizationId,
    this.branchRef,
    this.posRef,
    this.registerRef,
    this.tableRef,
    this.customerId,
    this.cashierId,
    this.notes,
    this.lifecycleStatus = 'open',
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discount = 0,
    this.tipAmount = 0,
    this.total = 0,
    this.isOpen = true,
    this.dirty = true,
  });

  @override
  Order markAsModified() => copyWith(
        syncStatus: SyncStatus.modified,
        dirty: true,
        updatedAt: DateTime.now(),
      );

  @override
  Order markAsSynced(String serverId) => copyWith(
        serverId: serverId,
        syncStatus: SyncStatus.synced,
        dirty: false,
        updatedAt: DateTime.now(),
      );

  @override
  Order markAsDeleted() => copyWith(
        deletedAt: DateTime.now(),
        syncStatus: SyncStatus.modified,
        updatedAt: DateTime.now(),
      );

  Order copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? localNumber,
    String? organizationId,
    String? branchRef,
    String? posRef,
    String? registerRef,
    String? tableRef,
    String? customerId,
    String? cashierId,
    String? notes,
    String? lifecycleStatus,
    double? subtotal,
    double? taxAmount,
    double? discount,
    double? tipAmount,
    double? total,
    bool? isOpen,
    bool? dirty,
  }) =>
      Order(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        localNumber: localNumber ?? this.localNumber,
        organizationId: organizationId ?? this.organizationId,
        branchRef: branchRef ?? this.branchRef,
        posRef: posRef ?? this.posRef,
        registerRef: registerRef ?? this.registerRef,
        tableRef: tableRef ?? this.tableRef,
        customerId: customerId ?? this.customerId,
        cashierId: cashierId ?? this.cashierId,
        notes: notes ?? this.notes,
        lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
        subtotal: subtotal ?? this.subtotal,
        taxAmount: taxAmount ?? this.taxAmount,
        discount: discount ?? this.discount,
        tipAmount: tipAmount ?? this.tipAmount,
        total: total ?? this.total,
        isOpen: isOpen ?? this.isOpen,
        dirty: dirty ?? this.dirty,
      );

  factory Order.createLocal({
    String? localNumber,
    String? organizationId,
    String? branchRef,
    String? posRef,
    String? registerRef,
    String? tableRef,
    String? customerId,
    String? cashierId,
    String? notes,
  }) {
    final now = DateTime.now();
    return Order(
      localId: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      localNumber: localNumber,
      organizationId: organizationId,
      branchRef: branchRef,
      posRef: posRef,
      registerRef: registerRef,
      tableRef: tableRef,
      customerId: customerId,
      cashierId: cashierId,
      notes: notes,
      lifecycleStatus: 'open',
      isOpen: true,
      dirty: true,
    );
  }
}
