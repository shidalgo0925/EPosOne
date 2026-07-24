import 'dart:io';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:eposone/src/core/printing/esc_pos_bytes.dart';
import 'package:eposone/src/core/printing/network_printer_service.dart';
import 'package:eposone/src/core/printing/printer_prefs.dart';

/// Impresión térmica: Bluetooth ESC/POS + cajón (L5.1 / L5.3).
/// La ruta unificada (BT o red) está en [printViaConfiguredChannel].
class ThermalPrinterService {
  static Future<bool> ensureConnected() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    final mac = await PrinterPrefs.getPrinterMac();
    if (mac == null || mac.isEmpty) return false;

    if (await PrintBluetoothThermal.connectionStatus) return true;

    final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!granted) return false;

    return PrintBluetoothThermal.connect(macPrinterAddress: mac);
  }

  /// Envía líneas por Bluetooth.
  static Future<bool> printLines(
    List<String> lines, {
    String? qrData,
    List<int>? logoRaster,
  }) async {
    if (!await ensureConnected()) return false;
    return PrintBluetoothThermal.writeBytes(
      EscPosBytes.fromLines(lines, qrData: qrData, logoRaster: logoRaster),
    );
  }

  /// Usa el canal configurado en Ajustes (BT o Red).
  static Future<bool> printViaConfiguredChannel(
    List<String> lines, {
    String? qrData,
    List<int>? logoRaster,
  }) async {
    final channel = await PrinterPrefs.getChannel();
    if (channel == PrinterChannel.network) {
      return NetworkPrinterService.printLines(
        lines,
        qrData: qrData,
        logoRaster: logoRaster,
      );
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return printLines(lines, qrData: qrData, logoRaster: logoRaster);
    }
    return false;
  }

  static Future<bool> openCashDrawer() async {
    final channel = await PrinterPrefs.getChannel();
    if (channel == PrinterChannel.network) {
      return NetworkPrinterService.openCashDrawer();
    }
    if (!await ensureConnected()) return false;
    return PrintBluetoothThermal.writeBytes(EscPosBytes.drawerPulse);
  }

  static Future<void> openDrawerIfConfigured(
      {required bool isCashPayment}) async {
    if (!isCashPayment) return;
    if (!await PrinterPrefs.getOpenCashDrawerOnCash()) return;
    await openCashDrawer();
  }

  static Future<List<BluetoothInfo>> listPairedDevices() {
    return PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<bool> testPrint() async {
    return printViaConfiguredChannel([
      'EPOSOne',
      'Prueba de impresion',
      DateTime.now().toString().substring(0, 16),
      'OK ESC/POS',
    ]);
  }
}
