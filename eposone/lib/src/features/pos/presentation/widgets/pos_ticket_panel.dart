import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/utils/save_open_ticket_flow.dart';
import 'package:eposone/src/features/pos/presentation/widgets/open_ticket_bill_preview.dart';
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

    final openTicketsOn = config?.openTicketsEnabled ?? true;

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
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 0),
              child: Row(
                children: [
                  const Text('Ticket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: EposBrand.navy)),
                  if (cart.openTicketId != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: EposBrand.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Guardado', style: TextStyle(fontSize: 9, color: EposBrand.orange, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const Spacer(),
                  if (cart.items.isNotEmpty)
                    Text('${cart.totalQuantity} uds', style: const TextStyle(fontSize: 11, color: EposBrand.textSecondary)),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onSelected: (action) async {
                      switch (action) {
                        case 'precuenta':
                          showBillForCart(context, cart, config);
                        case 'limpiar':
                          ref.read(cartProvider.notifier).clear();
                        case 'descuento':
                          await _showDiscountDialog(context, ref, cart.discountPercent);
                        case 'guardar':
                          await _saveTicket(context, ref);
                        case 'dividir':
                          if (context.mounted) context.push('/payment/split');
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (cart.items.isNotEmpty) ...[
                        const PopupMenuItem(value: 'precuenta', child: Text('Pre-cuenta')),
                        const PopupMenuItem(value: 'descuento', child: Text('Descuento ticket')),
                        if (openTicketsOn)
                          const PopupMenuItem(value: 'guardar', child: Text('Guardar ticket')),
                        if (cart.items.length > 1)
                          const PopupMenuItem(value: 'dividir', child: Text('Dividir ticket')),
                        const PopupMenuItem(value: 'limpiar', child: Text('Limpiar ticket')),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  const Expanded(child: CustomerPickerTile(compact: true)),
                  const SizedBox(width: 6),
                  Expanded(child: _OrderTypeSelector(orderType: cart.orderType, compact: true)),
                ],
              ),
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
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => _TicketLine(
                      item: cart.items[i],
                      symbol: symbol,
                      expanded: expanded,
                    ),
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(8, 6, 8, ViewInsets.bottom(context) + 6),
            decoration: BoxDecoration(
              color: EposBrand.background,
              border: Border(top: BorderSide(color: EposBrand.divider)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cart.items.isNotEmpty) ...[
                  _TotalRow(label: 'Subtotal', value: '$symbol${totals.subtotal.toStringAsFixed(2)}'),
                  if (cart.discountPercent != null && cart.discountPercent! > 0)
                    _TotalRow(
                      label: 'Desc. (${cart.discountPercent!.toStringAsFixed(0)}%)',
                      value: '-$symbol${totals.discount.toStringAsFixed(2)}',
                      valueColor: Colors.red.shade400,
                    )
                  else if (totals.discount > 0)
                    _TotalRow(label: 'Descuento', value: '-$symbol${totals.discount.toStringAsFixed(2)}', valueColor: Colors.red.shade400),
                  if (totals.taxAmount > 0)
                    _TotalRow(label: taxLabel, value: '$symbol${totals.taxAmount.toStringAsFixed(2)}'),
                  _TotalRow(
                    label: 'Total',
                    value: '$symbol${totals.total.toStringAsFixed(2)}',
                    bold: true,
                    valueColor: EposBrand.navy,
                  ),
                  const SizedBox(height: 8),
                ],
                if (expanded && openTicketsOn) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => showOpenTicketsSheet(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EposBrand.navy,
                        side: BorderSide(color: EposBrand.navy.withValues(alpha: 0.5)),
                      ),
                      child: const Text('TICKETS ABIERTOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                SizedBox(
                  width: double.infinity,
                  height: expanded ? 44 : 40,
                  child: FilledButton(
                    onPressed: cart.items.isEmpty ? null : () => context.push('/payment'),
                    style: FilledButton.styleFrom(
                      backgroundColor: EposBrand.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      cart.items.isEmpty
                          ? 'COBRAR'
                          : 'COBRAR  $symbol${totals.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: expanded ? 14 : 13,
                      ),
                    ),
                  ),
                ),
                if (!expanded && openTicketsOn && cart.items.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => _saveTicket(context, ref),
                      child: const Text('Guardar', style: TextStyle(fontSize: 12)),
                    ),
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
      await saveOpenTicketFlow(context, ref);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showDiscountDialog(BuildContext context, WidgetRef ref, double? current) async {
    final customCtrl = TextEditingController(text: current?.toStringAsFixed(0) ?? '');

    final result = await showDialog<_DiscountChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descuento en ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in [5.0, 10.0, 15.0, 20.0])
                  ActionChip(
                    label: Text('${p.toStringAsFixed(0)}%'),
                    onPressed: () => Navigator.pop(ctx, _DiscountChoice.percent(p)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Otro %',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, const _DiscountChoice.clear()),
              child: const Text('Quitar'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(customCtrl.text);
              if (v == null || v <= 0 || v > 100) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Indica un porcentaje entre 1 y 100')),
                );
                return;
              }
              Navigator.pop(ctx, _DiscountChoice.percent(v));
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final notifier = ref.read(cartProvider.notifier);
    if (result.clear) {
      notifier.clearGlobalDiscount();
    } else if (result.percent != null) {
      notifier.setGlobalDiscount(result.percent!);
    }
  }
}

class _DiscountChoice {
  final double? percent;
  final bool clear;
  const _DiscountChoice.percent(this.percent) : clear = false;
  const _DiscountChoice.clear() : percent = null, clear = true;
}

class _OrderTypeSelector extends ConsumerWidget {
  final OrderType orderType;
  final bool compact;

  const _OrderTypeSelector({required this.orderType, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        final selected = await showModalBottomSheet<OrderType>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Tipo de orden', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                for (final t in OrderType.values)
                  ListTile(
                    title: Text(orderTypeLabel(t)),
                    trailing: orderType == t ? const Icon(Icons.check, color: EposBrand.orange) : null,
                    onTap: () => Navigator.pop(ctx, t),
                  ),
              ],
            ),
          ),
        );
        if (selected != null) {
          ref.read(cartProvider.notifier).setOrderType(selected);
        }
      },
      borderRadius: BorderRadius.circular(compact ? 6 : 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 5 : 10),
        decoration: BoxDecoration(
          border: Border.all(color: EposBrand.divider),
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
        ),
        child: Row(
          children: [
            Icon(Icons.restaurant_menu, size: compact ? 15 : 18, color: EposBrand.textSecondary),
            SizedBox(width: compact ? 4 : 8),
            Expanded(
              child: Text(
                orderTypeLabel(orderType),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 11 : 13),
              ),
            ),
            Icon(Icons.expand_more, size: compact ? 16 : 18, color: EposBrand.textSecondary),
          ],
        ),
      ),
    );
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
      padding: EdgeInsets.symmetric(horizontal: expanded ? 6 : 8, vertical: expanded ? 5 : 8),
      decoration: BoxDecoration(
        color: EposBrand.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: EposBrand.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: expanded ? 2 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: expanded ? 12 : 13),
                ),
                if (!expanded) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$symbol${item.unitPrice.toStringAsFixed(2)} c/u',
                    style: const TextStyle(fontSize: 10, color: EposBrand.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (expanded) ...[
            _QtyControl(item: item, compact: true),
            const SizedBox(width: 4),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('x${item.quantity.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$symbol${item.total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: expanded ? 12 : 13, color: EposBrand.navy)),
              InkWell(
                onTap: () => ref.read(cartProvider.notifier).removeItem(item.id),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.close, size: expanded ? 14 : 16, color: Colors.red),
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
  final bool compact;

  const _QtyControl({required this.item, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = item.product.allowDecimalQty ? 0.5 : 1.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: EposBrand.divider),
        borderRadius: BorderRadius.circular(6),
        color: EposBrand.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(
            icon: Icons.remove,
            compact: compact,
            onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - step),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8),
            child: Text(
              item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(1),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 12 : 14),
            ),
          ),
          _QtyBtn(
            icon: Icons.add,
            compact: compact,
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
  final bool compact;

  const _QtyBtn({required this.icon, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(compact ? 4 : 6),
        child: Icon(icon, size: compact ? 14 : 16, color: EposBrand.navy),
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
      fontSize: bold ? 15 : 12,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: valueColor ?? EposBrand.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 14 : 12, color: bold ? EposBrand.navy : EposBrand.textSecondary)),
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
    final config = ref.watch(businessConfigProvider);
    if (config?.openTicketsEnabled == false) return const SizedBox.shrink();

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
