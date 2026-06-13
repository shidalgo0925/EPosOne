import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/pos/presentation/widgets/customer_picker_tile.dart';
import 'package:eposone/src/features/pos/presentation/widgets/open_tickets_sheet.dart';

class PosTicketPanel extends ConsumerWidget {
  final bool expanded;

  const PosTicketPanel({
    super.key,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totals = ref.watch(saleTotalsProvider);
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';
    final taxLabel = config?.taxIncluded == true ? 'Imp. incl.' : 'ITBMS';

    return Container(
      decoration: BoxDecoration(
        color: EposBrand.surface,
        border: Border(
          left: expanded ? BorderSide(color: EposBrand.divider) : BorderSide.none,
          top: expanded ? BorderSide.none : BorderSide(color: EposBrand.divider),
        ),
        boxShadow: [
          if (!expanded)
            BoxShadow(color: EposBrand.navy.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  const Text('Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EposBrand.navy)),
                  if (cart.openTicketId != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: EposBrand.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Guardado', style: TextStyle(fontSize: 10, color: EposBrand.orange, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const Spacer(),
                  Text('${cart.totalQuantity} uds', style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: CustomerPickerTile(),
            ),
          ],
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Text(
                      expanded ? 'Agrega productos al ticket' : 'Ticket vacío',
                      style: const TextStyle(color: EposBrand.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _TicketLine(
                      item: cart.items[i],
                      symbol: symbol,
                      expanded: expanded,
                    ),
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, ViewInsets.bottom(context)),
            decoration: BoxDecoration(
              color: EposBrand.background,
              border: Border(top: BorderSide(color: EposBrand.divider)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  if (cart.items.isNotEmpty) ...[
                    _TotalRow(label: 'Subtotal', value: '$symbol${totals.subtotal.toStringAsFixed(2)}'),
                    if (totals.discount > 0)
                      _TotalRow(label: 'Descuento', value: '-$symbol${totals.discount.toStringAsFixed(2)}', valueColor: Colors.red.shade400),
                    if (totals.taxAmount > 0)
                      _TotalRow(label: taxLabel, value: '$symbol${totals.taxAmount.toStringAsFixed(2)}'),
                    _TotalRow(
                      label: 'Total',
                      value: '$symbol${totals.total.toStringAsFixed(2)}',
                      bold: true,
                      valueColor: EposBrand.navy,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      if (expanded)
                        OutlinedButton.icon(
                          onPressed: cart.items.isEmpty ? null : () => _saveTicket(context, ref),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Guardar'),
                        ),
                      if (expanded) const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: cart.items.isEmpty ? null : () => context.push('/payment'),
                          child: Text(
                            cart.items.isEmpty ? 'Cobrar' : 'Cobrar  $symbol${totals.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (expanded && cart.items.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clear();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Limpiar ticket'),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTicket(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(openTicketActionsProvider).saveCurrentCart();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket guardado')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _TicketLine extends ConsumerWidget {
  final CartItem item;
  final String symbol;
  final bool expanded;

  const _TicketLine({required this.item, required this.symbol, required this.expanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EposBrand.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EposBrand.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '$symbol${item.unitPrice.toStringAsFixed(2)} c/u',
                  style: const TextStyle(fontSize: 11, color: EposBrand.textSecondary),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            _QtyControl(item: item),
            const SizedBox(width: 8),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('x${item.quantity.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$symbol${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: EposBrand.navy)),
              InkWell(
                onTap: () => ref.read(cartProvider.notifier).removeItem(item.id),
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends ConsumerWidget {
  final CartItem item;

  const _QtyControl({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = item.product.allowDecimalQty ? 0.5 : 1.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: EposBrand.divider),
        borderRadius: BorderRadius.circular(8),
        color: EposBrand.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(
            icon: Icons.remove,
            onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - step),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          _QtyBtn(
            icon: Icons.add,
            onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + step),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: EposBrand.navy),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 18 : 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: valueColor ?? EposBrand.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 16 : 13, color: bold ? EposBrand.navy : EposBrand.textSecondary)),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Botón app bar con badge de tickets abiertos.
class OpenTicketsButton extends ConsumerWidget {
  const OpenTicketsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(openTicketsCountProvider);

    return countAsync.when(
      data: (count) => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Tickets abiertos',
            onPressed: () => showOpenTicketsSheet(context, ref),
          ),
          if (count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: EposBrand.orange, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      loading: () => IconButton(icon: const Icon(Icons.receipt_long_outlined), onPressed: null),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.receipt_long_outlined),
        onPressed: () => showOpenTicketsSheet(context, ref),
      ),
    );
  }
}
