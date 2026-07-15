import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/orders/domain/entities/order.dart';
import 'package:eposone/src/features/orders/domain/entities/order_event.dart';
import 'package:eposone/src/features/orders/domain/entities/order_item.dart';
import 'package:eposone/src/features/orders/domain/entities/order_payment.dart';

/// Persistencia local del Pedido (Isar). Sin I/O HTTP.
class OrderRepository {
  OrderRepository(this._isar);

  final Isar _isar;

  Future<List<Order>> listOpen() async {
    final all = await _isar.orders.filter().isDeletedEqualTo(false).findAll();
    return all.where((o) => o.isOpen).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<Order>> listRecent({int limit = 50}) async {
    final all = await _isar.orders.filter().isDeletedEqualTo(false).findAll();
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all.take(limit).toList();
  }

  Future<List<Order>> listDirty({int limit = 100}) async {
    final all = await _isar.orders
        .filter()
        .isDeletedEqualTo(false)
        .dirtyEqualTo(true)
        .findAll();
    all.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return all.take(limit).toList();
  }

  Future<int> countDirty() async {
    return _isar.orders.filter().isDeletedEqualTo(false).dirtyEqualTo(true).count();
  }

  Future<Order?> getByLocalId(String localId) =>
      _isar.orders.filter().localIdEqualTo(localId).findFirst();

  Future<List<OrderItem>> itemsOf(String orderLocalId) async {
    final items = await _isar.orderItems
        .filter()
        .orderLocalIdEqualTo(orderLocalId)
        .isDeletedEqualTo(false)
        .findAll();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Future<List<OrderEvent>> eventsOf(String orderLocalId) async {
    final evts = await _isar.orderEvents
        .filter()
        .orderLocalIdEqualTo(orderLocalId)
        .isDeletedEqualTo(false)
        .findAll();
    evts.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return evts;
  }

  Future<List<OrderPayment>> paymentsOf(String orderLocalId) async {
    final pays = await _isar.orderPayments
        .filter()
        .orderLocalIdEqualTo(orderLocalId)
        .isDeletedEqualTo(false)
        .findAll();
    pays.sort((a, b) => a.paidAt.compareTo(b.paidAt));
    return pays;
  }

  Future<List<OrderEvent>> pendingEvents({int limit = 100}) async {
    final all = await _isar.orderEvents
        .filter()
        .syncedToEn1EqualTo(false)
        .isDeletedEqualTo(false)
        .findAll();
    all.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return all.take(limit).toList();
  }

  Future<void> putOrder(Order order) async {
    await _isar.writeTxn(() => _isar.orders.put(order));
  }

  Future<void> putItem(OrderItem item) async {
    await _isar.writeTxn(() => _isar.orderItems.put(item));
  }

  Future<void> putEvent(OrderEvent event) async {
    await _isar.writeTxn(() => _isar.orderEvents.put(event));
  }

  Future<void> putPayment(OrderPayment payment) async {
    await _isar.writeTxn(() => _isar.orderPayments.put(payment));
  }

  Future<void> saveOrderBundle({
    required Order order,
    List<OrderItem>? items,
    OrderEvent? event,
    List<OrderEvent>? events,
    OrderPayment? payment,
  }) async {
    await _isar.writeTxn(() async {
      await _isar.orders.put(order);
      if (items != null) {
        for (final i in items) {
          await _isar.orderItems.put(i);
        }
      }
      if (event != null) await _isar.orderEvents.put(event);
      if (events != null) {
        for (final e in events) {
          await _isar.orderEvents.put(e);
        }
      }
      if (payment != null) await _isar.orderPayments.put(payment);
    });
  }

  Future<void> recomputeTotals(String orderLocalId) async {
    final order = await getByLocalId(orderLocalId);
    if (order == null) return;
    final items = await itemsOf(orderLocalId);
    final subtotal = items.fold<double>(0, (s, i) => s + (i.unitPrice * i.quantity));
    final discount = items.fold<double>(0, (s, i) => s + i.discount);
    final tax = items.fold<double>(0, (s, i) => s + i.taxAmount);
    final total = subtotal - discount + tax + order.tipAmount;
    await putOrder(
      order.copyWith(
        subtotal: subtotal,
        discount: discount,
        taxAmount: tax,
        total: total,
        syncStatus: SyncStatus.modified,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
