import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/orders/data/order_sync_diag.dart';
import 'package:eposone/src/features/orders/presentation/providers/order_providers.dart';

/// Operación Pedido Hito 3B + diagnóstico Sync 3C.
class OrderOperationScreen extends ConsumerStatefulWidget {
  const OrderOperationScreen({super.key});

  @override
  ConsumerState<OrderOperationScreen> createState() => _OrderOperationScreenState();
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                    diag.isEmpty ? 'Sin actividad Sync aún. Pulsa ☁ o Nuevo pedido.' : diag,
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
                    return ListTile(
                      title: Text(o.localNumber ?? o.localId),
                      subtitle: Text(
                        '${o.lifecycleStatus} · ${o.total.toStringAsFixed(2)}'
                        '${o.serverId != null ? ' · EN1 #${o.serverId}' : ' · pendiente sync'}',
                      ),
                      trailing: Icon(
                        o.isOpen ? Icons.lock_open : Icons.lock,
                        color: o.isOpen ? EposBrand.orange : Colors.green,
                      ),
                      onTap: _busy
                          ? null
                          : () async {
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
