import 'dart:convert';

import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/orders/domain/entities/order.dart';
import 'package:eposone/src/features/orders/domain/entities/order_event.dart';
import 'package:eposone/src/features/orders/domain/entities/order_item.dart';
import 'package:eposone/src/features/orders/domain/entities/order_payment.dart';
import 'package:uuid/uuid.dart';

/// Mapeo dominio local ↔ JSON contrato Hito 3B.
///
/// Fuente: `Doc/EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`
class OrderMapper {
  OrderMapper._();

  static const _uuid = Uuid();

  static String newEventId() => _uuid.v4();

  /// Body `POST /api/v1/orders`
  static Map<String, dynamic> toCreateRequest({
    required Order order,
    required String eventId,
  }) {
    final cashierContactId = contactIdFromCashierRef(order.cashierId);
    return {
      'local_number': order.localNumber,
      'table_ref': order.tableRef,
      if (cashierContactId == null && order.cashierId != null)
        'user_ref': order.cashierId,
      if (cashierContactId != null) 'cashier_contact_id': cashierContactId,
      'customer_ref': order.customerId,
      'notes': order.notes,
      'tip': order.tipAmount,
      'event_id': eventId,
    };
  }

  /// Body `PATCH /api/v1/orders/{id}`
  static Map<String, dynamic> toPatchRequest({
    required Order order,
    String? eventId,
  }) {
    final cashierContactId = contactIdFromCashierRef(order.cashierId);
    return {
      if (cashierContactId == null && order.cashierId != null)
        'user_ref': order.cashierId,
      if (cashierContactId != null) 'cashier_contact_id': cashierContactId,
      'customer_ref': order.customerId,
      'notes': order.notes,
      'tip': order.tipAmount,
      'local_number': order.localNumber,
      if (eventId != null) 'event_id': eventId,
    };
  }

  /// Body `POST .../events` desde [OrderEvent] local (+ payloadJson).
  static Map<String, dynamic> toEventRequest(OrderEvent event) {
    Map<String, dynamic> payload = {};
    if (event.payloadJson != null && event.payloadJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(event.payloadJson!);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        } else if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    final contact = contactIdFromCashierRef(event.actorId);
    return {
      'event_id': event.localId,
      'type': event.eventType,
      if (contact == null && event.actorId != null)
        'actor_user_ref': event.actorId,
      if (contact != null) 'cashier_contact_id': contact,
      'payload': payload,
    };
  }

  /// Body `POST .../payments`
  static Map<String, dynamic> toPaymentRequest(
    OrderPayment payment, {
    int? cashierContactId,
  }) {
    final kind = payment.isPartial ? 'partial' : 'payment';
    return {
      'amount': payment.amount,
      'method': payment.methodCode,
      'kind': kind,
      if (payment.currency != null) 'currency': payment.currency,
      'customer_ref': null,
      'payment_ref': payment.localId,
      'event_id': _uuid.v4(),
      if (cashierContactId != null) 'cashier_contact_id': cashierContactId,
    };
  }

  /// `en1_cashier_42` o `"42"` → 42. Público para sync de pagos.
  static int? contactIdFromCashierRef(String? ref) {
    if (ref == null || ref.isEmpty) return null;
    if (ref.startsWith('en1_cashier_')) {
      return int.tryParse(ref.substring('en1_cashier_'.length));
    }
    return int.tryParse(ref);
  }

  /// ¿El pedido remoto sigue abierto para el POS?
  static bool isRemoteStillOpen(Map<String, dynamic> remote) {
    final status = remote['status']?.toString().toLowerCase() ?? '';
    final payment = remote['payment_status']?.toString().toLowerCase() ?? '';
    final financiallyClosed = remote['financially_closed'] == true ||
        remote['financially_closed']?.toString().toLowerCase() == 'true';
    if (financiallyClosed) return false;
    if (payment == 'paid' || payment == 'settled') return false;
    const closedStatuses = {
      'closed',
      'paid',
      'cancelled',
      'canceled',
      'returned',
      'voided',
      'refunded',
    };
    if (closedStatuses.contains(status)) return false;
    return true;
  }

  /// Aplica `order` remoto al local (mantiene [Order.localId]).
  static Order applyRemoteOrder(Order local, Map<String, dynamic> remote) {
    final id = remote['id'];
    final serverId = id?.toString();
    final status = remote['status']?.toString() ?? local.lifecycleStatus;
    return local.copyWith(
      serverId: serverId ?? local.serverId,
      syncStatus: SyncStatus.synced,
      localNumber: remote['local_number']?.toString() ?? local.localNumber,
      organizationId:
          remote['organization_id']?.toString() ?? local.organizationId,
      branchRef: remote['branch_ref']?.toString() ?? local.branchRef,
      posRef: remote['pos_ref']?.toString() ?? local.posRef,
      registerRef: remote['register_ref']?.toString() ?? local.registerRef,
      tableRef: remote['table_ref']?.toString() ?? local.tableRef,
      customerId: remote['customer_ref']?.toString() ?? local.customerId,
      cashierId: remote['user_ref']?.toString() ?? local.cashierId,
      notes: remote['notes']?.toString() ?? local.notes,
      lifecycleStatus: status,
      subtotal: _d(remote['subtotal']) ?? local.subtotal,
      taxAmount: _d(remote['tax']) ?? local.taxAmount,
      discount: _d(remote['discount']) ?? local.discount,
      tipAmount: _d(remote['tip']) ?? local.tipAmount,
      total: _d(remote['total']) ?? local.total,
      isOpen: isRemoteStillOpen(remote),
      updatedAt: En1DateTimeService.nowUtc(),
    );
  }

  static Order orderFromRemote(Map<String, dynamic> remote, {String? localId}) {
    final now = En1DateTimeService.nowUtc();
    final id = remote['id']?.toString() ?? '';
    final status = remote['status']?.toString() ?? 'open';
    return Order(
      localId: localId ?? 'en1_order_$id',
      serverId: id.isEmpty ? null : id,
      syncStatus: SyncStatus.synced,
      createdAt: _dt(remote['opened_at']) ?? now,
      updatedAt: _dt(remote['updated_at']) ?? now,
      localNumber: remote['local_number']?.toString(),
      organizationId: remote['organization_id']?.toString(),
      branchRef: remote['branch_ref']?.toString(),
      posRef: remote['pos_ref']?.toString(),
      registerRef: remote['register_ref']?.toString(),
      tableRef: remote['table_ref']?.toString(),
      customerId: remote['customer_ref']?.toString(),
      cashierId: remote['user_ref']?.toString(),
      notes: remote['notes']?.toString(),
      lifecycleStatus: status,
      subtotal: _d(remote['subtotal']) ?? 0,
      taxAmount: _d(remote['tax']) ?? 0,
      discount: _d(remote['discount']) ?? 0,
      tipAmount: _d(remote['tip']) ?? 0,
      total: _d(remote['total']) ?? 0,
      isOpen: isRemoteStillOpen(remote),
    );
  }

  static OrderItem itemFromRemote(
      Map<String, dynamic> remote, String orderLocalId) {
    final now = En1DateTimeService.nowUtc();
    final lineRef = remote['line_ref']?.toString() ??
        remote['id']?.toString() ??
        now.microsecondsSinceEpoch.toString();
    final productRef = remote['product_ref']?.toString() ?? '';
    return OrderItem(
      localId: '${orderLocalId}_$lineRef',
      serverId: remote['id']?.toString(),
      syncStatus: SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
      orderLocalId: orderLocalId,
      productLocalId: productRef,
      productRef: productRef,
      productName: productRef,
      quantity: _d(remote['qty']) ?? 0,
      unitPrice: _d(remote['unit_price']) ?? 0,
      taxAmount: _d(remote['tax']) ?? 0,
      discount: _d(remote['discount']) ?? 0,
      notes: remote['notes']?.toString(),
      lineStatus: remote['line_status']?.toString() ?? 'pending',
      lineRef: lineRef,
    );
  }

  static Map<String, dynamic>? unwrapOrder(Map<String, dynamic> root) {
    final o = root['order'];
    if (o is Map<String, dynamic>) return o;
    if (o is Map) return Map<String, dynamic>.from(o);
    return null;
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    final parsed = DateTime.tryParse(v.toString());
    if (parsed == null) return null;
    return En1DateTimeService.ensureUtc(parsed);
  }
}
