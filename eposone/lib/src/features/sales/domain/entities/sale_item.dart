import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';

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
  final String? modifiersJson;

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
    this.modifiersJson,
  });

  @override
  SaleItem markAsModified() => copyWith(syncStatus: SyncStatus.modified, updatedAt: En1DateTimeService.nowUtc());

  @override
  SaleItem markAsSynced(String serverId) => copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: En1DateTimeService.nowUtc());

  @override
  SaleItem markAsDeleted() => copyWith(deletedAt: En1DateTimeService.nowUtc(), syncStatus: SyncStatus.modified, updatedAt: En1DateTimeService.nowUtc());

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
    String? modifiersJson,
    bool clearModifiersJson = false,
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
        modifiersJson: clearModifiersJson ? null : (modifiersJson ?? this.modifiersJson),
      );

  factory SaleItem.create({
    required String saleId,
    required String productId,
    required String productName,
    required double quantity,
    required double unitPrice,
    double discount = 0,
    double taxRate = 0,
    String? modifiersJson,
  }) {
    final now = En1DateTimeService.nowUtc();
    // UUID: varios ítems en el mismo ms no deben compartir isarId (hash de localId).
    return SaleItem(
      localId: const Uuid().v4(),
      saleId: saleId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      taxRate: taxRate,
      total: (quantity * unitPrice) - discount,
      modifiersJson: modifiersJson,
      createdAt: now,
      updatedAt: now,
    );
  }
}