import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias locales de impresora (L5) — sin migración Isar.
class PrinterPrefs {
  static const _macKey = 'thermal_printer_mac';
  static const _nameKey = 'thermal_printer_name';
  static const _drawerKey = 'open_cash_drawer_on_cash';

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

  static Future<void> setOpenCashDrawerOnCash(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_drawerKey, value);
  }
}
