import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:eposone/src/core/printing/thermal_ops_text.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/cash_register/domain/shift_summary.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';

/// Documento de caja: arqueo (X) o cierre (Z) — ancho operativo 42.
class ShiftReportBuilder {
  static List<String> buildText({
    required BusinessConfig? config,
    required CashRegister register,
    required ShiftSummary summary,
    required String symbol,
    required bool isClosing,
    double? countedCash,
    double? difference,
  }) {
    final title = isClosing ? 'CIERRE DE TURNO (Z)' : 'ARQUEO DE TURNO (X)';
    final lines = <String>[
      ThermalOpsText.center(title),
      ThermalOpsText.center(config?.businessName ?? 'EPOSOne'),
      if (config?.address != null)
        ThermalOpsText.center(config!.address!),
      ThermalOpsText.line(),
      'Abierto: ${En1DateTimeService.formatLocal(register.openDate)}',
      if (register.closeDate != null)
        'Cerrado: ${En1DateTimeService.formatLocal(register.closeDate!)}',
      if (register.openedBy != null) 'Abrio: ${register.openedBy}',
      if (register.currentCashierName != null)
        'Cajero: ${register.currentCashierName}',
      if (register.closedBy != null) 'Cerro: ${register.closedBy}',
      ThermalOpsText.line(),
      ThermalOpsText.row('Ventas', '${summary.saleCount}'),
      ThermalOpsText.row(
          'Bruto', '$symbol${summary.grossSales.toStringAsFixed(2)}'),
      if (summary.totalDiscount > 0)
        ThermalOpsText.row('Descuentos',
            '-$symbol${summary.totalDiscount.toStringAsFixed(2)}'),
      if (summary.totalTax > 0)
        ThermalOpsText.row(
            'Impuestos', '$symbol${summary.totalTax.toStringAsFixed(2)}'),
      if (summary.totalTips > 0)
        ThermalOpsText.row(
            'Propinas', '$symbol${summary.totalTips.toStringAsFixed(2)}'),
      if (summary.refundCount > 0) ...[
        ThermalOpsText.row('Devoluciones', '${summary.refundCount}'),
        ThermalOpsText.row('Monto devoluciones',
            '-$symbol${summary.totalRefunds.toStringAsFixed(2)}'),
      ],
      ThermalOpsText.row(
          'Neto', '$symbol${summary.netSales.toStringAsFixed(2)}'),
      ThermalOpsText.line(),
      ThermalOpsText.center('Por metodo de pago'),
      for (final m in PaymentMethod.values)
        if (summary.paymentTotal(m) > 0)
          ThermalOpsText.row(paymentMethodLabel(m),
              '$symbol${summary.paymentTotal(m).toStringAsFixed(2)}'),
      ThermalOpsText.line(),
      ThermalOpsText.row(
          'Apertura', '$symbol${summary.openingAmount.toStringAsFixed(2)}'),
      ThermalOpsText.row('Efectivo ventas',
          '$symbol${summary.cashFromSales.toStringAsFixed(2)}'),
      if (summary.cashMovementIn > 0)
        ThermalOpsText.row('Ingresos',
            '$symbol${summary.cashMovementIn.toStringAsFixed(2)}'),
      if (summary.cashMovementOut > 0)
        ThermalOpsText.row('Retiros',
            '-$symbol${summary.cashMovementOut.toStringAsFixed(2)}'),
      ThermalOpsText.row('Efectivo esperado',
          '$symbol${summary.expectedCash.toStringAsFixed(2)}'),
      if (countedCash != null)
        ThermalOpsText.row(
            'Efectivo contado', '$symbol${countedCash.toStringAsFixed(2)}'),
      if (difference != null)
        ThermalOpsText.row(
            'Diferencia',
            '${difference >= 0 ? '+' : ''}$symbol${difference.toStringAsFixed(2)}'),
      ThermalOpsText.line(),
      ThermalOpsText.center(
          En1DateTimeService.formatLocal(En1DateTimeService.nowUtc())),
    ];
    return lines;
  }

  static Future<Uint8List> buildPdf({
    required BusinessConfig? config,
    required CashRegister register,
    required ShiftSummary summary,
    required String symbol,
    required bool isClosing,
    double? countedCash,
    double? difference,
    PdfPageFormat? pageFormat,
  }) async {
    final text = buildText(
      config: config,
      register: register,
      summary: summary,
      symbol: symbol,
      isClosing: isClosing,
      countedCash: countedCash,
      difference: difference,
    );
    return ThermalOpsText.linesToPdf(text, pageFormat: pageFormat);
  }
}
