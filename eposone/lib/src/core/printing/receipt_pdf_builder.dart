import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:eposone/src/core/printing/receipt_logo_loader.dart';
import 'package:eposone/src/core/printing/receipt_text_builder.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// PDF estrecho — mismo modelo de recibo que la térmica.
class ReceiptPdfBuilder {
  static PdfPageFormat _ticketPageFormat({
    PdfPageFormat? requested,
    required int contentLines,
    bool hasLogo = false,
  }) {
    final width = requested?.width ?? (58 * PdfPageFormat.mm);
    const minH = 120 * PdfPageFormat.mm;
    final logoPad = hasLogo ? 28.0 : 0.0;
    final estimated =
        (48 + logoPad + contentLines * 11.0) * PdfPageFormat.mm / 2.8;
    final height = (requested != null &&
            requested.height.isFinite &&
            requested.height > 0 &&
            requested.height < 2000 * PdfPageFormat.mm)
        ? requested.height
        : estimated.clamp(minH, 500 * PdfPageFormat.mm);
    return PdfPageFormat(
      width,
      height,
      marginAll: 3 * PdfPageFormat.mm,
    );
  }

  static List<pw.Widget> _logoWidgets(pw.MemoryImage? logo) {
    if (logo == null) return const [];
    return [
      pw.Center(
        child: pw.Image(
          logo,
          width: 72,
          height: 72,
          fit: pw.BoxFit.contain,
        ),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static Future<Uint8List> buildSaleReceipt({
    required BusinessConfig? config,
    required Sale sale,
    required List<SaleItem> items,
    required String symbol,
    String? customerName,
    String? customerDocument,
    PdfPageFormat? pageFormat,
  }) async {
    final textLines = ReceiptTextBuilder.buildSaleReceipt(
      config: config,
      sale: sale,
      items: items,
      symbol: symbol,
      customerName: customerName,
      customerDocument: customerDocument,
    );
    final qr = ReceiptTextBuilder.qrPayload(sale: sale, symbol: symbol);
    final logoBytes = await ReceiptLogoLoader.bytesFromConfig(config);
    final logo = logoBytes == null ? null : pw.MemoryImage(logoBytes);
    final doc = pw.Document();
    final format = _ticketPageFormat(
      requested: pageFormat,
      contentLines: textLines.length + 8,
      hasLogo: logo != null,
    );

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            ..._logoWidgets(logo),
            for (final line in textLines)
              if (line.trim().isNotEmpty)
                pw.Text(
                  line,
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qr,
                width: 140,
                height: 140,
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Pre-cuenta / cuenta (no fiscal).
  static Future<Uint8List> buildBillPreview({
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
    PdfPageFormat? pageFormat,
  }) async {
    final textLines = ReceiptTextBuilder.buildBillPreview(
      config: config,
      symbol: symbol,
      ticketLabel: ticketLabel,
      comment: comment,
      lines: lines,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: total,
      taxByRate: taxByRate,
      exemptBase: exemptBase,
    );
    final logoBytes = await ReceiptLogoLoader.bytesFromConfig(config);
    final logo = logoBytes == null ? null : pw.MemoryImage(logoBytes);
    final doc = pw.Document();
    final format = _ticketPageFormat(
      requested: pageFormat,
      contentLines: textLines.length + 2,
      hasLogo: logo != null,
    );

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            ..._logoWidgets(logo),
            for (final line in textLines)
              if (line.trim().isNotEmpty)
                pw.Text(
                  line,
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
          ],
        ),
      ),
    );

    return doc.save();
  }
}
