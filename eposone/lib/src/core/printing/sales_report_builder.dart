import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:eposone/src/core/printing/thermal_ops_text.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Reporte de ventas — ancho operativo 42.
class SalesReportBuilder {
  static List<String> buildText({
    required BusinessConfig? config,
    required String symbol,
    required DateTime from,
    required DateTime to,
    required List<Sale> sales,
  }) {
    final completed =
        sales.where((s) => s.status == SaleStatus.completed).toList();
    final refunded =
        sales.where((s) => s.status == SaleStatus.refunded).toList();
    var gross = 0.0;
    var tips = 0.0;
    var tax = 0.0;
    final byPay = <PaymentMethod, double>{};
    final byCashier = <String, double>{};

    for (final s in completed) {
      gross += s.total;
      tips += s.tipAmount;
      tax += s.taxAmount;
      byPay[s.paymentMethod] = (byPay[s.paymentMethod] ?? 0) + s.total;
      final key = s.cashierName ?? s.cashierId ?? 'Sin cajero';
      byCashier[key] = (byCashier[key] ?? 0) + s.total;
    }
    var refundTotal = 0.0;
    for (final s in refunded) {
      refundTotal += s.total;
    }

    return [
      ThermalOpsText.center('REPORTE DE VENTAS'),
      ThermalOpsText.center(config?.businessName ?? 'EPOSOne'),
      ThermalOpsText.center(
          '${En1DateTimeService.formatLocal(from, 'dd/MM/yyyy')} - ${En1DateTimeService.formatLocal(to, 'dd/MM/yyyy')}'),
      ThermalOpsText.line(),
      ThermalOpsText.row('Tickets', '${completed.length}'),
      ThermalOpsText.row('Bruto', '$symbol${gross.toStringAsFixed(2)}'),
      if (tax > 0)
        ThermalOpsText.row('Impuestos', '$symbol${tax.toStringAsFixed(2)}'),
      if (tips > 0)
        ThermalOpsText.row('Propinas', '$symbol${tips.toStringAsFixed(2)}'),
      if (refunded.isNotEmpty) ...[
        ThermalOpsText.row('Devoluciones', '${refunded.length}'),
        ThermalOpsText.row(
            'Monto devoluciones', '-$symbol${refundTotal.toStringAsFixed(2)}'),
      ],
      ThermalOpsText.row(
          'Neto', '$symbol${(gross - refundTotal).toStringAsFixed(2)}'),
      ThermalOpsText.line(),
      ThermalOpsText.center('Por metodo de pago'),
      for (final e in byPay.entries)
        ThermalOpsText.row(
            paymentMethodLabel(e.key), '$symbol${e.value.toStringAsFixed(2)}'),
      if (byCashier.length > 1) ...[
        ThermalOpsText.line(),
        ThermalOpsText.center('Por cajero'),
        for (final e in byCashier.entries)
          ThermalOpsText.row(
            ThermalOpsText.clip(e.key, 24),
            '$symbol${e.value.toStringAsFixed(2)}',
          ),
      ],
      ThermalOpsText.line(),
      ThermalOpsText.center(
          En1DateTimeService.formatLocal(En1DateTimeService.nowUtc())),
    ];
  }

  static Future<Uint8List> buildPdf({
    required BusinessConfig? config,
    required String symbol,
    required DateTime from,
    required DateTime to,
    required List<Sale> sales,
    PdfPageFormat? pageFormat,
  }) async {
    final text = buildText(
      config: config,
      symbol: symbol,
      from: from,
      to: to,
      sales: sales,
    );
    return ThermalOpsText.linesToPdf(text, pageFormat: pageFormat);
  }
}
