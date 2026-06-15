import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/customers/presentation/providers/customer_provider.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';
import 'package:eposone/src/features/pos/presentation/utils/cart_guard.dart';
import 'package:eposone/src/features/pos/presentation/widgets/open_ticket_bill_preview.dart';

Future<void> showOpenTicketsSheet(BuildContext context, WidgetRef ref) async {
  ref.invalidate(openTicketsListProvider);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => const OpenTicketsSheet(),
  );
}

class OpenTicketsSheet extends ConsumerWidget {
  const OpenTicketsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(openTicketsListProvider);
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: EposBrand.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Tickets abiertos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EposBrand.navy)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: ticketsAsync.when(
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const Center(child: Text('No hay tickets guardados'));
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _OpenTicketCard(
                    ticket: tickets[i],
                    allTickets: tickets,
                    symbol: symbol,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenTicketCard extends ConsumerWidget {
  final OpenTicket ticket;
  final List<OpenTicket> allTickets;
  final String symbol;

  const _OpenTicketCard({
    required this.ticket,
    required this.allTickets,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(openTicketDetailProvider(ticket.localId));
    final dateFmt = DateFormat('dd/MM HH:mm');
    final config = ref.watch(businessConfigProvider);

    return Card(
      child: detailAsync.when(
        data: (detail) {
          if (detail == null) return const SizedBox.shrink();
          final lineCount = detail.lines.length;
          final customerAsync = ticket.customerId != null
              ? ref.watch(customerByIdProvider(ticket.customerId!))
              : const AsyncValue.data(null);

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.label ?? 'Ticket ${ticket.localId.substring(ticket.localId.length - 4)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            '${dateFmt.format(ticket.savedAt)} · ${orderTypeLabel(ticket.orderType)}',
                            style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$symbol${detail.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EposBrand.orange),
                    ),
                  ],
                ),
                if (ticket.comment != null && ticket.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(ticket.comment!, style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary)),
                ],
                const SizedBox(height: 6),
                Text(
                  '$lineCount ${lineCount == 1 ? 'producto' : 'productos'}'
                  '${customerAsync.valueOrNull?.name != null ? ' · ${customerAsync.value!.name}' : ''}',
                  style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(onPressed: () => _charge(context, ref), child: const Text('Cobrar')),
                    OutlinedButton(onPressed: () => _open(context, ref), child: const Text('Abrir')),
                    OutlinedButton(onPressed: () => _edit(context, ref), child: const Text('Editar')),
                    if (lineCount > 0)
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/tickets/${ticket.localId}/split');
                        },
                        child: const Text('Dividir'),
                      ),
                    if (config?.usePredefinedTickets == true)
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/tickets/pick/move/${ticket.localId}');
                        },
                        child: const Text('Mover'),
                      ),
                    if (allTickets.length > 1)
                      OutlinedButton(
                        onPressed: () => _merge(context, ref),
                        child: const Text('Fusionar'),
                      ),
                    OutlinedButton(
                      onPressed: () => showBillForOpenTicket(
                        context,
                        ticket: ticket,
                        lines: detail.lines,
                        config: config,
                      ),
                      child: const Text('Pre-cuenta'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _delete(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        error: (e, _) => Padding(padding: const EdgeInsets.all(12), child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (!await confirmDiscardCartIfNeeded(context, ref, openingTicketId: ticket.localId)) return;
    try {
      await ref.read(openTicketActionsProvider).restoreTicket(ticket.localId);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _charge(BuildContext context, WidgetRef ref) async {
    if (!await confirmDiscardCartIfNeeded(context, ref, openingTicketId: ticket.localId)) return;
    try {
      await ref.read(openTicketActionsProvider).restoreTicket(ticket.localId);
      if (context.mounted) {
        Navigator.pop(context);
        context.push('/payment');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _merge(BuildContext context, WidgetRef ref) async {
    final others = allTickets.where((t) => t.localId != ticket.localId).toList();
    final destId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Fusionar en ticket'),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        children: [
          const Text('Todo el contenido se moverá al ticket destino.'),
          const SizedBox(height: 12),
          for (final t in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t.localId),
              child: Text(t.label ?? 'Ticket ${t.localId.substring(t.localId.length - 4)}'),
            ),
        ],
      ),
    );

    if (destId == null || !context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar fusión'),
        content: const Text('¿Fusionar este ticket en el destino? El ticket origen se eliminará.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Fusionar')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(openTicketActionsProvider).mergeInto(fromTicketId: ticket.localId, toTicketId: destId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tickets fusionados')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final labelCtrl = TextEditingController(text: ticket.label ?? '');
    final commentCtrl = TextEditingController(text: ticket.comment ?? '');
    var orderType = ticket.orderType;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Editar ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 12),
              TextField(controller: commentCtrl, decoration: const InputDecoration(labelText: 'Comentario')),
              const SizedBox(height: 12),
              DropdownButtonFormField<OrderType>(
                initialValue: orderType,
                decoration: const InputDecoration(labelText: 'Tipo de orden'),
                items: OrderType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(orderTypeLabel(t))))
                    .toList(),
                onChanged: (v) => setState(() => orderType = v ?? OrderType.generic),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (ok == true) {
      await ref.read(openTicketActionsProvider).updateTicketMeta(
            ticketId: ticket.localId,
            label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
            comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
            orderType: orderType,
          );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ticket'),
        content: const Text('¿Eliminar este ticket guardado?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(openTicketActionsProvider).deleteTicket(ticket.localId);
    }
  }
}
