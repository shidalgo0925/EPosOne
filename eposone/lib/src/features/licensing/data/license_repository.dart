import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eposone/src/features/licensing/domain/license_snapshot.dart';

/// Persistencia local offline-first del snapshot de licencia (fuera de Isar).
class LicenseRepository {
  static const _key = 'eposone_license_snapshot_v1';
  static const schemaVersion = 1;

  Future<LicenseSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LicenseSnapshot.fromJson(map);
    } catch (e) {
      debugPrint('[License] load failed: $e');
      return null;
    }
  }

  Future<void> save(LicenseSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final map = snapshot.toJson();
    map['schemaVersion'] = schemaVersion;
    await prefs.setString(_key, jsonEncode(map));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
