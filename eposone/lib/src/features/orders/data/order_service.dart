import 'dart:convert';

import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/orders/data/en1_orders_api.dart';
import 'package:eposone/src/features/orders/data/order_mapper.dart';
import 'package:eposone/src/features/orders/data/order_repository.dart';
import 'package:eposone/src/features/orders/data/order_sync_diag.dart';
import 'package:eposone/src/features/orders/domain/entities/order.dart';
import 'package:eposone/src/features/orders/domain/entities/order_event.dart';
import 'package:eposone/src/features/orders/domain/entities/order_item.dart';
import 'package:eposone/src/features/orders/domain/entities/order_payment.dart';
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
    En1OrdersApi? en1Api,
  })  : _repo = repository,
        _sync = syncRepository,
        _api = en1Api ?? En1OrdersApi();

  final OrderRepository _repo;
  final SyncRepository _sync;
  final En1OrdersApi _api;

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
    final order = await _requireOpen(orderLocalId);
    final payment = OrderPayment.create(
      orderLocalId: orderLocalId,
      methodCode: methodCode,
      amount: amount,
      currency: currency ?? 'USD',
      notes: notes,
      isPartial: isPartial,
    );
    final updated = closeOrder && !isPartial
        ? order.copyWith(isOpen: false, lifecycleStatus: 'paid').markAsModified()
        : order.markAsModified();
    await _repo.saveOrderBundle(order: updated, payment: payment);
    await _enqueueSync(orderLocalId);
    try {
      await syncOrderToEn1(orderLocalId);
    } catch (_) {}
    return payment;
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
      branchRef: config?.en1BranchId,
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

  Future<Order> voidOrder({
    required String orderLocalId,
    required String reason,
    String? actorId,
    BusinessConfig? config,
    bool syncNow = true,
  }) async {
    final order = await _repo.getByLocalId(orderLocalId);
    if (order == null) throw StateError('Pedido no encontrado: $orderLocalId');
    await _repo.putEvent(
      OrderEvent.record(
        orderLocalId: orderLocalId,
        eventType: OrderEventTypes.voided,
        actorId: actorId,
        payloadJson: jsonEncode({'reason': reason}),
      ),
    );
    await _repo.putOrder(
      order
          .copyWith(isOpen: false, lifecycleStatus: 'voided')
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
  Future<Order> createPaidOrderFromPosSale({
    required String localNumber,
    required List<PosOrderLineInput> lines,
    required String methodCode,
    required double paymentAmount,
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
  }) async {
    if (lines.isEmpty) throw StateError('Pedido POS sin líneas');

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
        await collectPayment(
          orderLocalId: existingOrderLocalId,
          methodCode: methodCode,
          amount: paymentAmount,
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
      branchRef: config?.en1BranchId,
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
      (s, l) => s + ((l.unitPrice * l.quantity) - l.discount).clamp(0, double.infinity),
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineRef = 'L${i + 1}';
      final lineBase =
          ((line.unitPrice * line.quantity) - line.discount).clamp(0, double.infinity);
      final lineTax = lineBaseSum > 0 ? taxAmount * (lineBase / lineBaseSum) : 0.0;
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

    final payment = OrderPayment.create(
      orderLocalId: draft.localId,
      methodCode: methodCode,
      amount: paymentAmount,
      currency: currency ?? config?.currency ?? 'USD',
      isPartial: false,
    );

    events.add(
      OrderEvent.record(
        orderLocalId: draft.localId,
        eventType: OrderEventTypes.paid,
        actorId: cashierId,
        payloadJson: jsonEncode({
          'method': methodCode,
          'amount': paymentAmount,
        }),
      ),
    );

    await _repo.saveOrderBundle(
      order: paid,
      items: orderItems,
      events: events,
      payment: payment,
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
    final base = existing ?? OrderMapper.orderFromRemote(remote, localId: localId);
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
    return mapped;
  }

  /// Sincroniza un pedido pendiente con EN1 (idempotente vía event_id).
  Future<void> syncOrderToEn1(String orderLocalId, {BusinessConfig? config}) async {
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
      'events_pending': events.where((e) => !e.syncedToEn1).map((e) => e.eventType).toList(),
      'payments_unsynced': payments.where((p) => !p.isSynced).length,
    });

    try {
      if (order.serverId == null || order.serverId!.isEmpty) {
        OrderSyncDiag.log('Paso: POST /orders (crear)');
        final createEvt = events.where((e) => e.eventType == OrderEventTypes.created).firstOrNull;
        final eventId = createEvt?.localId ?? OrderMapper.newEventId();
        final root = await _api.createOrder(
          OrderMapper.toCreateRequest(order: order, eventId: eventId),
          config: config,
        );
        final remote = OrderMapper.unwrapOrder(root);
        if (remote == null) {
          throw En1OrdersException(code: 'validation', message: 'create sin order');
        }
        order = OrderMapper.applyRemoteOrder(order, remote);
        await _repo.putOrder(order);
        if (createEvt != null && !createEvt.syncedToEn1) {
          await _repo.putEvent(createEvt.copyWith(syncedToEn1: true, syncStatus: SyncStatus.synced));
        }
        OrderSyncDiag.log('Tras create: serverId=${order.serverId}');
      } else {
        OrderSyncDiag.log('Pedido ya tiene serverId=${order.serverId} — skip create');
      }

      final en1Id = order.serverId!;
      for (final evt in events) {
        if (evt.syncedToEn1) continue;
        if (evt.eventType == OrderEventTypes.created) {
          await _repo.putEvent(evt.copyWith(syncedToEn1: true, syncStatus: SyncStatus.synced));
          continue;
        }
        if (evt.eventType == OrderEventTypes.paid) {
          await _repo.putEvent(evt.copyWith(syncedToEn1: true, syncStatus: SyncStatus.synced));
          continue;
        }
        OrderSyncDiag.log('Paso: POST /orders/$en1Id/events type=${evt.eventType}');
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
        await _repo.putEvent(evt.copyWith(syncedToEn1: true, syncStatus: SyncStatus.synced));
      }

      for (final pay in payments) {
        if (pay.isSynced) continue;
        OrderSyncDiag.log('Paso: POST /orders/$en1Id/payments amount=${pay.amount}');
        final root = await _api.postPayment(
          en1Id,
          OrderMapper.toPaymentRequest(pay),
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
        final root = await _api.getOrder(en1Id, includeEvents: true, config: config);
        final remote = OrderMapper.unwrapOrder(root);
        if (remote != null) {
          order = OrderMapper.applyRemoteOrder(order, remote);
        }
      } catch (e) {
        OrderSyncDiag.log('GET confirmación falló (no aborta): $e');
      }
      // Sync OK → dirty = false
      await _repo.putOrder(
        order.copyWith(
          dirty: false,
          syncStatus: SyncStatus.synced,
          updatedAt: DateTime.now(),
        ),
      );
      OrderSyncDiag.log('Estado Sync pedido: OK serverId=${order.serverId} dirty=false');
    } catch (e) {
      OrderSyncDiag.log('Estado Sync pedido: FALLÓ → $e');
      try {
        await _repo.putOrder(
          order.copyWith(dirty: true, syncStatus: SyncStatus.error, updatedAt: DateTime.now()),
        );
      } catch (_) {}
      rethrow;
    }
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
    OrderSyncDiag.log('FLUSH COLA — fin');
  }

  /// ¿Hay algo que justifique auto-sync?
  Future<bool> hasPendingWork() async {
    if (await _repo.countDirty() > 0) return true;
    final pendingOps = await _sync.getRecent(limit: 50);
    return pendingOps.any(
      (op) =>
          op.entityKind == SyncEntityKind.order &&
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
      (s, l) => s + ((l.unitPrice * l.quantity) - l.discount).clamp(0, double.infinity),
    );
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineRef = 'L${i + 1}';
      final lineBase =
          ((line.unitPrice * line.quantity) - line.discount).clamp(0, double.infinity);
      final lineTax = lineBaseSum > 0 ? taxAmount * (lineBase / lineBaseSum) : 0.0;
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

    final updated = order.copyWith(
      localNumber: localNumber,
      customerId: customerId,
      cashierId: cashierId,
      tableRef: tableRef,
      notes: notes,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: discount,
      total: total,
      dirty: true,
    ).markAsModified();

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
