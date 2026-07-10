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
      appVersion: appVersion,
      registeredAt: registeredAt,
    );
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
  final String appVersion;
  final DateTime? registeredAt;

  const DeviceSnapshot({
    required this.uuid,
    required this.model,
    required this.os,
    required this.appVersion,
    this.registeredAt,
  });
}
