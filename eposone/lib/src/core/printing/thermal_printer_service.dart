import 'dart:io';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:eposone/src/core/printing/printer_prefs.dart';

/// Impresión térmica Bluetooth ESC/POS (L5.1) + cajón (L5.3).
class ThermalPrinterService {
  /// ESC/POS: abrir cajón (pin 2).
  static const _drawerPulse = [0x1B, 0x70, 0x00, 0x19, 0xFA];

  /// ESC/POS: corte parcial.
  static const _paperCut = [0x1D, 0x56, 0x00];

  static Future<bool> ensureConnected() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    final mac = await PrinterPrefs.getPrinterMac();
    if (mac == null || mac.isEmpty) return false;

    if (await PrintBluetoothThermal.connectionStatus) return true;

    final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!granted) return false;

    return PrintBluetoothThermal.connect(macPrinterAddress: mac);
  }

  static Future<bool> printLines(List<String> lines) async {
    if (!await ensureConnected()) return false;

    for (final line in lines) {
      final ok = await PrintBluetoothThermal.writeString(
        printText: PrintTextSize(size: 2, text: '$line\n'),
      );
      if (!ok) return false;
    }

    await PrintBluetoothThermal.writeBytes(_paperCut);
    return true;
  }

  static Future<bool> openCashDrawer() async {
    if (!await ensureConnected()) return false;
    return PrintBluetoothThermal.writeBytes(_drawerPulse);
  }

  static Future<void> openDrawerIfConfigured({required bool isCashPayment}) async {
    if (!isCashPayment) return;
    if (!await PrinterPrefs.getOpenCashDrawerOnCash()) return;
    await openCashDrawer();
  }

  static Future<List<BluetoothInfo>> listPairedDevices() {
    return PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<bool> testPrint() async {
    return printLines([
      'EPOSOne',
      'Prueba de impresión',
      DateTime.now().toString().substring(0, 16),
    ]);
  }
}
