import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket_line.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

SaleTotals computeBillTotals({
  required List<OpenTicketLine> lines,
  double? discountPercent,
  required double taxRate,
  required bool taxIncluded,
}) {
  final subtotal = lines.fold<double>(0, (s, l) => s + l.quantity * l.unitPrice);
  final lineDiscount = lines.fold<double>(0, (s, l) => s + l.discount);
  final globalDiscount = discountPercent != null ? subtotal * (discountPercent / 100) : 0;
  final discount = lineDiscount + globalDiscount;
  final taxable = (subtotal - discount).clamp(0, double.infinity);
  final taxAmount = taxIncluded ? 0.0 : taxable * (taxRate / 100);
  final total = taxable + taxAmount;
  return SaleTotals(subtotal: subtotal, discount: discount, taxAmount: taxAmount, total: total);
}

/// Pre-cuenta (bill) — documento informativo, no venta.
Future<void> showOpenTicketBillPreview({
  required BuildContext context,
  required BusinessConfig? config,
  required String symbol,
  String? ticketLabel,
  String? comment,
  OrderType orderType = OrderType.generic,
  required List<OpenTicketLine> lines,
  required SaleTotals totals,
}) async {
  final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  final businessName = config?.businessName ?? 'EPOSOne';

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Pre-cuenta'),
      content: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: EposBrand.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CUENTA',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(businessName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (config?.address != null)
                Text(
                  config!.address!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                ),
              const Divider(height: 24),
              if (ticketLabel != null) Text(ticketLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(dateFmt.format(DateTime.now()), style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary)),
              if (orderType != OrderType.generic)
                Text(orderTypeLabel(orderType), style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary)),
              if (comment != null && comment.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(comment, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
              const Divider(height: 20),
              for (final line in lines) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${line.quantity % 1 == 0 ? line.quantity.toStringAsFixed(0) : line.quantity.toStringAsFixed(1)} x ${line.productName}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text('$symbol${line.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              const Divider(height: 20),
              _BillRow(label: 'Subtotal', value: '$symbol${totals.subtotal.toStringAsFixed(2)}'),
              if (totals.discount > 0)
                _BillRow(label: 'Descuento', value: '-$symbol${totals.discount.toStringAsFixed(2)}'),
              if (totals.taxAmount > 0)
                _BillRow(label: config?.taxName ?? 'ITBMS', value: '$symbol${totals.taxAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _BillRow(
                label: 'TOTAL ADEUDADO',
                value: '$symbol${totals.total.toStringAsFixed(2)}',
                bold: true,
              ),
              const SizedBox(height: 12),
              const Text(
                'Documento informativo — no es un recibo de venta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: EposBrand.textSecondary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Impresión: próximamente (L5)')),
            );
          },
          icon: const Icon(Icons.print_outlined),
          label: const Text('Imprimir'),
        ),
      ],
    ),
  );
}

Future<void> showBillForOpenTicket(
  BuildContext context, {
  required OpenTicket ticket,
  required List<OpenTicketLine> lines,
  required BusinessConfig? config,
}) {
  final symbol = config?.currencySymbol ?? 'B/.';
  final totals = computeBillTotals(
    lines: lines,
    discountPercent: ticket.discountPercent,
    taxRate: config?.taxRate ?? 0,
    taxIncluded: config?.taxIncluded ?? false,
  );

  return showOpenTicketBillPreview(
    context: context,
    config: config,
    symbol: symbol,
    ticketLabel: ticket.label,
    comment: ticket.comment,
    orderType: ticket.orderType,
    lines: lines,
    totals: totals,
  );
}

Future<void> showBillForCart(BuildContext context, CartState cart, BusinessConfig? config) {
  final symbol = config?.currencySymbol ?? 'B/.';
  final totals = calculateSaleTotals(
    cart,
    taxRate: config?.taxRate ?? 0,
    taxIncluded: config?.taxIncluded ?? false,
  );
  final lines = cart.items
      .map(
        (i) => OpenTicketLine.create(
          openTicketId: 'preview',
          productId: i.product.localId,
          productName: i.product.name,
          quantity: i.quantity,
          unitPrice: i.unitPrice,
          discount: i.discount,
        ),
      )
      .toList();

  return showOpenTicketBillPreview(
    context: context,
    config: config,
    symbol: symbol,
    orderType: cart.orderType,
    lines: lines,
    totals: totals,
  );
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _BillRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, fontSize: bold ? 18 : 14),
          ),
        ],
      ),
    );
  }
}
