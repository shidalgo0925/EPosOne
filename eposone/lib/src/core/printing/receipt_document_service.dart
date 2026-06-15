import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eposone/src/core/printing/receipt_pdf_builder.dart';
import 'package:eposone/src/core/printing/receipt_text_builder.dart';
import 'package:eposone/src/core/printing/thermal_printer_service.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Orquesta impresión PDF, térmica BT y compartir (L5 + L6.1).
class ReceiptDocumentService {
  static Future<Uint8List> salePdfBytes({
    required BusinessConfig? config,
    required Sale sale,
    required List<SaleItem> items,
    required String symbol,
  }) {
    return ReceiptPdfBuilder.buildSaleReceipt(
      config: config,
      sale: sale,
      items: items,
      symbol: symbol,
    );
  }

  static Future<void> printSale({
    required BuildContext context,
    required BusinessConfig? config,
    required Sale sale,
    required List<SaleItem> items,
    required String symbol,
  }) async {
    final lines = ReceiptTextBuilder.buildSaleReceipt(
      config: config,
      sale: sale,
      items: items,
      symbol: symbol,
    );

    if (Platform.isAndroid || Platform.isIOS) {
      final thermalOk = await ThermalPrinterService.printLines(lines);
      if (thermalOk) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recibo enviado a impresora térmica')),
          );
        }
        return;
      }
    }

    final bytes = await salePdfBytes(config: config, sale: sale, items: items, symbol: symbol);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> shareSalePdf({
    required Sale sale,
    required BusinessConfig? config,
    required List<SaleItem> items,
    required String symbol,
  }) async {
    final bytes = await salePdfBytes(config: config, sale: sale, items: items, symbol: symbol);
    final dir = await getTemporaryDirectory();
    final name = sale.receiptNumber ?? sale.localId;
    final file = File('${dir.path}/recibo_$name.pdf');
    await file.writeAsBytes(bytes);

    final business = config?.businessName ?? 'EPOSOne';
    final receiptNo = sale.receiptNumber ?? sale.localId;
    final message = StringBuffer()
      ..writeln('$business')
      ..writeln('Recibo: $receiptNo')
      ..writeln('Total: $symbol${sale.total.toStringAsFixed(2)}');
    if (sale.tipAmount > 0) {
      message.writeln('Propina: $symbol${sale.tipAmount.toStringAsFixed(2)}');
    }
    message.write(config?.receiptFooter ?? 'Gracias por su compra');

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: 'recibo_$name.pdf')],
      text: message.toString(),
      subject: 'Recibo $receiptNo — $business',
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
    required double tax,
    required double total,
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
    );

    if (Platform.isAndroid || Platform.isIOS) {
      final ok = await ThermalPrinterService.printLines(textLines);
      if (ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pre-cuenta enviada a impresora')),
          );
        }
        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configure impresora BT en Ajustes → Impresora')),
      );
    }
  }
}
