import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'open_ticket_line.g.dart';

@collection
class OpenTicketLine extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String openTicketId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;

  /// Categoría fiscal del producto al guardar el ticket (snapshot).
  final String? fiscalCategoryCode;

  /// JSON serializado de [SelectedModifier].
  final String? modifiersJson;

  /// Line marked as legal/commercial discount beneficiary (ITEMS scope).
  final bool discountBeneficiary;

  const OpenTicketLine({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.openTicketId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.fiscalCategoryCode,
    this.modifiersJson,
    this.discountBeneficiary = false,
  });

  double get lineTotal => (quantity * unitPrice) - discount;

  @override
  OpenTicketLine markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  OpenTicketLine markAsSynced(String serverId) => copyWith(
      serverId: serverId,
      syncStatus: SyncStatus.synced,
      updatedAt: DateTime.now());

  @override
  OpenTicketLine markAsDeleted() => copyWith(
      deletedAt: DateTime.now(),
      syncStatus: SyncStatus.modified,
      updatedAt: DateTime.now());

  OpenTicketLine copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? openTicketId,
    String? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? discount,
    String? fiscalCategoryCode,
    String? modifiersJson,
    bool clearModifiersJson = false,
    bool? discountBeneficiary,
  }) =>
      OpenTicketLine(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        openTicketId: openTicketId ?? this.openTicketId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        discount: discount ?? this.discount,
        fiscalCategoryCode: fiscalCategoryCode ?? this.fiscalCategoryCode,
        modifiersJson:
            clearModifiersJson ? null : (modifiersJson ?? this.modifiersJson),
        discountBeneficiary:
            discountBeneficiary ?? this.discountBeneficiary,
      );

  factory OpenTicketLine.create({
    required String openTicketId,
    required String productId,
    required String productName,
    required double quantity,
    required double unitPrice,
    double discount = 0,
    String? fiscalCategoryCode,
    String? modifiersJson,
    bool discountBeneficiary = false,
  }) {
    final now = DateTime.now();
    return OpenTicketLine(
      localId: '${openTicketId}_${productId}_${now.millisecondsSinceEpoch}',
      openTicketId: openTicketId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      fiscalCategoryCode: fiscalCategoryCode,
      modifiersJson: modifiersJson,
      discountBeneficiary: discountBeneficiary,
      createdAt: now,
      updatedAt: now,
    );
  }
}
