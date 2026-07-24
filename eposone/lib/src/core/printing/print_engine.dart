import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:eposone/src/core/printing/printer_prefs.dart';
import 'package:eposone/src/core/printing/thermal_printer_service.dart';

/// Motor único de impresión (estilo Loyverse).
/// Documentos y Reportes solo generan contenido; aquí sale el papel/PDF.
class PrintEngine {
  /// Canal configurado (BT o Red TCP) → si falla, diálogo PDF del sistema.
  /// Retorna `true` si salió por térmica (sin PDF).
  static Future<bool> printDocument({
    required BuildContext context,
    required List<String> textLines,
    required Future<Uint8List> Function(PdfPageFormat format) buildPdf,
    String? qrData,
    List<int>? logoRaster,
    String thermalOkMessage = 'Documento enviado a impresora',
    bool announcePdfFallback = true,
  }) async {
    final ok = await ThermalPrinterService.printViaConfiguredChannel(
      textLines,
      qrData: qrData,
      logoRaster: logoRaster,
    );
    if (ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(thermalOkMessage)),
        );
      }
      return true;
    }

    if (!context.mounted) return false;
    if (announcePdfFallback) {
      final channel = await PrinterPrefs.getChannel();
      if (!context.mounted) return false;
      final hint = channel == PrinterChannel.network
          ? 'Sin impresora de red: abriendo PDF. Revisa IP/puerto en Ajustes.'
          : 'Sin impresora BT: abriendo PDF. Elige la impresora en el diálogo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hint)),
      );
    }
    if (!context.mounted) return false;
    await Printing.layoutPdf(onLayout: buildPdf);
    return false;
  }

  static Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String subject,
    String? body,
  }) async {
    final dir = await getTemporaryDirectory();
    final safe = fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final file = File('${dir.path}/$safe');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: safe)],
      text: body,
      subject: subject,
    );
  }
}
