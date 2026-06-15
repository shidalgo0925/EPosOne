import 'package:intl/intl.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Texto plano para impresora térmica ESC/POS (80mm).
class ReceiptTextBuilder {
  static List<String> buildSaleReceipt({
    required BusinessConfig? config,
    required Sale sale,
    required List<SaleItem> items,
    required String symbol,
  }) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final lines = <String>[
      _center(config?.businessName ?? 'EPOSOne'),
      if (config?.address != null) _center(config!.address!),
      if (config?.phone != null) _center(config!.phone!),
      if (config?.ruc != null) _center('RUC: ${config!.ruc}'),
      _line(),
      if (sale.receiptNumber != null) _center('Recibo ${sale.receiptNumber}'),
      _center(dateFmt.format(sale.saleDate)),
      if (sale.cashierName != null) 'Cajero: ${sale.cashierName}',
      _line(),
    ];

    for (final item in items) {
      final qty = item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(1);
      lines.add('$qty x ${item.productName}');
      lines.add('   $symbol${(item.quantity * item.unitPrice).toStringAsFixed(2)}');
    }

    lines.addAll([
      _line(),
      _row('Subtotal', '$symbol${sale.subtotal.toStringAsFixed(2)}'),
      if (sale.discount > 0) _row('Descuento', '-$symbol${sale.discount.toStringAsFixed(2)}'),
      if (sale.taxAmount > 0) _row(config?.taxName ?? 'ITBMS', '$symbol${sale.taxAmount.toStringAsFixed(2)}'),
      _row('TOTAL', '$symbol${sale.total.toStringAsFixed(2)}'),
      _row('Pago', paymentMethodLabel(sale.paymentMethod)),
      if (sale.change > 0) _row('Vuelto', '$symbol${sale.change.toStringAsFixed(2)}'),
      _line(),
      _center(config?.receiptFooter ?? 'Gracias por su compra'),
      '',
    ]);
    return lines;
  }

  static List<String> buildBillPreview({
    required BusinessConfig? config,
    required String symbol,
    String? ticketLabel,
    String? comment,
    required List<({String name, double qty, double lineTotal})> lines,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
  }) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final result = <String>[
      _center('CUENTA'),
      _center(config?.businessName ?? 'EPOSOne'),
      _center(dateFmt.format(DateTime.now())),
      if (ticketLabel != null) ticketLabel,
      if (comment != null && comment.isNotEmpty) comment,
      _line(),
    ];

    for (final line in lines) {
      final qty = line.qty % 1 == 0 ? line.qty.toStringAsFixed(0) : line.qty.toStringAsFixed(1);
      result.add('$qty x ${line.name}');
      result.add('   $symbol${line.lineTotal.toStringAsFixed(2)}');
    }

    result.addAll([
      _line(),
      _row('Subtotal', '$symbol${subtotal.toStringAsFixed(2)}'),
      if (discount > 0) _row('Descuento', '-$symbol${discount.toStringAsFixed(2)}'),
      if (tax > 0) _row(config?.taxName ?? 'ITBMS', '$symbol${tax.toStringAsFixed(2)}'),
      _row('TOTAL ADEUDADO', '$symbol${total.toStringAsFixed(2)}'),
      _line(),
      _center('Documento informativo'),
      '',
    ]);
    return result;
  }

  static String _center(String text) {
    const width = 32;
    if (text.length >= width) return text;
    final pad = ((width - text.length) / 2).floor();
    return '${' ' * pad}$text';
  }

  static String _row(String left, String right) {
    const width = 32;
    final space = width - left.length - right.length;
    if (space < 1) return '$left $right';
    return '$left${' ' * space}$right';
  }

  static String _line() => '-' * 32;
}
