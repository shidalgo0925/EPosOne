import 'package:eposone/src/core/printing/thermal_ops_text.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Recibo / precuenta — mismo ancho 48 que reportes (llena papel 80 mm).
class ReceiptTextBuilder {
  static List<String> buildSaleReceipt({
    required BusinessConfig? config,
    required Sale sale,
    required List<SaleItem> items,
    required String symbol,
    String? customerName,
    String? customerDocument,
  }) {
    final taxIncluded = config?.taxIncluded ?? false;
    final taxName = config?.taxName ?? 'ITBMS';
    final name = config?.businessName ?? 'EPOSOne';
    final factura = _facturaNumber(sale.receiptNumber);
    final pto = (config?.fiscalPointOfSale ?? '001').padLeft(3, '0');
    final cliente = (customerName == null || customerName.trim().isEmpty)
        ? 'CLIENTE POS'
        : customerName.trim().toUpperCase();
    final doc = (customerDocument == null || customerDocument.trim().isEmpty)
        ? 'CF'
        : customerDocument.trim();

    final lines = <String>[
      ..._header(config, name),
      ThermalOpsText.line(),
      'Factura: $factura',
      'Pto. Facturacion: $pto',
      'Fecha de Emision: ${En1DateTimeService.formatLocal(sale.saleDate, 'dd-MM-yyyy HH:mm')}',
      'Razon social Cliente: $cliente',
      'Numero de documento: $doc',
      if (sale.cashierName != null) 'Cajero: ${sale.cashierName}',
      ThermalOpsText.line(),
      ThermalOpsText.itemHeader(),
    ];

    final taxByRate = <double, double>{};
    var exemptBase = 0.0;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final lineTax = _lineTax(item, taxIncluded);
      final base = (item.quantity * item.unitPrice) - item.discount;
      if (item.taxRate <= 0) {
        exemptBase += taxIncluded && lineTax > 0 ? base - lineTax : base;
      } else {
        taxByRate[item.taxRate] = (taxByRate[item.taxRate] ?? 0) + lineTax;
      }

      lines.add(ThermalOpsText.itemCodeName(_itemCode(item), item.productName));
      lines.add(ThermalOpsText.itemValues(
        qty: item.quantity,
        unitPrice: item.unitPrice,
        itbms: lineTax,
        monto: item.total,
      ));
      if (i < items.length - 1) lines.add('');
    }

    final taxFromLines =
        taxByRate.values.fold<double>(0, (a, b) => a + b);
    final itbmsTotal =
        taxFromLines > 0.0001 ? taxFromLines : sale.taxAmount;
    final merchTotal = sale.total - sale.tipAmount;
    final neto = taxIncluded && itbmsTotal > 0
        ? merchTotal - itbmsTotal
        : sale.subtotal;
    final discount = sale.discount + sale.couponDiscount;

    // Si no hubo desglose por línea pero hay ITBMS en la venta, una sola fila.
    final ratesToShow = <MapEntry<double, double>>[];
    if (taxFromLines > 0.0001) {
      ratesToShow.addAll(
        taxByRate.entries.where((e) => e.value > 0.0001).toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
    } else if (itbmsTotal > 0.0001) {
      final rate = items
          .map((i) => i.taxRate)
          .where((r) => r > 0)
          .fold<double?>(null, (a, b) => a ?? b);
      ratesToShow.add(MapEntry(rate ?? (config?.taxRate ?? 7), itbmsTotal));
    }

    lines.addAll([
      ThermalOpsText.line(),
      ThermalOpsText.row('Num pedidos:', '${items.length}'),
      ThermalOpsText.row('Neto sin impuestos:', _money(symbol, neto)),
      if (exemptBase > 0.0001)
        ThermalOpsText.row('Exento:', _money(symbol, exemptBase)),
      for (final e in ratesToShow)
        ThermalOpsText.row(
          '$taxName ${e.key.toStringAsFixed(0)}%:',
          _money(symbol, e.value),
        ),
      if (itbmsTotal > 0.0001)
        ThermalOpsText.row('$taxName Total:', _money(symbol, itbmsTotal)),
      ThermalOpsText.row('Descuento:', _money(symbol, discount)),
      if (sale.tipAmount > 0)
        ThermalOpsText.row('Propina:', _money(symbol, sale.tipAmount)),
      ThermalOpsText.row('Total:', _money(symbol, sale.total)),
      ThermalOpsText.row('Cambio:', _money(symbol, sale.change)),
      'Metodos de pago:',
      ThermalOpsText.row(
          '${paymentMethodLabel(sale.paymentMethod)}:',
          _money(
              symbol, sale.amountPaid > 0 ? sale.amountPaid : sale.total)),
      ThermalOpsText.line(),
      ThermalOpsText.center(config?.receiptFooter ?? 'Gracias por su compra'),
    ]);
    return lines;
  }

  static String qrPayload({
    required Sale sale,
    required String symbol,
  }) {
    final no = sale.receiptNumber ?? sale.localId;
    final digits = no.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    final total = sale.total.toStringAsFixed(2);
    final when =
        En1DateTimeService.formatLocal(sale.saleDate, 'yyMMddHHmm');
    return 'E1|$digits|$total|$when';
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
    Map<double, double>? taxByRate,
    double exemptBase = 0,
  }) {
    final name = config?.businessName ?? 'EPOSOne';
    final taxName = config?.taxName ?? 'ITBMS';
    final result = <String>[
      ThermalOpsText.center('CUENTA / PRECUENTA'),
      ..._header(config, name),
      ThermalOpsText.center(En1DateTimeService.formatLocal(
          En1DateTimeService.nowUtc(), 'dd-MM-yyyy HH:mm')),
      if (ticketLabel != null && ticketLabel.isNotEmpty) ticketLabel,
      if (comment != null && comment.isNotEmpty) comment,
      ThermalOpsText.line(),
      ThermalOpsText.itemHeader(),
    ];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      result.add(line.name.toUpperCase());
      result.add(ThermalOpsText.itemValues(
        qty: line.qty,
        unitPrice: line.qty > 0 ? line.lineTotal / line.qty : line.lineTotal,
        itbms: 0,
        monto: line.lineTotal,
      ));
      if (i < lines.length - 1) result.add('');
    }

    final rates = (taxByRate ?? {})
        .entries
        .where((e) => e.value > 0.0001)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    result.addAll([
      ThermalOpsText.line(),
      ThermalOpsText.row('Neto sin impuestos:', _money(symbol, subtotal)),
      ThermalOpsText.row('Descuento:', _money(symbol, discount)),
      if (exemptBase > 0.0001)
        ThermalOpsText.row('Exento:', _money(symbol, exemptBase)),
      for (final e in rates)
        ThermalOpsText.row(
          '$taxName ${e.key.toStringAsFixed(0)}%:',
          _money(symbol, e.value),
        ),
      if (rates.isEmpty && tax > 0.0001)
        ThermalOpsText.row('$taxName:', _money(symbol, tax)),
      if (tax > 0.0001 && rates.isNotEmpty)
        ThermalOpsText.row('$taxName Total:', _money(symbol, tax)),
      ThermalOpsText.row('TOTAL ADEUDADO:', _money(symbol, total)),
      ThermalOpsText.line(),
      ThermalOpsText.center('Documento informativo'),
      ThermalOpsText.center('No es factura'),
    ]);
    return result;
  }

  static List<String> _header(BusinessConfig? config, String name) {
    final out = <String>[ThermalOpsText.center(name.toUpperCase())];
    final header = config?.receiptHeader.trim();
    if (header != null &&
        header.isNotEmpty &&
        header.toLowerCase() != 'gracias por su compra' &&
        header.toLowerCase() != 'vuelva pronto') {
      out.add(ThermalOpsText.center(header.toUpperCase()));
    }
    final branch = config?.fiscalBranchCode?.trim();
    if (branch != null && branch.isNotEmpty) {
      out.add(ThermalOpsText.center('Sucursal $branch'));
    }
    if (config?.ruc != null && config!.ruc!.trim().isNotEmpty) {
      out.add(ThermalOpsText.center('RUC: ${config.ruc!.trim()}'));
    }
    if (config?.address != null && config!.address!.trim().isNotEmpty) {
      out.addAll(ThermalOpsText.wrapCenter(config.address!.trim()));
    }
    if (config?.phone != null && config!.phone!.trim().isNotEmpty) {
      out.add(ThermalOpsText.center('Tel: ${config.phone!.trim()}'));
    }
    return out;
  }

  static String _facturaNumber(String? receiptNumber) {
    if (receiptNumber == null || receiptNumber.isEmpty) return '0000000000';
    final digits = receiptNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return receiptNumber;
    return digits.length >= 10
        ? digits.substring(digits.length - 10)
        : digits.padLeft(10, '0');
  }

  static String _itemCode(SaleItem item) {
    var id = item.productId.trim();
    if (id.toUpperCase().startsWith('EN1_')) {
      id = id.substring(4);
    }
    id = id.replaceAll('-', '');
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(id.length - 6).toUpperCase();
  }

  static double _lineTax(SaleItem item, bool taxIncluded) {
    if (item.taxRate <= 0) return 0;
    final base = (item.quantity * item.unitPrice) - item.discount;
    if (taxIncluded) {
      return item.total - (item.total / (1 + item.taxRate / 100));
    }
    return base * item.taxRate / 100;
  }

  static String _money(String symbol, double amount) =>
      '$symbol${amount.toStringAsFixed(2)}';
}
