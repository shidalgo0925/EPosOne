import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utilidades de layout POS — tablet-first (estilo Loyverse).
abstract final class PosLayout {
  /// Tablet si el lado corto ≥ 600 dp (convención Flutter).
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  /// Columnas del grid — densidad estilo Loyverse (5–6 en tablet landscape).
  static int gridColumns(double catalogWidth) {
    if (catalogWidth >= 1100) return 6;
    if (catalogWidth >= 880) return 5;
    if (catalogWidth >= 680) return 4;
    if (catalogWidth >= 480) return 3;
    return 2;
  }

  /// Loyverse TPV en tablet usa landscape; bloqueamos solo en POS.
  static Future<void> lockLandscapeIfTablet(BuildContext context) async {
    if (!isTablet(context)) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static Future<void> unlockOrientations() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}
