import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'sale_item.g.dart';

@collection
class SaleItem extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String saleId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final double total;

  const SaleItem({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.taxRate = 0,
    required this.total,
  });

  @override
  SaleItem markAsModified() => copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  SaleItem markAsSynced(String serverId) => copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  SaleItem markAsDeleted() => copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  SaleItem copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? saleId,
    String? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? discount,
    double? taxRate,
    double? total,
  }) =>
      SaleItem(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        saleId: saleId ?? this.saleId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        discount: discount ?? this.discount,
        taxRate: taxRate ?? this.taxRate,
        total: total ?? this.total,
      );

  factory SaleItem.create({
    required String saleId,
    required String productId,
    required String productName,
    required double quantity,
    required double unitPrice,
    double discount = 0,
    double taxRate = 0,
  }) =>
      SaleItem(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        saleId: saleId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        discount: discount,
        taxRate: taxRate,
        total: (quantity * unitPrice) - discount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}