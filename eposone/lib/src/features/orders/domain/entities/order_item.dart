import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'order_item.g.dart';

/// Línea de pedido local.
@collection
class OrderItem extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String orderLocalId;
  final String productLocalId;
  final String? productRef;
  /// Identificador de línea estable (`line_ref` del contrato).
  final String lineRef;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double taxAmount;
  final double discount;
  final String? notes;
  final String lineStatus;

  const OrderItem({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.orderLocalId,
    required this.productLocalId,
    this.productRef,
    required this.lineRef,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.taxAmount = 0,
    this.discount = 0,
    this.notes,
    this.lineStatus = 'pending',
  });

  double get lineTotal => (unitPrice * quantity) - discount + taxAmount;

  @override
  OrderItem markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  OrderItem markAsSynced(String serverId) => copyWith(
        serverId: serverId,
        syncStatus: SyncStatus.synced,
        updatedAt: DateTime.now(),
      );

  @override
  OrderItem markAsDeleted() => copyWith(
        deletedAt: DateTime.now(),
        syncStatus: SyncStatus.modified,
        updatedAt: DateTime.now(),
      );

  OrderItem copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? orderLocalId,
    String? productLocalId,
    String? productRef,
    String? lineRef,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? taxAmount,
    double? discount,
    String? notes,
    String? lineStatus,
  }) =>
      OrderItem(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        orderLocalId: orderLocalId ?? this.orderLocalId,
        productLocalId: productLocalId ?? this.productLocalId,
        productRef: productRef ?? this.productRef,
        lineRef: lineRef ?? this.lineRef,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        taxAmount: taxAmount ?? this.taxAmount,
        discount: discount ?? this.discount,
        notes: notes ?? this.notes,
        lineStatus: lineStatus ?? this.lineStatus,
      );

  factory OrderItem.create({
    required String orderLocalId,
    required String lineRef,
    required String productLocalId,
    String? productRef,
    required String productName,
    required double quantity,
    required double unitPrice,
    double taxAmount = 0,
    double discount = 0,
    String? notes,
  }) {
    final now = DateTime.now();
    return OrderItem(
      localId: '${orderLocalId}_$lineRef',
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      orderLocalId: orderLocalId,
      productLocalId: productLocalId,
      productRef: productRef,
      lineRef: lineRef,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      taxAmount: taxAmount,
      discount: discount,
      notes: notes,
      lineStatus: 'pending',
    );
  }
}
