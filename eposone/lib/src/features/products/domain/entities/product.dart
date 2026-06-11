import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'product.g.dart';

@collection
class Product extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String name;
  final String? barcode;
  final String? sku;
  final String? description;
  final double price;
  final double? cost;
  final double stock;
  final String? categoryId;
  final String? imagePath;
  final bool isActive;
  final bool allowDecimalQty;
  final double? minStockAlert;

  const Product({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.name,
    this.barcode,
    this.sku,
    this.description,
    required this.price,
    this.cost,
    this.stock = 0,
    this.categoryId,
    this.imagePath,
    this.isActive = true,
    this.allowDecimalQty = false,
    this.minStockAlert,
  });

  double get marginPercent => cost != null && cost! > 0 ? ((price - cost!) / cost!) * 100 : 0;

  @override
  Product markAsModified() => copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  Product markAsSynced(String serverId) => copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  Product markAsDeleted() => copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  Product copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? name,
    String? barcode,
    String? sku,
    String? description,
    double? price,
    double? cost,
    double? stock,
    String? categoryId,
    String? imagePath,
    bool? isActive,
    bool? allowDecimalQty,
    double? minStockAlert,
  }) =>
      Product(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        name: name ?? this.name,
        barcode: barcode ?? this.barcode,
        sku: sku ?? this.sku,
        description: description ?? this.description,
        price: price ?? this.price,
        cost: cost ?? this.cost,
        stock: stock ?? this.stock,
        categoryId: categoryId ?? this.categoryId,
        imagePath: imagePath ?? this.imagePath,
        isActive: isActive ?? this.isActive,
        allowDecimalQty: allowDecimalQty ?? this.allowDecimalQty,
        minStockAlert: minStockAlert ?? this.minStockAlert,
      );

  factory Product.create({
    required String name,
    required double price,
    String? barcode,
    String? sku,
    String? description,
    double? cost,
    double stock = 0,
    String? categoryId,
    bool allowDecimalQty = false,
    double? minStockAlert,
  }) =>
      Product(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        price: price,
        barcode: barcode,
        sku: sku,
        description: description,
        cost: cost,
        stock: stock,
        categoryId: categoryId,
        allowDecimalQty: allowDecimalQty,
        minStockAlert: minStockAlert,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}