import 'dart:convert';

import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';
import 'package:eposone/src/features/orders/data/en1_orders_api.dart';
import 'package:eposone/src/features/orders/data/order_mapper.dart';
import 'package:eposone/src/features/orders/data/order_repository.dart';
import 'package:eposone/src/features/orders/data/order_sync_diag.dart';
import 'package:eposone/src/features/orders/domain/entities/order.dart';
import 'package:eposone/src/features/orders/domain/entities/order_event.dart';
import 'package:eposone/src/features/orders/domain/entities/order_item.dart';
import 'package:eposone/src/features/orders/domain/entities/order_payment.dart';
import 'package:eposone/src/features/orders/domain/en1_tender_methods.dart';
import 'package:eposone/src/features/orders/domain/order_event_audit.dart';
import 'package:eposone/src/features/orders/domain/order_lifecycle.dart';
import 'package:eposone/src/features/pos/data/repositories/open_ticket_repository.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';

/// Línea del carrito POS para mapear a Order Domain.
class PosOrderLineInput {
  const PosOrderLineInput({
    required this.productLocalId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.productRef,
    this.discount = 0,
    this.notes,
  });

  final String productLocalId;
  final String? productRef;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final String? notes;
}

/// Operación del Pedido: local offline-first + sync HTTP contrato 3B.
class OrderService {
  OrderService({
    required OrderRepository repository,
    required SyncRepository syncRepository,
    required CommercialEngineFacade commercialEngine,
    OpenTicketRepository? openTicketRepository,
    En1OrdersApi? en1Api,
  })  : _repo = repository,
        _sync = syncRepository,
        _commercialEngine = commercialEngine,
        _openTickets = openTicketRepository,
        _api = en1Api ?? En1OrdersApi();

  final OrderRepository _repo;
  final SyncRepository _sync;
  final CommercialEngineFacade _commercialEngine;
  final OpenTicketRepository? _openTickets;
  final En1OrdersApi _api;

  Future<List<OrderPayment>> paymentsOf(String orderLocalId) =>
      _repo.paymentsOf(orderLocalId);

  Future<List<OrderEvent>> eventsOf(String orderLocalId) =>
      _repo.eventsOf(orderLocalId);

  Future<Order> createOrder({
    String? localNumber,
    String? organizationId,
    String? branchRef,
    String? posRef,
    String? registerRef,
    String? tableRef,
    String? customerId,
    String? cashierId,
    String? notes,
  }) async {
    final createEventId = OrderMapper.newEventId();
    final order = Order.createLocal(
      localNumber: localNumber,
      organizationId: organizationId,
      branchRef: branchRef,
      posRef: posRef,
      registerRef: registerRef,
      tableRef: tableRef,
      customerId: customerId,
      cashierId: cashierId,
      notes: notes,
    );
    final evt = OrderEvent.record(
      orderLocalId: order.localId,
      eventType: OrderEventTypes.created,
      actorId: cashierId,
      eventId: createEventId,
      payloadJson: jsonEncode({
        'local_number': localNumber,
        'table_ref': tableRef,
      }),
    );
    await _repo.saveOrderBundle(order: order, event: evt);
    await _enqueueSync(order.localId);
    // Best-effort inmediato; si falla, queda en cola.
    try {
      await syncOrderToEn1(order.localId);
    } catch (_) {}
    return (await _repo.getByLocalId(order.localId)) ?? order;
  }

  Future<OrderItem> addProduct({
    required String orderLocalId,
    required String productLocalId,
    String? productRef,
    required String productName,
    required double quantity,
    required double unitPrice,
    double taxAmount = 0,
    double discount = 0,
    String? notes,
    String? actorId,
  }) async {
    final order = await _requireOpen(orderLocalId);
    final lineRef = await _nextLineRef(orderLocalId);
    final item = OrderItem.create(
      orderLocalId: orderLocalId,
      lineRef: lineRef,
      productLocalId: productLocalId,
      productRef: productRef,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      taxAmount: taxAmount,
      discount: discount,
      notes: notes,
    );
    final evt = OrderEvent.record(
      orderLocalId: orderLocalId,
      eventType: OrderEventTypes.productAdded,
      actorId: actorId,
      payloadJson: jsonEncode({
        'line_ref': lineRef,
        'product_ref': productRef ?? productLocalId,
        'qty': quantity,
        'unit_price': unitPrice,
        'tax': taxAmount,
        'discount': discount,
        'notes': notes,
      }),
    );
    await _repo.putItem(item);
    await _repo.putEvent(evt);
    await _repo.putOrder(order.markAsModified());
    await _repo.recomputeTotals(orderLocalId);
    await _enqueueSync(orderLocalId);
    try {
      await syncOrderToEn1(orderLocalId);
    } catch (_) {}
    return item;
  }

  Future<void> removeProduct({
    required String orderLocalId,
    required String itemLocalId,
    String? actorId,
  }) async {
    await _requireOpen(orderLocalId);
    final items = await _repo.itemsOf(orderLocalId);
    OrderItem? item;
    for (final i in items) {
      if (i.localId == itemLocalId) {
        item = i;
        break;
      }
    }
    if (item == null) return;
    await _repo.putItem(item.markAsDeleted());
    await _repo.putEvent(
      OrderEvent.record(
        orderLocalId: orderLocalId,
        eventType: OrderEventTypes.productRemoved,
        actorId: actorId,
        payloadJson: jsonEncode({'line_ref': item.lineRef}),
      ),
    );
    await _repo.recomputeTotals(orderLocalId);
    await _enqueueSync(orderLocalId);
    try {
      await syncOrderToEn1(orderLocalId);
    } catch (_) {}
  }

  Future<void> changeQuantity({
    required String orderLocalId,
    required String itemLocalId,
    required double quantity,
    String? actorId,
  }) async {
    await _requireOpen(orderLocalId);
    final items = await _repo.itemsOf(orderLocalId);
    OrderItem? item;
    for (final i in items) {
      if (i.localId == itemLocalId) {
        item = i;
        break;
      }
    }
    if (item == null) return;
    await _repo.putItem(item.copyWith(quantity: quantity).markAsModified());
    await _repo.putEvent(
      OrderEvent.record(
        orderLocalId: orderLocalId,
        eventType: OrderEventTypes.qtyChanged,
        actorId: actorId,
        payloadJson: jsonEncode({
          'line_ref': item.lineRef,
          'qty': quantity,
        }),
      ),
    );
    await _repo.recomputeTotals(orderLocalId);
    await _enqueueSync(orderLocalId);
    try {
      await syncOrderToEn1(orderLocalId);
    } catch (_) {}
  }

  Future<void> updateNotes({
    required String orderLocalId,
    required String notes,
    String? actorId,
  }) async {
    final order = await _requireOpen(orderLocalId);
    await _repo.putOrder(order.copyWith(notes: notes).markAsModified());
    await _repo.putEvent(
      OrderEvent.record(
        orderLocalId: orderLocalId,
        eventType: OrderEventTypes.updated,
        actorId: actorId,
        payloadJson: jsonEncode({'notes': notes}),
      ),
    );
    await _enqueueSync(orderLocalId);
    try {
      await syncOrderToEn1(orderLocalId);
    } catch (_) {}
  }

  Future<OrderPayment> collectPayment({
    required String orderLocalId,
    required String methodCode,
    required double amount,
    String? currency,
    String? notes,
    bool isPartial = false,
    String? actorId,
    bool closeOrder = true,
  }) async {
    final payments = await collectPayments(
      orderLocalId: orderLocalId,
      tenders: [TenderAmount(code: methodCode, amount: amount)],
      currency: currency,
      notes: notes,
      actorId: actorId,
      closeOrder: closeOrder,
      forcePartial: isPartial,
    );
    return payments.first;
  }

  /// Pago mixto: N tenders → N `OrderPayment` → N× `POST /payments` en sync.
  Future<List<OrderPayment>> collectPayments({
    required String orderLocalId,
    required List<TenderAmount> tenders,
    String? currency,
    String? notes,
    String? actorId,
    bool closeOrder = true,
    bool forcePartial = false,
  }) async {
    final positive = tenders.where((t) => t.amount > 0.00001).toList();
    if (positive.isEmpty) throw StateError('Sin montos de pago');

    final order = await _requireOpen(orderLocalId);
    final existing = await _repo.paymentsOf(orderLocalId);
    final alreadyPaid =
        _commercialEngine.sumPayments(existing.map((p) => p.amount));
    final balanceDue = _commercialEngine.outstandingBalance(
      total: order.total,
      paid: alreadyPaid,
    );

    final settlement = _commercialEngine
        .evaluatePayment(balanceDue: balanceDue, entered: positive)
        .settlement;
    if (settlement == null || settlement.paymentsToPost.isEmpty) {
      throw StateError('Montos de pago no cubren el saldo ($balanceDue)');
    }

    final paySum = _commercialEngine
        .sumPayments(settlement.paymentsToPost.map((t) => t.amount));
    final covers = _commercialEngine.outstandingBalance(
          total: balanceDue,
          paid: paySum,
        ) <=
        0.009;
    final isPartial = forcePartial || !covers;

    final created = <OrderPayment>[];
    for (final t in settlement.paymentsToPost) {
      created.add(
        OrderPayment.create(
          orderLocalId: orderLocalId,
          methodCode: t.code,
          amount: t.amount,
          currency: currency ?? 'USD',
          notes: t.reference ?? notes,
          isPartial: isPartial,
        ),
      );
    }

    final updated = closeOrder && covers && !isPartial
        ? order
            .copyWith(isOpen: false, lifecycleStatus: 'paid')
            .markAsModified()
        : order.markAsModified();

    await _repo.saveOrderBundle(order: updated, payments: created);
    await _enqueueSync(orderLocalId);
    try {
      await syncOrderToEn1(orderLocalId);
    } catch (_) {}
    return created;
  }

  /// Guardar ticket POS → Pedido abierto EN1 (nace antes del cobro).
  Future<Order> upsertOpenOrderFromPosCart({
    required String localNumber,
    required List<PosOrderLineInput> lines,
    required double subtotal,
    required double taxAmount,
    required double discount,
    required double total,
    String? existingOrderLocalId,
    BusinessConfig? config,
    String? customerId,
    String? cashierId,
    String? tableRef,
    String? notes,
    bool syncNow = true,
    String? organizationId,
    String? posRef,
    String? registerRef,
  }) async {
    if (lines.isEmpty) throw StateError('Pedido POS sin líneas');

    final existing = existingOrderLocalId == null
        ? null
        : await _repo.getByLocalId(existingOrderLocalId);

    if (existing != null && existing.isOpen) {
      return _replaceOpenOrderLines(
        order: existing,
        lines: lines,
        subtotal: subtotal,
        taxAmount: taxAmount,
        discount: discount,
        total: total,
        localNumber: localNumber,
        customerId: customerId,
        cashierId: cashierId,
        tableRef: tableRef,
        notes: notes,
        config: config,
        syncNow: syncNow,
      );
    }

    final createEventId = OrderMapper.newEventId();
    final draft = Order.createLocal(
      localNumber: localNumber,
      organizationId: organizationId,
      branchRef: config?.en1BranchId,
      posRef: posRef,
      registerRef: registerRef,
      customerId: customerId,
      cashierId: cashierId,
      tableRef: tableRef,
      notes: notes,
    );

    final orderItems = <OrderItem>[];
    final events = <OrderEvent>[
      OrderEvent.record(
        orderLocalId: draft.localId,
        eventType: OrderEventTypes.created,
        actorId: cashierId,
        eventId: createEventId,
        payloadJson: jsonEncode({
          'local_number': localNumber,
          'table_ref': tableRef,
          'source': 'pos_save',
        }),
      ),
    ];

    _appendLineItemsAndEvents(
      orderLocalId: draft.localId,
      lines: lines,
      taxAmount: taxAmount,
      cashierId: cashierId,
      orderItems: orderItems,
      events: events,
    );

    final open = draft.copyWith(
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: discount,
      tipAmount: 0,
      total: total,
      dirty: true,
      lifecycleStatus: 'open',
      isOpen: true,
    );

    await _repo.saveOrderBundle(order: open, items: orderItems, events: events);
    await _enqueueSync(draft.localId);
    if (syncNow) {
      try {
        await syncOrderToEn1(draft.localId, config: config);
      } catch (_) {}
    }
    return (await _repo.getByLocalId(draft.localId)) ?? open;
  }

  Future<Order> sendOrder({
    required String orderLocalId,
    String? actorId,
    BusinessConfig? config,
    bool syncNow = true,
  }) async {
    final order = await _requireOpen(orderLocalId);
    await _repo.putEvent(
      OrderEvent.record(
        orderLocalId: orderLocalId,
        eventType: OrderEventTypes.sent,
        actorId: actorId,
        payloadJson: '{}',
      ),
    );
    await _repo.putOrder(
      order.copyWith(lifecycleStatus: 'sent').markAsModified(),
    );
    await _enqueueSync(orderLocalId);
    if (syncNow) {
      try {
        await syncOrderToEn1(orderLocalId, config: config);
      } catch (_) {}
    }
    return (await _repo.getByLocalId(orderLocalId)) ?? order;
  }

  /// Anula post-cocina: status VOIDED + mismo evento `pedido.anulado` (contrato EN1).
  /// Internamente mismo canal HTTP que cancel; distinto estado local / UI.
  Future<Order> voidOrder({
    required String orderLocalId,
    required String reason,
    String? actorId,
    BusinessConfig? config,
    bool syncNow = true,
    String? organizationId,
    String? registerId,
    String? deviceId,
    String? shiftId,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Anulación requiere motivo');
    }
    if (!OrderActionPolicy.cashierMayVoid(hasReason: true)) {
      throw StateError('Sin permiso para anular');
    }

    final order = await _repo.getByLocalId(orderLocalId);
    if (order == null) throw StateError('Pedido no encontrado: $orderLocalId');
    if (OrderLifecycle.isCancelledLike(order.lifecycleStatus)) {
      return order;
    }
    if (!OrderLifecycle.canVoid(order.lifecycleStatus)) {
      throw StateError(
        'No se puede anular un pedido en estado ${order.lifecycleStatus}. '
        'Use Cancelar (pre-cocina) o Reembolsar (cobrado).',
      );
    }

    final audit = OrderEventAudit(
      reason: trimmed,
      origin: OrderEventOriginCode.eposone,
      organizationId: organizationId ?? order.organizationId,
      registerId: registerId ?? order.registerRef,
      deviceId: deviceId,
      shiftId: shiftId,
      createdBy: actorId,
      extra: const {'action': 'void'},
    );

    await _repo.putEvent(
      OrderEvent.record(
        orderLocalId: orderLocalId,
        eventType: OrderEventTypes.voided,
        actorId: actorId,
        payloadJson: audit.toPayloadJson(),
      ),
    );
    await _repo.putOrder(
      order
          .copyWith(
            isOpen: false,
            lifecycleStatus: OrderLifecycle.voided,
          )
          .markAsModified(),
    );
    await _enqueueSync(orderLocalId);
    if (syncNow) {
      try {
        await syncOrderToEn1(orderLocalId, config: config);
      } catch (_) {}
    }
    return (await _repo.getByLocalId(orderLocalId)) ?? order;
  }

  /// Cancela pre-cocina: status CANCELLED + evento `pedido.anulado`.
  /// Nunca elimina registros físicos del Order Domain.
  Future<Order> cancelOrder({
    required String orderLocalId,
    required String reason,
    String? actorId,
    BusinessConfig? config,
    bool syncNow = true,
    String? organizationId,
    String? registerId,
    String? deviceId,
    String? shiftId,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Cancelación requiere motivo');
    }
    if (!OrderActionPolicy.cashierMayCancelConfirmed(hasReason: true)) {
      throw StateError('Sin permiso para cancelar');
    }

    final order = await _repo.getByLocalId(orderLocalId);
    if (order == null) throw StateError('Pedido no encontrado: $orderLocalId');
    if (OrderLifecycle.isCancelledLike(order.lifecycleStatus)) {
      return order;
    }
    // Si ya fue a cocina, redirigir a anulación (misma cola EN1).
    if (OrderLifecycle.canVoid(order.lifecycleStatus)) {
      return voidOrder(
        orderLocalId: orderLocalId,
        reason: trimmed,
        actorId: actorId,
        config: config,
        syncNow: syncNow,
        organizationId: organizationId,
        registerId: registerId,
        deviceId: deviceId,
        shiftId: shiftId,
      );
    }
    if (!OrderLifecycle.canCancel(order.lifecycleStatus)) {
      throw StateError(
        'No se puede cancelar un pedido en estado ${order.lifecycleStatus}',
      );
    }

    final audit = OrderEventAudit(
      reason: trimmed,
      origin: OrderEventOriginCode.eposone,
      organizationId: organizationId ?? order.organizationId,
      registerId: registerId ?? order.registerRef,
      deviceId: deviceId,
      shiftId: shiftId,
      createdBy: actorId,
      extra: const {'action': 'cancel'},
    );

    await _repo.putEvent(
      OrderEvent.record(
        orderLocalId: orderLocalId,
        eventType: OrderEventTypes.voided,
        actorId: actorId,
        payloadJson: audit.toPayloadJson(),
      ),
    );
    await _repo.putOrder(
      order
          .copyWith(
            isOpen: false,
            lifecycleStatus: OrderLifecycle.cancelled,
          )
          .markAsModified(),
    );
    await _enqueueSync(orderLocalId);
    if (syncNow) {
      try {
        await syncOrderToEn1(orderLocalId, config: config);
      } catch (_) {}
    }
    return (await _repo.getByLocalId(orderLocalId)) ?? order;
  }

  /// Reembolso / devolución post-cobro: evento `pedido.devuelto` (contrato).
  Future<Order> refundOrder({
    required String orderLocalId,
    required String reason,
    String? actorId,
    BusinessConfig? config,
    bool syncNow = true,
    double? amount,
    String? organizationId,
    String? registerId,
    String? deviceId,
    String? shiftId,
  }) async {
    final trimmed = reason.trim();
    if (!OrderActionPolicy.mayRefund(hasReason: trimmed.isNotEmpty)) {
      throw ArgumentError('Reembolso requiere motivo');
    }
    final order = await _repo.getByLocalId(orderLocalId);
    if (order == null) throw StateError('Pedido no encontrado: $orderLocalId');
    if (!OrderLifecycle.canRefund(order.lifecycleStatus) &&
        OrderLifecycle.normalize(order.lifecycleStatus) !=
            OrderLifecycle.refunded) {
      throw StateError(
        'Solo se puede reembolsar un pedido cobrado '
        '(estado: ${order.lifecycleStatus})',
      );
    }
    if (OrderLifecycle.normalize(order.lifecycleStatus) ==
            OrderLifecycle.refunded ||
        OrderLifecycle.normalize(order.lifecycleStatus) ==
            OrderLifecycle.returned) {
      return order;
    }

    final audit = OrderEventAudit(
      reason: trimmed,
      origin: OrderEventOriginCode.eposone,
      organizationId: organizationId ?? order.organizationId,
      registerId: registerId ?? order.registerRef,
      deviceId: deviceId,
      shiftId: shiftId,
      createdBy: actorId,
      extra: {
        if (amount != null) 'amount': amount,
      },
    );

    await _repo.putEvent(
      OrderEvent.record(
        orderLocalId: orderLocalId,
        eventType: OrderEventTypes.returned,
        actorId: actorId,
        payloadJson: audit.toPayloadJson(),
      ),
    );
    await _repo.putOrder(
      order
          .copyWith(
            isOpen: false,
            lifecycleStatus: OrderLifecycle.refunded,
          )
          .markAsModified(),
    );
    await _enqueueSync(orderLocalId);
    if (syncNow) {
      try {
        await syncOrderToEn1(orderLocalId, config: config);
      } catch (_) {}
    }
    return (await _repo.getByLocalId(orderLocalId)) ?? order;
  }

  Future<Order> closeOrder({
    required String orderLocalId,
    String? actorId,
    BusinessConfig? config,
    bool syncNow = true,
  }) async {
    final order = await _requireOpen(orderLocalId);
    await _repo.putEvent(
      OrderEvent.record(
        orderLocalId: orderLocalId,
        eventType: OrderEventTypes.updated,
        actorId: actorId,
        payloadJson: jsonEncode({'lifecycle': 'closed'}),
      ),
    );
    await _repo.putOrder(
      order.copyWith(isOpen: false, lifecycleStatus: 'closed').markAsModified(),
    );
    await _enqueueSync(orderLocalId);
    if (syncNow) {
      try {
        await syncOrderToEn1(orderLocalId, config: config);
      } catch (_) {}
    }
    return (await _repo.getByLocalId(orderLocalId)) ?? order;
  }

  /// Cobro POS → Pedido Order Domain (Hito 3). Un solo sync al final.
  ///
  /// Preferir [paymentTenders] (pago mixto). Si viene vacío, usa
  /// [methodCode] + [paymentAmount] (compat).
  Future<Order> createPaidOrderFromPosSale({
    required String localNumber,
    required List<PosOrderLineInput> lines,
    String? methodCode,
    double? paymentAmount,
    List<TenderAmount> paymentTenders = const [],
    required double subtotal,
    required double taxAmount,
    required double discount,
    required double tipAmount,
    required double total,
    BusinessConfig? config,
    String? customerId,
    String? cashierId,
    String? tableRef,
    String? notes,
    String? currency,
    String? existingOrderLocalId,
    String? organizationId,
    String? posRef,
    String? registerRef,
  }) async {
    if (lines.isEmpty) throw StateError('Pedido POS sin líneas');

    final tenders = paymentTenders.isNotEmpty
        ? paymentTenders
        : [
            TenderAmount(
              code: methodCode ?? 'cash',
              amount: paymentAmount ?? total,
            ),
          ];

    if (existingOrderLocalId != null) {
      final existing = await _repo.getByLocalId(existingOrderLocalId);
      if (existing != null && existing.isOpen) {
        await _replaceOpenOrderLines(
          order: existing,
          lines: lines,
          subtotal: subtotal,
          taxAmount: taxAmount,
          discount: discount,
          total: total - tipAmount,
          localNumber: localNumber,
          customerId: customerId,
          cashierId: cashierId,
          tableRef: tableRef,
          notes: notes,
          config: config,
          syncNow: false,
        );
        final withTip = (await _repo.getByLocalId(existingOrderLocalId))!;
        await _repo.putOrder(
          withTip.copyWith(tipAmount: tipAmount, total: total).markAsModified(),
        );
        await collectPayments(
          orderLocalId: existingOrderLocalId,
          tenders: tenders,
          currency: currency ?? config?.currency ?? 'USD',
          actorId: cashierId,
          closeOrder: true,
        );
        return (await _repo.getByLocalId(existingOrderLocalId)) ?? withTip;
      }
    }

    final createEventId = OrderMapper.newEventId();
    final draft = Order.createLocal(
      localNumber: localNumber,
      organizationId: organizationId,
      branchRef: config?.en1BranchId,
      posRef: posRef,
      registerRef: registerRef,
      customerId: customerId,
      cashierId: cashierId,
      tableRef: tableRef,
      notes: notes,
    );

    final orderItems = <OrderItem>[];
    final events = <OrderEvent>[
      OrderEvent.record(
        orderLocalId: draft.localId,
        eventType: OrderEventTypes.created,
        actorId: cashierId,
        eventId: createEventId,
        payloadJson: jsonEncode({
          'local_number': localNumber,
          'table_ref': tableRef,
          'source': 'pos_sale',
        }),
      ),
    ];

    final lineBaseSum = lines.fold<double>(
      0,
      (s, l) =>
          s +
          ((l.unitPrice * l.quantity) - l.discount).clamp(0, double.infinity),
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineRef = 'L${i + 1}';
      final lineBase = ((line.unitPrice * line.quantity) - line.discount)
          .clamp(0, double.infinity);
      final lineTax =
          lineBaseSum > 0 ? taxAmount * (lineBase / lineBaseSum) : 0.0;
      final productRef = line.productRef ?? line.productLocalId;

      orderItems.add(
        OrderItem.create(
          orderLocalId: draft.localId,
          lineRef: lineRef,
          productLocalId: line.productLocalId,
          productRef: productRef,
          productName: line.productName,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          taxAmount: lineTax,
          discount: line.discount,
          notes: line.notes,
        ),
      );
      events.add(
        OrderEvent.record(
          orderLocalId: draft.localId,
          eventType: OrderEventTypes.productAdded,
          actorId: cashierId,
          payloadJson: jsonEncode({
            'line_ref': lineRef,
            'product_ref': productRef,
            'qty': line.quantity,
            'unit_price': line.unitPrice,
            'tax': lineTax,
            'discount': line.discount,
            'notes': line.notes,
          }),
        ),
      );
    }

    final paid = draft.copyWith(
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: discount,
      tipAmount: tipAmount,
      total: total,
      isOpen: false,
      lifecycleStatus: 'paid',
    );

    final settlement = _commercialEngine
        .evaluatePayment(balanceDue: total, entered: tenders)
        .settlement;
    if (settlement == null || settlement.paymentsToPost.isEmpty) {
      throw StateError('Montos de pago no cubren el total del pedido');
    }

    final orderPayments = settlement.paymentsToPost
        .map(
          (t) => OrderPayment.create(
            orderLocalId: draft.localId,
            methodCode: t.code,
            amount: t.amount,
            currency: currency ?? config?.currency ?? 'USD',
            notes: t.reference,
            isPartial: false,
          ),
        )
        .toList();

    events.add(
      OrderEvent.record(
        orderLocalId: draft.localId,
        eventType: OrderEventTypes.paid,
        actorId: cashierId,
        payloadJson: jsonEncode({
          'payments': [
            for (final t in settlement.paymentsToPost)
              {'method': t.code, 'amount': t.amount},
          ],
        }),
      ),
    );

    await _repo.saveOrderBundle(
      order: paid,
      items: orderItems,
      events: events,
      payments: orderPayments,
    );
    await _enqueueSync(draft.localId);
    try {
      await syncOrderToEn1(draft.localId, config: config);
    } catch (_) {}
    return (await _repo.getByLocalId(draft.localId)) ?? paid;
  }

  Future<Order?> fetchRemote(String en1OrderId) async {
    final root = await _api.getOrder(en1OrderId, includeEvents: true);
    final remote = OrderMapper.unwrapOrder(root);
    if (remote == null) return null;
    final localId = 'en1_order_${remote['id']}';
    final existing = await _repo.getByLocalId(localId) ??
        await _findByServerId(remote['id']?.toString());
    final base =
        existing ?? OrderMapper.orderFromRemote(remote, localId: localId);
    final mapped = OrderMapper.applyRemoteOrder(base, remote);
    await _repo.putOrder(mapped);
    final items = remote['items'];
    if (items is List) {
      for (final raw in items) {
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw);
          await _repo.putItem(OrderMapper.itemFromRemote(m, mapped.localId));
        }
      }
    }
    await _closeLinkedOpenTicketsIfNeeded(mapped);
    return mapped;
  }

  /// Sincroniza un pedido pendiente con EN1 (idempotente vía event_id).
  Future<void> syncOrderToEn1(String orderLocalId,
      {BusinessConfig? config}) async {
    OrderSyncDiag.section('SYNC Pedido localId=$orderLocalId');
    final existing = await _repo.getByLocalId(orderLocalId);
    if (existing == null) {
      OrderSyncDiag.log('Pedido Local: NO ENCONTRADO — abort');
      return;
    }
    var order = existing;
    final items = await _repo.itemsOf(orderLocalId);
    final events = await _repo.eventsOf(orderLocalId);
    final payments = await _repo.paymentsOf(orderLocalId);
    OrderSyncDiag.jsonBlock('Pedido Local', {
      'localId': order.localId,
      'serverId': order.serverId,
      'localNumber': order.localNumber,
      'tableRef': order.tableRef,
      'cashierId': order.cashierId,
      'customerId': order.customerId,
      'lifecycleStatus': order.lifecycleStatus,
      'isOpen': order.isOpen,
      'syncStatus': order.syncStatus.name,
      'totals': {
        'subtotal': order.subtotal,
        'tax': order.taxAmount,
        'discount': order.discount,
        'tip': order.tipAmount,
        'total': order.total,
      },
      'items': items
          .map((i) => {
                'localId': i.localId,
                'lineRef': i.lineRef,
                'productRef': i.productRef,
                'qty': i.quantity,
                'unitPrice': i.unitPrice,
              })
          .toList(),
      'events_pending':
          events.where((e) => !e.syncedToEn1).map((e) => e.eventType).toList(),
      'payments_unsynced': payments.where((p) => !p.isSynced).length,
    });

    try {
      if (order.serverId == null || order.serverId!.isEmpty) {
        OrderSyncDiag.log('Paso: POST /orders (crear)');
        final createEvt = events
            .where((e) => e.eventType == OrderEventTypes.created)
            .firstOrNull;
        final eventId = createEvt?.localId ?? OrderMapper.newEventId();
        final root = await _api.createOrder(
          OrderMapper.toCreateRequest(order: order, eventId: eventId),
          config: config,
        );
        final remote = OrderMapper.unwrapOrder(root);
        if (remote == null) {
          throw En1OrdersException(
              code: 'validation', message: 'create sin order');
        }
        order = OrderMapper.applyRemoteOrder(order, remote);
        await _repo.putOrder(order);
        if (createEvt != null && !createEvt.syncedToEn1) {
          await _repo.putEvent(createEvt.copyWith(
              syncedToEn1: true, syncStatus: SyncStatus.synced));
        }
        OrderSyncDiag.log('Tras create: serverId=${order.serverId}');
      } else {
        OrderSyncDiag.log(
            'Pedido ya tiene serverId=${order.serverId} — skip create');
      }

      final en1Id = order.serverId!;
      for (final evt in events) {
        if (evt.syncedToEn1) continue;
        if (evt.eventType == OrderEventTypes.created) {
          await _repo.putEvent(
              evt.copyWith(syncedToEn1: true, syncStatus: SyncStatus.synced));
          continue;
        }
        if (evt.eventType == OrderEventTypes.paid) {
          await _repo.putEvent(
              evt.copyWith(syncedToEn1: true, syncStatus: SyncStatus.synced));
          continue;
        }
        OrderSyncDiag.log(
            'Paso: POST /orders/$en1Id/events type=${evt.eventType}');
        final root = await _api.postEvent(
          en1Id,
          OrderMapper.toEventRequest(evt),
          config: config,
        );
        final remote = OrderMapper.unwrapOrder(root);
        if (remote != null) {
          order = OrderMapper.applyRemoteOrder(order, remote);
          await _repo.putOrder(order);
        }
        await _repo.putEvent(
            evt.copyWith(syncedToEn1: true, syncStatus: SyncStatus.synced));
      }

      for (final pay in payments) {
        if (pay.isSynced) continue;
        OrderSyncDiag.log(
            'Paso: POST /orders/$en1Id/payments amount=${pay.amount}');
        final root = await _api.postPayment(
          en1Id,
          OrderMapper.toPaymentRequest(
            pay,
            cashierContactId:
                OrderMapper.contactIdFromCashierRef(order.cashierId),
          ),
          config: config,
        );
        final remote = OrderMapper.unwrapOrder(root);
        if (remote != null) {
          order = OrderMapper.applyRemoteOrder(order, remote);
          await _repo.putOrder(order);
        }
        await _repo.putPayment(pay.markAsSynced(pay.localId));
      }

      try {
        OrderSyncDiag.log('Paso: GET /orders/$en1Id (confirmación)');
        final root =
            await _api.getOrder(en1Id, includeEvents: true, config: config);
        final remote = OrderMapper.unwrapOrder(root);
        if (remote != null) {
          order = OrderMapper.applyRemoteOrder(order, remote);
          await ingestRemoteEventsFromOrderJson(order: order, remote: remote);
          order = (await _repo.getByLocalId(order.localId)) ?? order;
        }
      } catch (e) {
        OrderSyncDiag.log('GET confirmación falló (no aborta): $e');
      }
      // Sync OK → dirty = false
      final finalized = order.copyWith(
        dirty: false,
        syncStatus: SyncStatus.synced,
        updatedAt: En1DateTimeService.nowUtc(),
      );
      await _repo.putOrder(finalized);
      await _closeLinkedOpenTicketsIfNeeded(finalized);
      OrderSyncDiag.log(
          'Estado Sync pedido: OK serverId=${order.serverId} dirty=false');
    } catch (e) {
      OrderSyncDiag.log('Estado Sync pedido: FALLÓ → $e');
      try {
        await _repo.putOrder(
          order.copyWith(
              dirty: true,
              syncStatus: SyncStatus.error,
              updatedAt: En1DateTimeService.nowUtc()),
        );
      } catch (_) {}
      rethrow;
    }
  }

  /// Si EN1 marcó el pedido cobrado/cerrado, saca Juanito/Pedrito de abiertos.
  Future<void> _closeLinkedOpenTicketsIfNeeded(Order order) async {
    if (order.isOpen || _openTickets == null) return;
    final n = await _openTickets!.closeTicketsForClosedOrder(order.localId);
    if (n > 0) {
      OrderSyncDiag.log(
        'E2E C20: $n ticket(s) abiertos cerrados (pedido ${order.localId} '
        'status=${order.lifecycleStatus} isOpen=false)',
      );
    }
  }

  /// Ingesta eventos administrativos EN1 (cancel/reopen/refund) sin duplicar.
  Future<void> ingestRemoteEventsFromOrderJson({
    required Order order,
    required Map<String, dynamic> remote,
  }) async {
    final raw = remote['events'];
    if (raw is! List || raw.isEmpty) return;

    final existing = await _repo.eventsOf(order.localId);
    final known = <String>{
      for (final e in existing) e.localId,
      for (final e in existing)
        if (e.serverId != null && e.serverId!.isNotEmpty) e.serverId!,
    };

    var latest = order;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final eventId =
          map['event_id']?.toString() ?? map['id']?.toString() ?? '';
      if (eventId.isEmpty || known.contains(eventId)) continue;

      final type =
          map['type']?.toString() ?? map['event_type']?.toString() ?? '';
      if (type.isEmpty) continue;

      final payload = <String, dynamic>{
        'origin': OrderEventOriginCode.en1,
      };
      final p = map['payload'];
      if (p is Map) payload.addAll(Map<String, dynamic>.from(p));
      if (map['reason'] != null) payload['reason'] = map['reason'];

      final evt = OrderEvent.record(
        orderLocalId: order.localId,
        eventType: type,
        eventId: eventId,
        actorId: map['actor_user_ref']?.toString() ??
            map['cashier_contact_id']?.toString(),
        payloadJson: jsonEncode(payload),
      ).markAsSynced(eventId);
      await _repo.putEvent(evt);
      known.add(eventId);

      if (type == OrderEventTypes.voided) {
        latest = latest.copyWith(
          isOpen: false,
          lifecycleStatus: OrderLifecycle.cancelled,
          updatedAt: En1DateTimeService.nowUtc(),
        );
        await _repo.putOrder(latest);
      } else if (type == OrderEventTypes.returned) {
        latest = latest.copyWith(
          isOpen: false,
          lifecycleStatus: OrderLifecycle.refunded,
          updatedAt: En1DateTimeService.nowUtc(),
        );
        await _repo.putOrder(latest);
      }
    }
  }

  /// Pull estado EN1 de pedidos ligados a tickets abiertos (cobro en BO).
  Future<int> reconcileOpenTicketsFromEn1({BusinessConfig? config}) async {
    final ticketsRepo = _openTickets;
    if (ticketsRepo == null) return 0;
    final openTickets = await ticketsRepo.getAllOpenTickets();
    var closed = 0;
    for (final ticket in openTickets) {
      final orderLocalId = ticket.linkedOrderLocalId;
      if (orderLocalId == null || orderLocalId.isEmpty) continue;
      final order = await _repo.getByLocalId(orderLocalId);
      final serverId = order?.serverId;
      if (order == null || serverId == null || serverId.isEmpty) continue;
      try {
        final root = await _api.getOrder(
          serverId,
          includeEvents: true,
          config: config,
        );
        final remote = OrderMapper.unwrapOrder(root);
        if (remote == null) continue;
        final mapped = OrderMapper.applyRemoteOrder(order, remote);
        await _repo.putOrder(mapped);
        await ingestRemoteEventsFromOrderJson(order: mapped, remote: remote);
        final refreshed = (await _repo.getByLocalId(orderLocalId)) ?? mapped;
        if (!refreshed.isOpen) {
          await ticketsRepo.markTicketCancelled(ticket.localId);
          closed++;
          OrderSyncDiag.log(
            'E2E C20 reconcile: ticket "${ticket.label}" cerrado '
            '(EN1 paid/financially_closed/closed)',
          );
        }
      } catch (e) {
        OrderSyncDiag.log(
          'Reconcile ticket "${ticket.label}" falló: $e',
        );
      }
    }
    return closed;
  }

  /// Vacía cola de pedidos pendientes.
  Future<void> flushPendingToEn1({BusinessConfig? config}) async {
    OrderSyncDiag.section('FLUSH COLA — botón Sincronizar');
    final pendingOps = await _sync.getRecent(limit: 100);
    final orderOps = pendingOps
        .where(
          (op) =>
              op.entityKind == SyncEntityKind.order &&
              op.entityLocalId != null &&
              (op.operationStatus == SyncOperationStatus.pending ||
                  op.operationStatus == SyncOperationStatus.failed),
        )
        .toList();
    OrderSyncDiag.log('Estado Cola SyncOperation(order): ${orderOps.length}');
    for (final op in orderOps) {
      OrderSyncDiag.log(
        '  op localId=${op.localId} entity=${op.entityLocalId} '
        'status=${op.operationStatus.name} attempts=${op.attemptCount} '
        'err=${op.errorMessage ?? "-"}',
      );
    }

    final orderIds = <String>{};
    for (final op in orderOps) {
      orderIds.add(op.entityLocalId!);
    }
    for (final o in await _repo.listRecent(limit: 100)) {
      final evts = await _repo.eventsOf(o.localId);
      if (evts.any((e) => !e.syncedToEn1)) orderIds.add(o.localId);
      final pays = await _repo.paymentsOf(o.localId);
      if (pays.any((p) => !p.isSynced)) orderIds.add(o.localId);
      if ((o.serverId == null || o.serverId!.isEmpty) && o.isPendingSync) {
        orderIds.add(o.localId);
      }
    }
    OrderSyncDiag.log('Pedidos a sincronizar: ${orderIds.length} → $orderIds');

    if (orderIds.isEmpty) {
      OrderSyncDiag.log('Nada que sincronizar (cola vacía).');
      return;
    }

    for (final dirty in await _repo.listDirty(limit: 100)) {
      orderIds.add(dirty.localId);
    }
    OrderSyncDiag.log('Pedidos dirty: ${(await _repo.countDirty())}');

    for (final id in orderIds) {
      try {
        await syncOrderToEn1(id, config: config);
      } catch (e) {
        OrderSyncDiag.log('Continúa flush tras error en $id: $e');
      }
    }
    final closedTickets = await reconcileOpenTicketsFromEn1(config: config);
    OrderSyncDiag.log(
      'FLUSH COLA — fin · tickets cerrados por EN1: $closedTickets',
    );
  }

  /// ¿Hay algo que justifique auto-sync?
  /// Incluye pedidos dirty y cola Sync (orders + cashRegister / turnos).
  Future<bool> hasPendingWork() async {
    if (await _repo.countDirty() > 0) return true;
    final pendingOps = await _sync.getRecent(limit: 50);
    return pendingOps.any(
      (op) =>
          (op.entityKind == SyncEntityKind.order ||
              op.entityKind == SyncEntityKind.cashRegister) &&
          (op.operationStatus == SyncOperationStatus.pending ||
              op.operationStatus == SyncOperationStatus.processing),
    );
  }

  void _appendLineItemsAndEvents({
    required String orderLocalId,
    required List<PosOrderLineInput> lines,
    required double taxAmount,
    required String? cashierId,
    required List<OrderItem> orderItems,
    required List<OrderEvent> events,
  }) {
    final lineBaseSum = lines.fold<double>(
      0,
      (s, l) =>
          s +
          ((l.unitPrice * l.quantity) - l.discount).clamp(0, double.infinity),
    );
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineRef = 'L${i + 1}';
      final lineBase = ((line.unitPrice * line.quantity) - line.discount)
          .clamp(0, double.infinity);
      final lineTax =
          lineBaseSum > 0 ? taxAmount * (lineBase / lineBaseSum) : 0.0;
      final productRef = line.productRef ?? line.productLocalId;
      orderItems.add(
        OrderItem.create(
          orderLocalId: orderLocalId,
          lineRef: lineRef,
          productLocalId: line.productLocalId,
          productRef: productRef,
          productName: line.productName,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          taxAmount: lineTax,
          discount: line.discount,
          notes: line.notes,
        ),
      );
      events.add(
        OrderEvent.record(
          orderLocalId: orderLocalId,
          eventType: OrderEventTypes.productAdded,
          actorId: cashierId,
          payloadJson: jsonEncode({
            'line_ref': lineRef,
            'product_ref': productRef,
            'qty': line.quantity,
            'unit_price': line.unitPrice,
            'tax': lineTax,
            'discount': line.discount,
            'notes': line.notes,
          }),
        ),
      );
    }
  }

  Future<Order> _replaceOpenOrderLines({
    required Order order,
    required List<PosOrderLineInput> lines,
    required double subtotal,
    required double taxAmount,
    required double discount,
    required double total,
    required String localNumber,
    String? customerId,
    String? cashierId,
    String? tableRef,
    String? notes,
    BusinessConfig? config,
    bool syncNow = true,
  }) async {
    final oldItems = await _repo.itemsOf(order.localId);
    final events = <OrderEvent>[];

    // Pedido ya en EN1: emitir eliminaciones + altas (contrato eventos).
    if (order.serverId != null && order.serverId!.isNotEmpty) {
      for (final old in oldItems) {
        events.add(
          OrderEvent.record(
            orderLocalId: order.localId,
            eventType: OrderEventTypes.productRemoved,
            actorId: cashierId,
            payloadJson: jsonEncode({'line_ref': old.lineRef}),
          ),
        );
      }
    }

    final orderItems = <OrderItem>[];
    _appendLineItemsAndEvents(
      orderLocalId: order.localId,
      lines: lines,
      taxAmount: taxAmount,
      cashierId: cashierId,
      orderItems: orderItems,
      events: events,
    );

    events.add(
      OrderEvent.record(
        orderLocalId: order.localId,
        eventType: OrderEventTypes.updated,
        actorId: cashierId,
        payloadJson: jsonEncode({
          'local_number': localNumber,
          'notes': notes,
          'table_ref': tableRef,
        }),
      ),
    );

    // created_by se congela en el primer save. El actor de update va en eventos.
    final createdBy = (order.cashierId != null && order.cashierId!.trim().isNotEmpty)
        ? order.cashierId
        : cashierId;

    final updated = order
        .copyWith(
          localNumber: localNumber,
          customerId: customerId,
          cashierId: createdBy,
          tableRef: tableRef,
          notes: notes,
          subtotal: subtotal,
          taxAmount: taxAmount,
          discount: discount,
          total: total,
          dirty: true,
        )
        .markAsModified();

    await _repo.saveOrderBundle(order: updated, events: events);
    // Reemplazar líneas locales
    for (final old in oldItems) {
      await _repo.putItem(old.markAsDeleted());
    }
    for (final item in orderItems) {
      await _repo.putItem(item);
    }

    await _enqueueSync(order.localId);
    if (syncNow) {
      try {
        await syncOrderToEn1(order.localId, config: config);
      } catch (_) {}
    }
    return (await _repo.getByLocalId(order.localId)) ?? updated;
  }

  Future<String> _nextLineRef(String orderLocalId) async {
    final items = await _repo.itemsOf(orderLocalId);
    return 'L${items.length + 1}';
  }

  Future<Order?> _findByServerId(String? serverId) async {
    if (serverId == null) return null;
    for (final o in await _repo.listRecent(limit: 200)) {
      if (o.serverId == serverId) return o;
    }
    return null;
  }

  Future<Order> _requireOpen(String orderLocalId) async {
    final order = await _repo.getByLocalId(orderLocalId);
    if (order == null) throw StateError('Pedido no encontrado: $orderLocalId');
    if (!order.isOpen) throw StateError('Pedido cerrado: $orderLocalId');
    return order;
  }

  Future<void> _enqueueSync(String orderLocalId) async {
    await _sync.enqueuePush(SyncEntityKind.order, orderLocalId);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
