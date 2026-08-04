import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';
import 'package:eposone/src/features/orders/data/order_sync_diag.dart';
import 'package:eposone/src/features/orders/domain/entities/order.dart';
import 'package:eposone/src/features/orders/domain/entities/order_event.dart';
import 'package:eposone/src/features/orders/domain/order_event_audit.dart';
import 'package:eposone/src/features/orders/domain/order_lifecycle.dart';
import 'package:eposone/src/features/orders/presentation/providers/order_providers.dart';
import 'package:eposone/src/features/orders/presentation/widgets/multi_tender_payment_dialog.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';

/// Operación Pedido Hito 3B + diagnóstico Sync 3C.
class OrderOperationScreen extends ConsumerStatefulWidget {
  const OrderOperationScreen({super.key});

  @override
  ConsumerState<OrderOperationScreen> createState() =>
      _OrderOperationScreenState();
}

class _OrderOperationScreenState extends ConsumerState<OrderOperationScreen> {
  bool _busy = false;
  String? _status;
  bool _showDiag = true;

  Future<void> _newOrder() async {
    setState(() {
      _busy = true;
      _status = 'Creando pedido…';
    });
    try {
      final svc = ref.read(orderServiceProvider);
      final order = await svc.createOrder(
        localNumber: 'POS-${DateTime.now().millisecondsSinceEpoch % 100000}',
      );
      ref.invalidate(localOrdersProvider);
      setState(() => _status =
          'Pedido ${order.localNumber} · EN1=${order.serverId ?? "cola"} · ver log Sync abajo');
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _flush() async {
    setState(() {
      _busy = true;
      _status = 'Sincronizando… (detalle en log)';
      _showDiag = true;
    });
    try {
      await ref.read(orderServiceProvider).flushPendingToEn1();
      ref.invalidate(localOrdersProvider);
      final lastHttp = OrderSyncDiag.lines.reversed
          .where((l) => l.contains('Response Code:'))
          .take(3)
          .toList();
      setState(() {
        _status = lastHttp.isEmpty
            ? 'Sync fin — ver log (¿cola vacía? ¿llegó HTTP?)'
            : 'Sync fin · ${lastHttp.reversed.join(" | ")}';
      });
    } catch (e) {
      setState(() => _status = 'ERROR Sync: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _copyDiag() {
    Clipboard.setData(ClipboardData(text: OrderSyncDiag.asText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log Sync copiado — pegar a Teams / P1')),
    );
  }

  Future<void> _addPayment(Order order) async {
    if (!order.isOpen) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El pedido ya está cerrado')),
      );
      return;
    }

    final svc = ref.read(orderServiceProvider);
    final pays = await svc.paymentsOf(order.localId);
    final engine = ref.read(commercialEngineProvider);
    final paid = engine.sumPayments(pays.map((p) => p.amount));
    final balance = engine.outstandingBalance(total: order.total, paid: paid);
    if (balance <= 0.009) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin saldo pendiente')),
      );
      return;
    }

    if (!mounted) return;
    final symbol = ref.read(businessConfigProvider)?.currencySymbol ?? 'B/.';
    final label = order.localNumber ?? order.serverId ?? order.localId;
    final settlement = await showMultiTenderPaymentDialog(
      context: context,
      balanceDue: balance,
      orderTotal: order.total,
      alreadyPaid: paid,
      orderLabel: label,
      title: 'Cobrar Pedido',
      engine: engine,
      currencySymbol: symbol,
    );
    if (settlement == null || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'Registrando pagos…';
      _showDiag = true;
    });
    try {
      await svc.collectPayments(
        orderLocalId: order.localId,
        tenders: settlement.paymentsToPost,
        currency: ref.read(businessConfigProvider)?.currency ?? 'USD',
      );
      ref.invalidate(localOrdersProvider);
      ref.invalidate(syncPendingCountProvider);
      ref.invalidate(syncOperationsProvider);
      setState(() => _status =
          'Pagos OK · ${settlement.paymentsToPost.length} método(s) · sync en curso');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pago registrado'
              '${settlement.change > 0.009 ? ' · vuelto $symbol${settlement.change.toStringAsFixed(2)}' : ''}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _status = 'ERROR pago: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncOne(Order o) async {
    setState(() {
      _busy = true;
      _status = 'Sync pedido ${o.localId}…';
      _showDiag = true;
    });
    try {
      await ref.read(orderServiceProvider).syncOrderToEn1(o.localId);
      ref.invalidate(localOrdersProvider);
      setState(() => _status = 'OK — ver Response Code en log');
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _abortOrder(Order o) async {
    final action = OrderLifecycle.abortAction(o.lifecycleStatus);
    if (action == OrderAbortAction.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No hay acción disponible en estado ${OrderLifecycle.label(o.lifecycleStatus)}',
          ),
        ),
      );
      return;
    }

    final isVoid = action == OrderAbortAction.voidOrder;
    final isRefund = action == OrderAbortAction.refund;
    final title = isRefund
        ? 'Reembolsar pedido'
        : (isVoid ? 'Anular pedido' : 'Cancelar pedido');
    final confirmLabel = isRefund
        ? 'Reembolsar'
        : (isVoid ? 'Anular pedido' : 'Cancelar pedido');
    final hint = isRefund
        ? 'Motivo del reembolso'
        : (isVoid ? 'Motivo de anulación' : 'Motivo de cancelación');

    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(
            labelText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Volver')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok != true) {
      reasonCtrl.dispose();
      return;
    }
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (reason.isEmpty) return;

    setState(() {
      _busy = true;
      _status = isRefund
          ? 'Reembolsando…'
          : (isVoid ? 'Anulando…' : 'Cancelando…');
    });
    try {
      final svc = ref.read(orderServiceProvider);
      if (isRefund) {
        await svc.refundOrder(orderLocalId: o.localId, reason: reason);
      } else if (isVoid) {
        await svc.voidOrder(orderLocalId: o.localId, reason: reason);
      } else {
        await svc.cancelOrder(orderLocalId: o.localId, reason: reason);
      }
      ref.invalidate(localOrdersProvider);
      ref.invalidate(syncPendingCountProvider);
      setState(() {
        _status = isRefund
            ? 'Reembolsado · evento pedido.devuelto en cola/sync'
            : (isVoid
                ? 'Anulado · evento pedido.anulado en cola/sync'
                : 'Cancelado · evento pedido.anulado en cola/sync');
      });
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(localOrdersProvider);
    final diag = OrderSyncDiag.asText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos EN1'),
        actions: [
          IconButton(
            tooltip: 'Copiar log Sync',
            onPressed: diag.isEmpty ? null : _copyDiag,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: 'Sincronizar cola',
            onPressed: _busy ? null : _flush,
            icon: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_sync),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _newOrder,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo pedido'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_status != null)
            Material(
              color: EposBrand.orange.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_status!, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ExpansionTile(
            initiallyExpanded: _showDiag,
            onExpansionChanged: (v) => setState(() => _showDiag = v),
            title: const Text('Diagnóstico Sync (Hito 3C)'),
            subtitle: const Text('Pedido local · JSON · URL · HTTP · cola'),
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 220),
                color: Colors.black87,
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: Text(
                    diag.isEmpty
                        ? 'Sin actividad Sync aún. Pulsa ☁ o Nuevo pedido.'
                        : diag,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  OrderSyncDiag.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Limpiar log'),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sin pedidos.\nNuevo pedido → Sync ☁ → copiar log.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: EposBrand.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    final cancelled =
                        OrderLifecycle.isCancelledLike(o.lifecycleStatus);
                    final refunded = OrderLifecycle.normalize(o.lifecycleStatus) ==
                            OrderLifecycle.refunded ||
                        OrderLifecycle.normalize(o.lifecycleStatus) ==
                            OrderLifecycle.returned;
                    return FutureBuilder<List<OrderEvent>>(
                      future: ref
                          .read(orderServiceProvider)
                          .eventsOf(o.localId),
                      builder: (context, snap) {
                        final events = snap.data ?? const <OrderEvent>[];
                        OrderEvent? lastAdmin;
                        for (var j = events.length - 1; j >= 0; j--) {
                          final e = events[j];
                          if (e.eventType == OrderEventTypes.voided ||
                              e.eventType == OrderEventTypes.returned) {
                            lastAdmin = e;
                            break;
                          }
                        }
                        final reason = OrderEventAudit.reasonFromPayload(
                            lastAdmin?.payloadJson);
                        final by = OrderEventAudit.createdByFromPayload(
                                lastAdmin?.payloadJson) ??
                            lastAdmin?.actorId;
                        return ListTile(
                          tileColor: cancelled
                              ? Colors.red.withValues(alpha: 0.06)
                              : null,
                          title: Text(o.localNumber ?? o.localId),
                          subtitle: Text(
                            [
                              OrderLifecycle.label(o.lifecycleStatus),
                              o.total.toStringAsFixed(2),
                              if (o.serverId != null) 'EN1 #${o.serverId}',
                              if (o.serverId == null) 'pendiente sync',
                              if (reason != null) 'Motivo: $reason',
                              if (by != null) 'Por: $by',
                            ].join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (OrderLifecycle.abortAction(
                                      o.lifecycleStatus) !=
                                  OrderAbortAction.none)
                                IconButton(
                                  tooltip: switch (OrderLifecycle.abortAction(
                                      o.lifecycleStatus)) {
                                    OrderAbortAction.cancel =>
                                      'Cancelar pedido',
                                    OrderAbortAction.voidOrder =>
                                      'Anular pedido',
                                    OrderAbortAction.refund =>
                                      'Reembolsar pedido',
                                    OrderAbortAction.none => '',
                                  },
                                  onPressed:
                                      _busy ? null : () => _abortOrder(o),
                                  icon: Icon(
                                    switch (OrderLifecycle.abortAction(
                                        o.lifecycleStatus)) {
                                      OrderAbortAction.refund =>
                                        Icons.replay_circle_filled_outlined,
                                      OrderAbortAction.voidOrder =>
                                        Icons.block,
                                      _ => Icons.cancel_outlined,
                                    },
                                    color: Colors.red,
                                  ),
                                ),
                              if (o.isOpen)
                                IconButton(
                                  tooltip: 'Agregar pago',
                                  onPressed:
                                      _busy ? null : () => _addPayment(o),
                                  icon: const Icon(Icons.payments_outlined),
                                ),
                              Icon(
                                cancelled || refunded
                                    ? Icons.block
                                    : (o.isOpen
                                        ? Icons.lock_open
                                        : Icons.lock),
                                color: cancelled
                                    ? Colors.red
                                    : (o.isOpen
                                        ? EposBrand.orange
                                        : Colors.green),
                              ),
                            ],
                          ),
                          onTap: _busy ? null : () => _syncOne(o),
                          onLongPress: _busy || !o.isOpen
                              ? null
                              : () => _addPayment(o),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}
