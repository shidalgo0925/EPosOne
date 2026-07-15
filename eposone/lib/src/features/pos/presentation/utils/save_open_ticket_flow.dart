import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/widgets/blocking_progress_overlay.dart';
import 'package:eposone/src/features/orders/data/order_service.dart';
import 'package:eposone/src/features/orders/presentation/providers/order_providers.dart';
import 'package:eposone/src/features/pos/data/repositories/open_ticket_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sync/presentation/providers/en1_connection_status.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';

/// Flujo Hito 3B.1: Guardar Pedido → Progress → local → sync → cerrar tickets → Snackbar.
Future<void> saveOpenTicketFlow(BuildContext context, WidgetRef ref) async {
  final config = ref.read(businessConfigProvider);
  final cart = ref.read(cartProvider);

  if (cart.items.isEmpty) {
    throw StateError('El pedido está vacío');
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

  // Capturar líneas antes de limpiar carrito.
  final cartSnapshot = ref.read(cartProvider);
  final openTicketIdBefore = cartSnapshot.openTicketId;
  String? priorLinkedOrder;
  if (openTicketIdBefore != null) {
    priorLinkedOrder =
        (await ref.read(openTicketRepositoryProvider).getById(openTicketIdBefore))
            ?.linkedOrderLocalId;
  }

  final taxRate = config?.taxRate ?? 0;
  final taxIncluded = config?.taxIncluded ?? false;
  final totals = calculateSaleTotals(
    cartSnapshot,
    taxRate: taxRate,
    taxIncluded: taxIncluded,
  );

  try {
    if (!context.mounted) return;
    await BlockingProgressOverlay.run(
      context: context,
      message: 'Guardando pedido…',
      showCompletedFlash: false,
      action: () async {
        final ticket = await ref.read(openTicketActionsProvider).saveCurrentCart(params);

        if (config?.isEn1SyncReady == true) {
          String en1ProductRef(String localId, String? serverId) {
            if (serverId != null && serverId.trim().isNotEmpty) return serverId.trim();
            if (localId.startsWith('en1_')) return localId.substring(4);
            return localId;
          }

          final lines = cartSnapshot.items
              .map(
                (item) => PosOrderLineInput(
                  productLocalId: item.product.localId,
                  productRef: en1ProductRef(item.product.localId, item.product.serverId),
                  productName: item.displayName,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  discount: item.discount,
                  notes: item.modifiersJson.isEmpty ? null : item.modifiersJson,
                ),
              )
              .toList();

          final order = await ref.read(orderServiceProvider).upsertOpenOrderFromPosCart(
                localNumber: params.label ?? ticket.label ?? ticket.localId,
                lines: lines,
                subtotal: totals.subtotal,
                taxAmount: totals.taxAmount,
                discount: totals.discount,
                total: totals.total,
                existingOrderLocalId: priorLinkedOrder ?? ticket.linkedOrderLocalId,
                config: config,
                customerId: cartSnapshot.customerId,
                tableRef: params.label ?? ticket.label,
                notes: params.comment ?? ticket.comment,
                syncNow: true,
              );

          await ref.read(openTicketRepositoryProvider).linkOrder(
                ticketId: ticket.localId,
                orderLocalId: order.localId,
              );

          ref.invalidate(syncPendingCountProvider);
          ref.invalidate(syncOperationsProvider);
          ref.invalidate(localOrdersProvider);
          ref.invalidate(en1StatusSnapshotProvider);
          ref.invalidate(openTicketsListProvider);
        }
      },
    );
  } catch (e) {
    // No cerrar tickets; mostrar error.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700),
      );
    }
    rethrow;
  }

  if (!context.mounted) return;

  // Cerrar hoja de tickets si sigue abierta → volver al POS.
  await Navigator.of(context).maybePop();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('✓ Pedido guardado correctamente')),
  );
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
    builder: (ctx) {
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Guardar pedido'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              // Teclado tablet 10" landscape: el campo Nombre queda usable.
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del pedido / mesa',
                      hintText: 'Cliente Juan, Mesa 3…',
                      helperText: 'Nombre local del ticket (no cambia el POS).',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentCtrl,
                    textInputAction: TextInputAction.done,
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
            ),
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
      );
    },
  );
}
