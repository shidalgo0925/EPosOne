import 'dart:typed_data';

import 'package:eposone/src/core/printing/esc_pos_bytes.dart';
import 'package:eposone/src/core/printing/printer_prefs.dart';
import 'package:eposone/src/core/printing/receipt_logo_loader.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Prepara raster ESC/POS del logo del comercio para térmica.
abstract final class ThermalLogoRaster {
  /// Null si no hay logo, preferencia off, o falla el encode.
  static Future<List<int>?> fromConfig(BusinessConfig? config) async {
    if (!await PrinterPrefs.getPrintLogoOnThermal()) return null;
    final bytes = await ReceiptLogoLoader.bytesFromConfig(config);
    if (bytes == null || bytes.isEmpty) return null;
    return EscPosBytes.rasterFromImageBytes(Uint8List.fromList(bytes));
  }
}
