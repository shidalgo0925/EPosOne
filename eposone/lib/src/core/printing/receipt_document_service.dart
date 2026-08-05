import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:eposone/src/core/printing/cash_document_builder.dart';
import 'package:eposone/src/core/printing/print_engine.dart';
import 'package:eposone/src/core/printing/receipt_pdf_builder.dart';
import 'package:eposone/src/core/printing/receipt_text_builder.dart';
import 'package:eposone/src/core/printing/shift_report_builder.dart';
import 'package:eposone/src/core/printing/thermal_logo_raster.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_movement.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/cash_register/domain/shift_summary.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Fachada de documentos comerciales/caja → [PrintEngine].
class ReceiptDocumentService {
  static Future<Uint8List> salePdfBytes({
    required BusinessConfig? config,
    required Sale sale,
    required List<SaleItem> items,
    required String symbol,
    String? customerName,
    String? customerDocument,
  }) {
    return ReceiptPdfBuilder.buildSaleReceipt(
      config: config,
      sale: sale,
      items: items,
      symbol: symbol,
      customerName: customerName,
      customerDocument: customerDocument,
    );
  }

  static Future<void> printSale({
    required BuildContext context,
    required BusinessConfig? config,
    required Sale sale,
    required List<SaleItem> items,
    required String symbol,
    String? customerName,
    String? customerDocument,
  }) async {
    final logoRaster = await ThermalLogoRaster.fromConfig(config);
    if (!context.mounted) return;
    await PrintEngine.printDocument(
      context: context,
      textLines: ReceiptTextBuilder.buildSaleReceipt(
        config: config,
        sale: sale,
        items: items,
        symbol: symbol,
        customerName: customerName,
        customerDocument: customerDocument,
      ),
      qrData: ReceiptTextBuilder.qrPayload(sale: sale, symbol: symbol),
      logoRaster: logoRaster,
      buildPdf: (format) => ReceiptPdfBuilder.buildSaleReceipt(
        config: config,
        sale: sale,
        items: items,
        symbol: symbol,
        customerName: customerName,
        customerDocument: customerDocument,
        pageFormat: format,
      ),
      thermalOkMessage: 'Recibo enviado a impresora',
    );
  }

  static Future<void> shareSalePdf({
    required Sale sale,
    required BusinessConfig? config,
    required List<SaleItem> items,
    required String symbol,
    String? customerName,
    String? customerDocument,
  }) async {
    final bytes = await salePdfBytes(
      config: config,
      sale: sale,
      items: items,
      symbol: symbol,
      customerName: customerName,
      customerDocument: customerDocument,
    );
    final business = config?.businessName ?? 'EPOSOne';
    final receiptNo = sale.receiptNumber ?? sale.localId;
    final message = StringBuffer()
      ..writeln(business)
      ..writeln('Recibo: $receiptNo')
      ..writeln('Total: $symbol${sale.total.toStringAsFixed(2)}');
    if (sale.tipAmount > 0) {
      message.writeln('Propina: $symbol${sale.tipAmount.toStringAsFixed(2)}');
    }
    message.write(config?.receiptFooter ?? 'Gracias por su compra');

    await PrintEngine.sharePdf(
      bytes: bytes,
      fileName: 'recibo_$receiptNo.pdf',
      subject: 'Recibo $receiptNo — $business',
      body: message.toString(),
    );
  }

  static Future<void> printBillPreview({
    required BuildContext context,
    required BusinessConfig? config,
    required String symbol,
    String? ticketLabel,
    String? comment,
    required List<({String name, double qty, double lineTotal})> lines,
    required double subtotal,
    required double discount,
    String? discountLabel,
    required double tax,
    required double total,
    Map<double, double>? taxByRate,
    double exemptBase = 0,
  }) async {
    final logoRaster = await ThermalLogoRaster.fromConfig(config);
    if (!context.mounted) return;
    await PrintEngine.printDocument(
      context: context,
      textLines: ReceiptTextBuilder.buildBillPreview(
        config: config,
        symbol: symbol,
        ticketLabel: ticketLabel,
        comment: comment,
        lines: lines,
        subtotal: subtotal,
        discount: discount,
        discountLabel: discountLabel,
        tax: tax,
        total: total,
        taxByRate: taxByRate,
        exemptBase: exemptBase,
      ),
      logoRaster: logoRaster,
      buildPdf: (format) => ReceiptPdfBuilder.buildBillPreview(
        config: config,
        symbol: symbol,
        ticketLabel: ticketLabel,
        comment: comment,
        lines: lines,
        subtotal: subtotal,
        discount: discount,
        discountLabel: discountLabel,
        tax: tax,
        total: total,
        taxByRate: taxByRate,
        exemptBase: exemptBase,
        pageFormat: format,
      ),
      thermalOkMessage: 'Pre-cuenta enviada a impresora',
    );
  }

  /// Arqueo (X) o cierre (Z).
  static Future<void> printShiftReport({
    required BuildContext context,
    required BusinessConfig? config,
    required CashRegister register,
    required ShiftSummary summary,
    required String symbol,
    required bool isClosing,
    double? countedCash,
    double? difference,
  }) async {
    await PrintEngine.printDocument(
      context: context,
      textLines: ShiftReportBuilder.buildText(
        config: config,
        register: register,
        summary: summary,
        symbol: symbol,
        isClosing: isClosing,
        countedCash: countedCash,
        difference: difference,
      ),
      buildPdf: (format) => ShiftReportBuilder.buildPdf(
        config: config,
        register: register,
        summary: summary,
        symbol: symbol,
        isClosing: isClosing,
        countedCash: countedCash,
        difference: difference,
        pageFormat: format,
      ),
      thermalOkMessage:
          isClosing ? 'Cierre (Z) enviado a impresora' : 'Arqueo (X) enviado a impresora',
    );
  }

  static Future<void> printCashOpen({
    required BuildContext context,
    required BusinessConfig? config,
    required CashRegister register,
    required String symbol,
  }) async {
    await PrintEngine.printDocument(
      context: context,
      textLines: CashDocumentBuilder.buildOpenText(
        config: config,
        register: register,
        symbol: symbol,
      ),
      buildPdf: (format) => CashDocumentBuilder.buildOpenPdf(
        config: config,
        register: register,
        symbol: symbol,
        pageFormat: format,
      ),
      thermalOkMessage: 'Apertura enviada a impresora',
    );
  }

  static Future<void> printCashMovement({
    required BuildContext context,
    required BusinessConfig? config,
    required CashMovement movement,
    required String symbol,
  }) async {
    await PrintEngine.printDocument(
      context: context,
      textLines: CashDocumentBuilder.buildMovementText(
        config: config,
        movement: movement,
        symbol: symbol,
      ),
      buildPdf: (format) => CashDocumentBuilder.buildMovementPdf(
        config: config,
        movement: movement,
        symbol: symbol,
        pageFormat: format,
      ),
      thermalOkMessage: 'Movimiento enviado a impresora',
    );
  }
}
