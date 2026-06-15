import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/domain/entities/predefined_ticket.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';

/// Elige slot predefinido libre o ticket personalizado (guardar o mover).
class PickTicketScreen extends ConsumerWidget {
  final String? moveTicketId;

  const PickTicketScreen({super.key, this.moveTicketId});

  bool get isMoveMode => moveTicketId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(availablePredefinedSlotsProvider);
    final config = ref.watch(businessConfigProvider);
    final usePredefined = config?.usePredefinedTickets ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMoveMode ? 'Mover ticket' : 'Asignar ticket'),
      ),
      body: slotsAsync.when(
        data: (slots) {
          final grouped = _groupSlots(slots);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!usePredefined || slots.isEmpty)
                _CustomTicketTile(
                  title: isMoveMode ? 'Renombrar (personalizado)' : 'Ticket personalizado',
                  subtitle: 'Nombre libre',
                  onTap: () => _showCustomDialog(context, ref),
                ),
              if (usePredefined && slots.isNotEmpty) ...[
                const Text(
                  'Tickets disponibles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EposBrand.navy),
                ),
                const SizedBox(height: 12),
                for (final entry in grouped.entries) ...[
                  if (entry.key.isNotEmpty) ...[
                    Text(entry.key, style: const TextStyle(color: EposBrand.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in entry.value)
                        ActionChip(
                          label: Text(slot.name),
                          onPressed: () => _onSlotSelected(context, ref, slot),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                const SizedBox(height: 8),
                _CustomTicketTile(
                  title: 'Ticket personalizado',
                  subtitle: 'Nombre y comentario libres',
                  onTap: () => _showCustomDialog(context, ref),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Map<String, List<PredefinedTicket>> _groupSlots(List<PredefinedTicket> slots) {
    final map = <String, List<PredefinedTicket>>{};
    for (final s in slots) {
      final key = s.groupName ?? '';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  Future<void> _onSlotSelected(BuildContext context, WidgetRef ref, PredefinedTicket slot) async {
    if (isMoveMode) {
      try {
        await ref.read(openTicketActionsProvider).moveTicket(moveTicketId!, slot.localId, slot.name);
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ticket movido a ${slot.name}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red),
          );
        }
      }
      return;
    }

    context.pop(SaveOpenTicketParams(
      label: slot.name,
      predefinedSlotId: slot.localId,
    ));
  }

  Future<void> _showCustomDialog(BuildContext context, WidgetRef ref) async {
    final labelCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    OrderType orderType = ref.read(businessConfigProvider)?.defaultOrderType ?? OrderType.generic;

    final result = await showDialog<SaveOpenTicketParams>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isMoveMode ? 'Renombrar ticket' : 'Ticket personalizado'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(labelText: 'Comentario', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                if (!isMoveMode) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<OrderType>(
                    value: orderType,
                    decoration: const InputDecoration(labelText: 'Tipo de orden', border: OutlineInputBorder()),
                    items: OrderType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(orderTypeLabel(t))))
                        .toList(),
                    onChanged: (v) => setState(() => orderType = v ?? OrderType.generic),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (labelCtrl.text.trim().isEmpty) return;
                Navigator.pop(
                  ctx,
                  SaveOpenTicketParams(
                    label: labelCtrl.text.trim(),
                    comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                    orderType: orderType,
                  ),
                );
              },
              child: Text(isMoveMode ? 'Aplicar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !context.mounted) return;

    if (isMoveMode) {
      try {
        await ref.read(openTicketActionsProvider).updateTicketMeta(
              ticketId: moveTicketId!,
              label: result.label,
              comment: result.comment,
              orderType: result.orderType,
              clearPredefinedSlot: true,
            );
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red),
          );
        }
      }
      return;
    }

    context.pop(result);
  }
}

class _CustomTicketTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CustomTicketTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.edit_note, color: EposBrand.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
