import 'package:shared_preferences/shared_preferences.dart';

/// Canal de salida térmica.
enum PrinterChannel {
  bluetooth,
  network,
}

/// Preferencias locales de impresora — BT y/o red (TCP ESC/POS).
class PrinterPrefs {
  static const _macKey = 'thermal_printer_mac';
  static const _nameKey = 'thermal_printer_name';
  static const _drawerKey = 'open_cash_drawer_on_cash';
  static const _channelKey = 'printer_channel';
  static const _hostKey = 'network_printer_host';
  static const _portKey = 'network_printer_port';
  static const _logoThermalKey = 'print_logo_on_thermal';

  static const defaultNetworkPort = 9100;

  static Future<PrinterChannel> getChannel() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_channelKey);
    if (raw == PrinterChannel.network.name) return PrinterChannel.network;
    return PrinterChannel.bluetooth;
  }

  static Future<void> setChannel(PrinterChannel channel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_channelKey, channel.name);
  }

  static Future<String?> getPrinterMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_macKey);
  }

  static Future<String?> getPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<bool> getOpenCashDrawerOnCash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_drawerKey) ?? false;
  }

  static Future<void> savePrinter({required String mac, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_macKey, mac);
    await prefs.setString(_nameKey, name);
  }

  static Future<void> clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_macKey);
    await prefs.remove(_nameKey);
  }

  static Future<String?> getNetworkHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hostKey);
  }

  static Future<int> getNetworkPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_portKey) ?? defaultNetworkPort;
  }

  static Future<void> saveNetworkPrinter({
    required String host,
    int port = defaultNetworkPort,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host.trim());
    await prefs.setInt(_portKey, port);
  }

  static Future<void> clearNetworkPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hostKey);
    await prefs.remove(_portKey);
  }

  static Future<void> setOpenCashDrawerOnCash(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_drawerKey, value);
  }

  /// Preferencia: logo en térmica (raster ESC/POS). Default on.
  /// PDF / preview siempre incluyen logo si existe.
  static Future<bool> getPrintLogoOnThermal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_logoThermalKey) ?? true;
  }

  static Future<void> setPrintLogoOnThermal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_logoThermalKey, value);
  }
}
