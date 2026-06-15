import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';

part 'sale.g.dart';

enum PaymentMethod { cash, card, transfer, yappy, other }

enum SaleStatus { completed, cancelled, refunded }

@collection
class Sale extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String? receiptNumber; // número de recibo local
  final DateTime saleDate;
  final String? customerId; // null = cliente ocasional
  final double subtotal;
  final double discount;
  final double taxAmount;
  final double total;
  final double amountPaid;
  final double change;
  final double tipAmount;
  @enumerated
  final PaymentMethod paymentMethod;
  @enumerated
  final SaleStatus status;
  final String? notes;
  final String? cashierName; // quien atendió
  final String? cashierId;
  final String? cashRegisterId; // caja donde se hizo
  @enumerated
  final OrderType orderType;
  final String? openTicketLabel;
  final String? couponCode;
  final double couponDiscount;

  const Sale({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    this.receiptNumber,
    required this.saleDate,
    this.customerId,
    required this.subtotal,
    this.discount = 0,
    required this.taxAmount,
    required this.total,
    required this.amountPaid,
    required this.change,
    this.tipAmount = 0,
    required this.paymentMethod,
    this.status = SaleStatus.completed,
    this.notes,
    this.cashierName,
    this.cashierId,
    this.cashRegisterId,
    this.orderType = OrderType.generic,
    this.openTicketLabel,
    this.couponCode,
    this.couponDiscount = 0,
  });

  @override
  Sale markAsModified() => copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  Sale markAsSynced(String serverId) => copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  Sale markAsDeleted() => copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  Sale copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? receiptNumber,
    DateTime? saleDate,
    String? customerId,
    double? subtotal,
    double? discount,
    double? taxAmount,
    double? total,
    double? amountPaid,
    double? change,
    double? tipAmount,
    PaymentMethod? paymentMethod,
    SaleStatus? status,
    String? notes,
    String? cashierName,
    String? cashierId,
    String? cashRegisterId,
    OrderType? orderType,
    String? openTicketLabel,
    String? couponCode,
    double? couponDiscount,
  }) =>
      Sale(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        receiptNumber: receiptNumber ?? this.receiptNumber,
        saleDate: saleDate ?? this.saleDate,
        customerId: customerId ?? this.customerId,
        subtotal: subtotal ?? this.subtotal,
        discount: discount ?? this.discount,
        taxAmount: taxAmount ?? this.taxAmount,
        total: total ?? this.total,
        amountPaid: amountPaid ?? this.amountPaid,
        change: change ?? this.change,
        tipAmount: tipAmount ?? this.tipAmount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        cashierName: cashierName ?? this.cashierName,
        cashierId: cashierId ?? this.cashierId,
        cashRegisterId: cashRegisterId ?? this.cashRegisterId,
        orderType: orderType ?? this.orderType,
        openTicketLabel: openTicketLabel ?? this.openTicketLabel,
        couponCode: couponCode ?? this.couponCode,
        couponDiscount: couponDiscount ?? this.couponDiscount,
      );

  factory Sale.create({
    required double subtotal,
    required double taxAmount,
    required double total,
    required double amountPaid,
    required double change,
    double tipAmount = 0,
    required PaymentMethod paymentMethod,
    String? receiptNumber,
    String? customerId,
    double discount = 0,
    String? notes,
    String? cashierName,
    String? cashierId,
    String? cashRegisterId,
    OrderType orderType = OrderType.generic,
    String? openTicketLabel,
    String? couponCode,
    double couponDiscount = 0,
  }) =>
      Sale(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        receiptNumber: receiptNumber,
        saleDate: DateTime.now(),
        customerId: customerId,
        subtotal: subtotal,
        discount: discount,
        taxAmount: taxAmount,
        total: total,
        amountPaid: amountPaid,
        change: change,
        tipAmount: tipAmount,
        paymentMethod: paymentMethod,
        notes: notes,
        cashierName: cashierName,
        cashierId: cashierId,
        cashRegisterId: cashRegisterId,
        orderType: orderType,
        openTicketLabel: openTicketLabel,
        couponCode: couponCode,
        couponDiscount: couponDiscount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}