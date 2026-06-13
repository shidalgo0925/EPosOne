import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/customers/presentation/providers/customer_provider.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';

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
      initialChildSize: 0.7,
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
                  itemBuilder: (_, i) => _OpenTicketCard(ticket: tickets[i], symbol: symbol),
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
  final String symbol;

  const _OpenTicketCard({required this.ticket, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(openTicketDetailProvider(ticket.localId));
    final dateFmt = DateFormat('dd/MM HH:mm');

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
                            dateFmt.format(ticket.savedAt),
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
                const SizedBox(height: 6),
                Text(
                  '$lineCount ${lineCount == 1 ? 'producto' : 'productos'}'
                  '${customerAsync.valueOrNull?.name != null ? ' · ${customerAsync.value!.name}' : ''}',
                  style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await ref.read(openTicketActionsProvider).restoreTicket(ticket.localId);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('Abrir'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
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
                      },
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
}
