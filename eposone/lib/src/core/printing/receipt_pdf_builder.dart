import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// PDF estrecho (80mm) para impresión del sistema y compartir.
class ReceiptPdfBuilder {
  static Future<Uint8List> buildSaleReceipt({
    required BusinessConfig? config,
    required Sale sale,
    required List<SaleItem> items,
    required String symbol,
  }) async {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final doc = pw.Document();
    final pageFormat = PdfPageFormat.roll80;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        build: (context) => [
          pw.Center(child: pw.Text(config?.businessName ?? 'EPOSOne', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
          if (config?.address != null) pw.Center(child: pw.Text(config!.address!, style: const pw.TextStyle(fontSize: 9))),
          if (config?.ruc != null) pw.Center(child: pw.Text('RUC: ${config!.ruc}', style: const pw.TextStyle(fontSize: 9))),
          pw.SizedBox(height: 8),
          pw.Divider(),
          if (sale.receiptNumber != null) pw.Text('Recibo: ${sale.receiptNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(dateFmt.format(sale.saleDate), style: const pw.TextStyle(fontSize: 9)),
          if (sale.cashierName != null) pw.Text('Cajero: ${sale.cashierName}', style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 8),
          for (final item in items)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(1)} x ${item.productName}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text('$symbol${(item.quantity * item.unitPrice).toStringAsFixed(2)}'),
                ],
              ),
            ),
          pw.Divider(),
          _pdfRow('Subtotal', '$symbol${sale.subtotal.toStringAsFixed(2)}'),
          if (sale.discount > 0) _pdfRow('Descuento', '-$symbol${sale.discount.toStringAsFixed(2)}'),
          if (sale.taxAmount > 0) _pdfRow(config?.taxName ?? 'ITBMS', '$symbol${sale.taxAmount.toStringAsFixed(2)}'),
          _pdfRow('TOTAL', '$symbol${sale.total.toStringAsFixed(2)}', bold: true),
          _pdfRow('Método', paymentMethodLabel(sale.paymentMethod)),
          if (sale.change > 0) _pdfRow('Vuelto', '$symbol${sale.change.toStringAsFixed(2)}'),
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Text(config?.receiptFooter ?? 'Gracias por su compra', style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
