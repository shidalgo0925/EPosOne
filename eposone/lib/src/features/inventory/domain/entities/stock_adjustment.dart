import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'stock_adjustment.g.dart';

enum StockAdjustmentType {
  count,
  reception,
  loss,
  correction,
}

String stockAdjustmentTypeLabel(StockAdjustmentType type) => switch (type) {
      StockAdjustmentType.count => 'Conteo físico',
      StockAdjustmentType.reception => 'Recepción',
      StockAdjustmentType.loss => 'Merma / pérdida',
      StockAdjustmentType.correction => 'Corrección',
    };

@collection
class StockAdjustment extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String productId;
  final String productName;
  final double previousStock;
  final double newStock;
  final double delta;
  @enumerated
  final StockAdjustmentType type;
  final String? reason;
  final String? cashierId;
  final String? cashierName;
  final DateTime adjustmentDate;

  const StockAdjustment({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.productId,
    required this.productName,
    required this.previousStock,
    required this.newStock,
    required this.delta,
    required this.type,
    this.reason,
    this.cashierId,
    this.cashierName,
    required this.adjustmentDate,
  });

  @override
  StockAdjustment markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  StockAdjustment markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  StockAdjustment markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  StockAdjustment copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? productId,
    String? productName,
    double? previousStock,
    double? newStock,
    double? delta,
    StockAdjustmentType? type,
    String? reason,
    String? cashierId,
    String? cashierName,
    DateTime? adjustmentDate,
  }) =>
      StockAdjustment(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        previousStock: previousStock ?? this.previousStock,
        newStock: newStock ?? this.newStock,
        delta: delta ?? this.delta,
        type: type ?? this.type,
        reason: reason ?? this.reason,
        cashierId: cashierId ?? this.cashierId,
        cashierName: cashierName ?? this.cashierName,
        adjustmentDate: adjustmentDate ?? this.adjustmentDate,
      );

  factory StockAdjustment.create({
    required String productId,
    required String productName,
    required double previousStock,
    required double newStock,
    required StockAdjustmentType type,
    String? reason,
    String? cashierId,
    String? cashierName,
  }) {
    final now = DateTime.now();
    return StockAdjustment(
      localId: now.microsecondsSinceEpoch.toString(),
      productId: productId,
      productName: productName,
      previousStock: previousStock,
      newStock: newStock,
      delta: newStock - previousStock,
      type: type,
      reason: reason,
      cashierId: cashierId,
      cashierName: cashierName,
      adjustmentDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }
}
