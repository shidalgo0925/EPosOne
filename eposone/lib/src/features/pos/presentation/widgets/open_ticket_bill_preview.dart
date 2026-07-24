import 'package:flutter/material.dart';
import 'package:eposone/src/core/printing/receipt_document_service.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/core/widgets/business_logo_header.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket_line.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Pre-cuenta (bill) — documento informativo, no venta.
Future<void> showOpenTicketBillPreview({
  required BuildContext context,
  required BusinessConfig? config,
  required String symbol,
  String? ticketLabel,
  String? comment,
  OrderType orderType = OrderType.generic,
  required List<OpenTicketLine> lines,
  required CalculationResult result,
}) async {
  final dateStr = En1DateTimeService.formatLocal(En1DateTimeService.nowUtc());
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
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              BusinessLogoHeader(logoPath: config?.logoPath, maxHeight: 56),
              Text(businessName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (config?.address != null)
                Text(
                  config!.address!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: EposBrand.textSecondary),
                ),
              const Divider(height: 24),
              if (ticketLabel != null)
                Text(ticketLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 12, color: EposBrand.textSecondary)),
              if (orderType != OrderType.generic)
                Text(orderTypeLabel(orderType),
                    style: const TextStyle(
                        fontSize: 12, color: EposBrand.textSecondary)),
              if (comment != null && comment.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(comment,
                    style: const TextStyle(
                        fontSize: 12, fontStyle: FontStyle.italic)),
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
                    Text(
                        '$symbol${result.lineTotal(line.localId).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              const Divider(height: 20),
              _BillRow(
                  label: 'Subtotal',
                  value: '$symbol${result.subtotal.toStringAsFixed(2)}'),
              if (result.discount > 0)
                _BillRow(
                    label: 'Descuento',
                    value: '-$symbol${result.discount.toStringAsFixed(2)}'),
              if (result.exemptBase > 0.0001)
                _BillRow(
                    label: 'Exento',
                    value: '$symbol${result.exemptBase.toStringAsFixed(2)}'),
              for (final e in result.taxByRate.entries)
                _BillRow(
                    label:
                        '${config?.taxName ?? 'ITBMS'} ${e.key.toStringAsFixed(0)}%',
                    value: '$symbol${e.value.toStringAsFixed(2)}'),
              if (result.taxByRate.isEmpty && result.taxAmount > 0)
                _BillRow(
                    label: config?.taxName ?? 'ITBMS',
                    value: '$symbol${result.taxAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _BillRow(
                label: 'TOTAL ADEUDADO',
                value: '$symbol${result.total.toStringAsFixed(2)}',
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
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);
            await ReceiptDocumentService.printBillPreview(
              context: context,
              config: config,
              symbol: symbol,
              ticketLabel: ticketLabel,
              comment: comment,
              lines: lines
                  .map((l) => (
                        name: l.productName,
                        qty: l.quantity,
                        lineTotal: result.lineTotal(l.localId),
                      ))
                  .toList(),
              subtotal: result.subtotal,
              discount: result.discount,
              tax: result.taxAmount,
              total: result.total,
              taxByRate: result.taxByRate,
              exemptBase: result.exemptBase,
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
  required CommercialEngineFacade engine,
}) {
  final symbol = config?.currencySymbol ?? 'B/.';
  final result = engine.calculateTotals(
    CommercialOrderInput(
      lines: [
        for (final line in lines)
          CommercialLineInput(
            lineId: line.localId,
            productId: line.productId,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            lineDiscount: line.discount,
            fiscalCategoryCode: line.fiscalCategoryCode,
          ),
      ],
      documentDiscountPercent: ticket.discountPercent ?? 0,
    ),
  );

  return showOpenTicketBillPreview(
    context: context,
    config: config,
    symbol: symbol,
    ticketLabel: ticket.label,
    comment: ticket.comment,
    orderType: ticket.orderType,
    lines: lines,
    result: result,
  );
}

Future<void> showBillForCart(
  BuildContext context,
  CartState cart,
  BusinessConfig? config,
  CommercialEngineFacade engine,
) {
  final symbol = config?.currencySymbol ?? 'B/.';
  final result = engine.calculateTotals(commercialOrderFromCart(cart));
  final now = DateTime.now();
  final lines = cart.items
      .map(
        (i) => OpenTicketLine(
          localId: i.id,
          openTicketId: 'preview',
          productId: i.product.localId,
          productName: i.displayName,
          quantity: i.quantity,
          unitPrice: i.unitPrice,
          discount: i.discount,
          fiscalCategoryCode: i.product.fiscalCategoryCode,
          modifiersJson:
              i.modifiersJson.isEmpty ? null : i.modifiersJson,
          createdAt: now,
          updatedAt: now,
        ),
      )
      .toList();

  return showOpenTicketBillPreview(
    context: context,
    config: config,
    symbol: symbol,
    orderType: cart.orderType,
    lines: lines,
    result: result,
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
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                fontSize: bold ? 18 : 14),
          ),
        ],
      ),
    );
  }
}
