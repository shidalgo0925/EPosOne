import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Registro local del dispositivo (capa Plataforma).
///
/// Genera y conserva un UUID estable para auditoría, colas e idempotencia.
/// No altera el flujo del cajero.
class DeviceRegistry {
  static const _uuidKey = 'device_uuid';
  static const _registeredAtKey = 'device_registered_at';

  static Future<String> getOrCreateUuid() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_uuidKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final uuid = const Uuid().v4();
    await prefs.setString(_uuidKey, uuid);
    await prefs.setString(_registeredAtKey, DateTime.now().toIso8601String());
    return uuid;
  }

  static Future<DateTime?> getRegisteredAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_registeredAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<DeviceSnapshot> snapshot({
    required String appVersion,
  }) async {
    final uuid = await getOrCreateUuid();
    final registeredAt = await getRegisteredAt();
    return DeviceSnapshot(
      uuid: uuid,
      model: _deviceModel(),
      os: _osLabel(),
      platform: _platform(),
      androidVersion: _androidVersion(),
      deviceName: _deviceName(uuid),
      appVersion: appVersion,
      registeredAt: registeredAt,
    );
  }

  static String _deviceName(String uuid) {
    final short = uuid.length >= 8 ? uuid.substring(0, 8) : uuid;
    return 'EPosOne-$short';
  }

  static String _platform() {
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isWindows) return 'windows';
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  static String? _androidVersion() {
    try {
      if (!Platform.isAndroid) return null;
      // Ej. "Android 13 (…)" o raw version string
      final raw = Platform.operatingSystemVersion.trim();
      final match = RegExp(r'(\d+(\.\d+)*)').firstMatch(raw);
      return match?.group(1) ?? raw;
    } catch (_) {
      return null;
    }
  }

  static String _deviceModel() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Desconocido';
    }
  }

  static String _osLabel() {
    try {
      if (Platform.isAndroid) return 'Android ${Platform.operatingSystemVersion}';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isIOS) return 'iOS';
      return Platform.operatingSystem;
    } catch (_) {
      return 'Desconocido';
    }
  }
}

class DeviceSnapshot {
  final String uuid;
  final String model;
  final String os;
  final String platform;
  final String? androidVersion;
  final String deviceName;
  final String appVersion;
  final DateTime? registeredAt;

  const DeviceSnapshot({
    required this.uuid,
    required this.model,
    required this.os,
    required this.platform,
    this.androidVersion,
    required this.deviceName,
    required this.appVersion,
    this.registeredAt,
  });
}
