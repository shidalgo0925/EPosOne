import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket_line.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';

/// Dividir ticket abierto — mover líneas seleccionadas a otro ticket.
class SplitOpenTicketScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const SplitOpenTicketScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SplitOpenTicketScreen> createState() => _SplitOpenTicketScreenState();
}

class _SplitOpenTicketScreenState extends ConsumerState<SplitOpenTicketScreen> {
  final _selectedLineIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(openTicketDetailProvider(widget.ticketId));
    final symbol = ref.watch(businessConfigProvider)?.currencySymbol ?? 'B/.';

    return Scaffold(
      appBar: AppBar(title: const Text('Dividir ticket')),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) return const Center(child: Text('Ticket no encontrado'));
          final ticket = detail.ticket;
          final lines = detail.lines;

          if (lines.isEmpty) {
            return const Center(child: Text('Ticket sin productos'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.label ?? 'Ticket',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EposBrand.navy),
                    ),
                    const SizedBox(height: 4),
                    const Text('Selecciona productos para mover a otro ticket', style: TextStyle(color: EposBrand.textSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lines.length,
                  itemBuilder: (_, i) => _LineTile(
                    line: lines[i],
                    symbol: symbol,
                    selected: _selectedLineIds.contains(lines[i].localId),
                    onChanged: (v) => setState(() {
                      if (v) {
                        _selectedLineIds.add(lines[i].localId);
                      } else {
                        _selectedLineIds.remove(lines[i].localId);
                      }
                    }),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _selectedLineIds.isEmpty
                          ? null
                          : () {
                              final tickets = ref.read(openTicketsListProvider).valueOrNull ?? [];
                              _pickDestination(context, tickets);
                            },
                      icon: const Icon(Icons.call_split),
                      label: const Text('Mover selección a…'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _selectedLineIds.length == lines.length
                          ? null
                          : () => _moveToNewTicket(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Mover a ticket nuevo'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _pickDestination(BuildContext context, List<OpenTicket> tickets) async {
    final others = tickets.where((t) => t.localId != widget.ticketId).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay otros tickets abiertos. Crea uno nuevo.')),
      );
      return;
    }

    final destId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Mover a ticket'),
        children: [
          for (final t in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t.localId),
              child: Text(t.label ?? 'Ticket ${t.localId.substring(t.localId.length - 4)}'),
            ),
        ],
      ),
    );

    if (destId == null || !mounted) return;
    await _moveLines(destId);
  }

  Future<void> _moveToNewTicket(BuildContext context) async {
    final params = await context.push<SaveOpenTicketParams>('/tickets/pick');
    if (params == null || !mounted) return;

    try {
      final newTicket = await ref.read(openTicketActionsProvider).createEmptyTicket(params);
      await _moveLines(newTicket.localId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _moveLines(String toTicketId) async {
    try {
      await ref.read(openTicketActionsProvider).moveLines(
            fromTicketId: widget.ticketId,
            toTicketId: toTicketId,
            lineIds: _selectedLineIds.toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Productos movidos')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _LineTile extends StatelessWidget {
  final OpenTicketLine line;
  final String symbol;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _LineTile({
    required this.line,
    required this.symbol,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) => onChanged(v ?? false),
        title: Text(line.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${line.quantity % 1 == 0 ? line.quantity.toStringAsFixed(0) : line.quantity.toStringAsFixed(1)} x $symbol${line.unitPrice.toStringAsFixed(2)}',
        ),
        secondary: Text(
          '$symbol${line.lineTotal.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: EposBrand.orange),
        ),
      ),
    );
  }
}
