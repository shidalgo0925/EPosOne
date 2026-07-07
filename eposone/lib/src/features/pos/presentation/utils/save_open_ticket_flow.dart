import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/features/pos/data/repositories/open_ticket_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';
import 'package:eposone/src/features/pos/presentation/widgets/open_tickets_sheet.dart';

/// Flujo compartido Guardar → elegir ticket predefinido o personalizado.
Future<void> saveOpenTicketFlow(BuildContext context, WidgetRef ref) async {
  final config = ref.read(businessConfigProvider);
  final cart = ref.read(cartProvider);

  if (cart.items.isEmpty) {
    throw StateError('El ticket está vacío');
  }

  SaveOpenTicketParams params;

  if (cart.openTicketId != null) {
    final existing = await ref.read(openTicketRepositoryProvider).getById(cart.openTicketId!);
    if (existing != null) {
      params = SaveOpenTicketParams(
        label: existing.label,
        comment: existing.comment,
        predefinedSlotId: existing.predefinedSlotId,
        orderType: cart.orderType,
      );
    } else {
      params = SaveOpenTicketParams(orderType: cart.orderType);
    }
  } else if (config?.usePredefinedTickets == true) {
    final picked = await context.push<SaveOpenTicketParams>('/tickets/pick');
    if (picked == null) return;
    params = SaveOpenTicketParams(
      label: picked.label,
      comment: picked.comment,
      predefinedSlotId: picked.predefinedSlotId,
      orderType: picked.orderType ?? cart.orderType,
    );
  } else {
    final picked = await _customTicketDialog(context, ref, cart.orderType);
    if (picked == null) return;
    params = picked;
  }

  await ref.read(openTicketActionsProvider).saveCurrentCart(params);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ticket guardado${params.label != null ? ': ${params.label}' : ''}'),
        action: SnackBarAction(
          label: 'Ver tickets',
          onPressed: () => showOpenTicketsSheet(context, ref),
        ),
      ),
    );
  }
}

Future<SaveOpenTicketParams?> _customTicketDialog(
  BuildContext context,
  WidgetRef ref,
  OrderType current,
) async {
  final labelCtrl = TextEditingController();
  final commentCtrl = TextEditingController();
  var orderType = current;

  return showDialog<SaveOpenTicketParams>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Guardar ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Cliente Juan, Pedido 001…'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(labelText: 'Comentario'),
            ),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                ctx,
                SaveOpenTicketParams(
                  label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
                  comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                  orderType: orderType,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}
