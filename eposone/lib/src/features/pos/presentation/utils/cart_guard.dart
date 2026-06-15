import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';

/// Confirma descarte si hay productos en el carrito activo distinto al ticket que se abre.
Future<bool> confirmDiscardCartIfNeeded(
  BuildContext context,
  WidgetRef ref, {
  String? openingTicketId,
}) async {
  final cart = ref.read(cartProvider);
  if (cart.items.isEmpty) return true;
  if (openingTicketId != null && cart.openTicketId == openingTicketId) return true;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Ticket sin guardar'),
      content: const Text(
        'Hay productos en el ticket actual que no se han guardado. '
        '¿Descartarlos y continuar?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );

  if (result == true) {
    ref.read(cartProvider.notifier).clear();
    return true;
  }
  return false;
}
