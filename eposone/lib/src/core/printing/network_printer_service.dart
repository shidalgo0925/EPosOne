import 'dart:io';
import 'dart:typed_data';

import 'package:eposone/src/core/printing/esc_pos_bytes.dart';
import 'package:eposone/src/core/printing/printer_prefs.dart';

/// Impresión térmica por red (TCP raw ESC/POS, puerto típico 9100).
class NetworkPrinterService {
  static const _connectTimeout = Duration(seconds: 4);

  /// Envía bytes raw al host:puerto y cierra el socket.
  static Future<bool> sendRaw(
    List<int> bytes, {
    String? host,
    int? port,
  }) async {
    final resolvedHost =
        (host ?? await PrinterPrefs.getNetworkHost())?.trim();
    if (resolvedHost == null || resolvedHost.isEmpty) return false;
    final resolvedPort = port ?? await PrinterPrefs.getNetworkPort();

    Socket? socket;
    try {
      socket = await Socket.connect(
        resolvedHost,
        resolvedPort,
        timeout: _connectTimeout,
      );
      socket.add(Uint8List.fromList(bytes));
      await socket.flush();
      // Breve pausa para que la impresora vacíe el buffer antes de cerrar.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
      socket?.destroy();
    }
  }

  static Future<bool> printLines(
    List<String> lines, {
    String? host,
    int? port,
    String? qrData,
    List<int>? logoRaster,
  }) async {
    return sendRaw(
      EscPosBytes.fromLines(lines, qrData: qrData, logoRaster: logoRaster),
      host: host,
      port: port,
    );
  }

  static Future<bool> openCashDrawer() async {
    return sendRaw(EscPosBytes.drawerPulse);
  }

  static Future<bool> testPrint({String? host, int? port}) async {
    return printLines(
      [
        'EPOSOne',
        'Prueba red TCP',
        DateTime.now().toString().substring(0, 16),
        'OK ESC/POS NET',
      ],
      host: host,
      port: port,
    );
  }
}
