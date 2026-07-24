import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Layout monospacio térmico compartido (80 mm ≈ 48 cols Font A/B).
/// Recibo, precuenta y reportes usan el mismo ancho para llenar el papel.
class ThermalOpsText {
  ThermalOpsText._();

  /// 48 cols — llena papel 80 mm; evita el margen derecho vacío de 32.
  static const width = 48;

  static String center(String text) {
    if (text.length >= width) return text.substring(0, width);
    final pad = ((width - text.length) / 2).floor();
    return '${' ' * pad}$text';
  }

  static String row(String left, String right) {
    var l = left;
    final r = right;
    final maxLeft = width - r.length - 1;
    if (maxLeft < 1) {
      return r.length > width ? r.substring(r.length - width) : r.padLeft(width);
    }
    if (l.length > maxLeft) {
      l = '${l.substring(0, (maxLeft - 2).clamp(1, maxLeft))}..';
    }
    final space = width - l.length - r.length;
    return '$l${' ' * space}$r';
  }

  static String line() => '-' * width;

  static String clip(String text, [int max = 32]) {
    if (text.length <= max) return text;
    return '${text.substring(0, max - 2)}..';
  }

  static List<String> wrapCenter(String text) {
    if (text.length <= width) return [center(text)];
    final words = text.split(RegExp(r'\s+'));
    final rows = <String>[];
    var cur = '';
    for (final w in words) {
      final next = cur.isEmpty ? w : '$cur $w';
      if (next.length <= width) {
        cur = next;
      } else {
        if (cur.isNotEmpty) rows.add(center(cur));
        cur = w.length <= width ? w : w.substring(0, width);
      }
    }
    if (cur.isNotEmpty) rows.add(center(cur));
    return rows;
  }

  /// Columnas de ítem: Cant Und Precio Itbms Monto — sin truncar decimales.
  static String itemHeader() =>
      padCols(['Cant', 'Und', 'Precio', 'Itbms', 'Monto']);

  /// Código + nombre en una sola línea (48 cols).
  static String itemCodeName(String code, String name) {
    final c = code.trim().toUpperCase();
    final n = name.trim().toUpperCase();
    if (c.isEmpty) return clip(n, width);
    final prefix = '$c  ';
    final maxName = width - prefix.length;
    if (maxName < 3) return clip(c, width);
    if (n.length <= maxName) return '$prefix$n';
    return '$prefix${n.substring(0, maxName - 2)}..';
  }

  static String itemValues({
    required double qty,
    required double unitPrice,
    required double itbms,
    required double monto,
  }) {
    final q = qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2);
    return padCols([
      q,
      'und',
      unitPrice.toStringAsFixed(2),
      itbms.toStringAsFixed(2),
      monto.toStringAsFixed(2),
    ]);
  }

  /// Anchos fijos que suman ≤ [width] (nunca cortar la línea entera).
  static String padCols(List<String> cols) {
    // 6+4+9+9+10 + 4 espacios = 42 ≤ 48
    const widths = [6, 4, 9, 9, 10];
    final parts = <String>[];
    for (var i = 0; i < cols.length && i < widths.length; i++) {
      final w = widths[i];
      var c = cols[i];
      if (c.length > w) {
        // Números: preferir parte derecha (mantener decimales visibles).
        c = c.substring(c.length - w);
      }
      parts.add(i <= 1 ? c.padRight(w) : c.padLeft(w));
    }
    return parts.join(' ');
  }

  static Future<Uint8List> linesToPdf(
    List<String> lines, {
    PdfPageFormat? pageFormat,
  }) async {
    final pageW = pageFormat?.width ?? (80 * PdfPageFormat.mm);
    final height = (pageFormat != null &&
            pageFormat.height.isFinite &&
            pageFormat.height > 0 &&
            pageFormat.height < 2000 * PdfPageFormat.mm)
        ? pageFormat.height
        : (70 + lines.length * 11.0).clamp(120.0, 520.0) *
            PdfPageFormat.mm /
            2.5;
    final format =
        PdfPageFormat(pageW, height, marginAll: 3 * PdfPageFormat.mm);
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              if (line.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 1),
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
