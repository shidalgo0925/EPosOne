import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Tamaño tipográfico ESC/POS (ESC ! n).
enum EscPosFontSize {
  normal,
  doubleHeight,
  doubleWidth,
  doubleBoth,
}

/// Línea de ticket con tamaño y alineación.
class EscPosPrintLine {
  final String text;
  final EscPosFontSize size;
  final bool center;

  const EscPosPrintLine(
    this.text, {
    this.size = EscPosFontSize.normal,
    this.center = false,
  });

  /// Columnas útiles aprox. en Font A 80 mm.
  static int colsFor(EscPosFontSize size) => switch (size) {
        EscPosFontSize.normal || EscPosFontSize.doubleHeight => 48,
        EscPosFontSize.doubleWidth || EscPosFontSize.doubleBoth => 24,
      };
}

/// Bytes ESC/POS compartidos (BT y red TCP).
class EscPosBytes {
  EscPosBytes._();

  static const drawerPulse = [0x1B, 0x70, 0x00, 0x19, 0xFA];
  static const paperCut = [0x1D, 0x56, 0x00];
  static const init = [0x1B, 0x40];
  static const alignLeft = [0x1B, 0x61, 0x00];
  static const alignCenter = [0x1B, 0x61, 0x01];
  static const fontNormal = [0x1B, 0x21, 0x00];
  /// ESC ! : bit4=doble alto, bit5=doble ancho.
  static const fontDoubleHeight = [0x1B, 0x21, 0x10];
  static const fontDoubleWidth = [0x1B, 0x21, 0x20];
  static const fontDoubleBoth = [0x1B, 0x21, 0x30];

  static List<int> fontBytes(EscPosFontSize size) => switch (size) {
        EscPosFontSize.normal => fontNormal,
        EscPosFontSize.doubleHeight => fontDoubleHeight,
        EscPosFontSize.doubleWidth => fontDoubleWidth,
        EscPosFontSize.doubleBoth => fontDoubleBoth,
      };

  /// Construye ticket: init + logo opcional + líneas ASCII + QR + corte.
  static List<int> fromLines(
    List<String> lines, {
    String? qrData,
    List<int>? logoRaster,
  }) {
    return fromPrintLines(
      [
        for (final line in lines)
          EscPosPrintLine(line, size: EscPosFontSize.normal),
      ],
      qrData: qrData,
      logoRaster: logoRaster,
    );
  }

  /// Ticket con tamaños por línea (comandas cocina/bar).
  static List<int> fromPrintLines(
    List<EscPosPrintLine> lines, {
    String? qrData,
    List<int>? logoRaster,
  }) {
    final bytes = <int>[
      ...init,
    ];

    if (logoRaster != null && logoRaster.isNotEmpty) {
      bytes.addAll(alignCenter);
      bytes.addAll(logoRaster);
      bytes.addAll([0x0A, 0x0A, 0x0A]);
    }

    for (final line in lines) {
      bytes.addAll(line.center ? alignCenter : alignLeft);
      bytes.addAll(fontBytes(line.size));
      bytes.addAll(_encodeAscii(_toPrinterText(line.text)));
      bytes.add(0x0A);
    }

    bytes.addAll(alignLeft);
    bytes.addAll(fontNormal);

    if (qrData != null && qrData.isNotEmpty) {
      bytes.addAll([0x0A, 0x0A]);
      bytes.addAll(alignCenter);
      bytes.addAll(qrCode(qrData, size: 10));
      bytes.addAll(alignLeft);
      bytes.addAll([0x0A, 0x0A]);
    }

    bytes.addAll([0x0A, 0x0A]);
    bytes.addAll(paperCut);
    return bytes;
  }

  /// Raster GS v 0 desde bytes de imagen (PNG/JPG). Null si no se puede.
  /// [maxWidthDots] ~384 encaja en 58/80 mm sin desbordar buffer barato.
  static List<int>? rasterFromImageBytes(
    Uint8List imageBytes, {
    int maxWidthDots = 384,
    int maxHeightDots = 200,
  }) {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      var image = decoded;
      if (image.width > maxWidthDots) {
        image = img.copyResize(
          image,
          width: maxWidthDots,
          interpolation: img.Interpolation.average,
        );
      }
      if (image.height > maxHeightDots) {
        image = img.copyResize(
          image,
          height: maxHeightDots,
          interpolation: img.Interpolation.average,
        );
      }

      // Ancho múltiplo de 8 para empaquetado limpio.
      final targetW = (image.width + 7) & ~7;
      if (image.width != targetW) {
        final canvas = img.Image(width: targetW, height: image.height);
        img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
        img.compositeImage(canvas, image, dstX: 0, dstY: 0);
        image = canvas;
      }

      final gray = img.grayscale(image);
      final widthBytes = gray.width ~/ 8;
      final height = gray.height;
      final data = <int>[];

      for (var y = 0; y < height; y++) {
        for (var xb = 0; xb < widthBytes; xb++) {
          var byte = 0;
          for (var bit = 0; bit < 8; bit++) {
            final x = xb * 8 + bit;
            final pixel = gray.getPixel(x, y);
            final lum = img.getLuminance(pixel);
            // Oscuro → bit 1 (imprime negro en térmica).
            if (lum < 160) {
              byte |= 0x80 >> bit;
            }
          }
          data.add(byte);
        }
      }

      final xL = widthBytes & 0xFF;
      final xH = (widthBytes >> 8) & 0xFF;
      final yL = height & 0xFF;
      final yH = (height >> 8) & 0xFF;

      return [
        0x1D, 0x76, 0x30, 0x00, // GS v 0, modo normal
        xL, xH, yL, yH,
        ...data,
      ];
    } catch (_) {
      return null;
    }
  }

  /// QR Code Model 2 (GS ( k).
  /// [size] módulo 3–16 (muchas térmicas aceptan hasta 16; más grande = más legible).
  static List<int> qrCode(String data, {int size = 10}) {
    final payload = data.codeUnits;
    final storeLen = payload.length + 3;
    final pL = storeLen & 0xFF;
    final pH = (storeLen >> 8) & 0xFF;
    final module = size.clamp(3, 16);

    return [
      // Model 2
      0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00,
      // Module size
      0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, module,
      // Error correction L
      0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30,
      // Store data
      0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30,
      ...payload,
      // Print
      0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30,
    ];
  }

  /// Térmicas baratas suelen esperar CP437/ASCII, no UTF-8.
  static String _toPrinterText(String input) {
    const map = <String, String>{
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'Á': 'A',
      'À': 'A',
      'Ä': 'A',
      'Â': 'A',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'É': 'E',
      'È': 'E',
      'Ë': 'E',
      'Ê': 'E',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'Í': 'I',
      'Ì': 'I',
      'Ï': 'I',
      'Î': 'I',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'Ó': 'O',
      'Ò': 'O',
      'Ö': 'O',
      'Ô': 'O',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'Ú': 'U',
      'Ù': 'U',
      'Ü': 'U',
      'Û': 'U',
      'ñ': 'n',
      'Ñ': 'N',
      '¿': '?',
      '¡': '!',
      '°': 'o',
      '–': '-',
      '—': '-',
      '“': '"',
      '”': '"',
      '‘': "'",
      '’': "'",
    };
    var out = input;
    map.forEach((k, v) => out = out.replaceAll(k, v));
    return out.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
  }

  static List<int> _encodeAscii(String text) =>
      text.codeUnits.where((c) => c >= 0x20 && c <= 0x7E).toList();
}
