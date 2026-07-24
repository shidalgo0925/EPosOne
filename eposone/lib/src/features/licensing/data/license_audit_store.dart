import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';

/// Auditoría local de eventos de licencia (ring buffer).
class LicenseAuditStore {
  static const _key = 'eposone_license_events_v1';
  static const _max = 80;

  static Future<void> record(String event, {Map<String, dynamic>? meta}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = <Map<String, dynamic>>[];
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(Map<String, dynamic>.from(e));
          }
        }
      } catch (_) {}
    }
    list.insert(0, {
      'event': event,
      'at': En1DateTimeService.toUtcIso(En1DateTimeService.nowUtc()),
      if (meta != null) 'meta': meta,
    });
    while (list.length > _max) {
      list.removeLast();
    }
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> recent({int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .take(limit)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
