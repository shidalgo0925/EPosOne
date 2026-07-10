import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eposone/src/features/platform/domain/connection_status.dart';
import 'package:eposone/src/features/platform/domain/provisioning_config.dart';

/// Persistencia local del provisioning (SharedPreferences — fuera del POS Core / Isar).
///
/// Versionado EN1-02:
/// - Clave: [_configKeyV1] (misma clave; schemaVersion = 2)
/// - v1 (contrato plano) no es migrable → se limpia para forzar re-provision
class ProvisioningStore {
  static const currentSchemaVersion = 2;

  static const _configKeyV1 = 'en1_provisioning_config_v1';

  static const _statusKey = 'en1_connection_status_v1';
  static const _errorKey = 'en1_connection_error_v1';
  static const _apiUrlDraftKey = 'en1_api_url_draft_v1';

  /// Ejecutar al arranque / antes de leer config.
  static Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKeyV1);
    if (raw == null || raw.isEmpty) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final version = (map['schemaVersion'] as num?)?.toInt() ?? 1;

      if (version == currentSchemaVersion) {
        if (map['schemaVersion'] == null) {
          map['schemaVersion'] = currentSchemaVersion;
          await prefs.setString(_configKeyV1, jsonEncode(map));
        }
        return;
      }

      if (version < currentSchemaVersion) {
        // v0.1 → EN1-02: modelo incompatible; limpiar y re-provisionar.
        debugPrint(
          '[EN1 Provisioning] store: clearing schema v$version → require EN1-02 re-provision',
        );
        await prefs.remove(_configKeyV1);
        await prefs.setString(_statusKey, ConnectionStatus.notConfigured.storageValue);
        await prefs.remove(_errorKey);
        return;
      }

      debugPrint(
        '[EN1 Provisioning] store: schemaVersion=$version '
        '(current=$currentSchemaVersion) — sin migración aplicada',
      );
    } catch (e) {
      debugPrint('[EN1 Provisioning] store migrateIfNeeded failed: $e');
    }
  }

  static Future<ProvisioningConfig?> loadConfig() async {
    await migrateIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKeyV1);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final config = ProvisioningConfig.fromJson(map);
      return config.isComplete ? config : null;
    } catch (e) {
      debugPrint('[EN1 Provisioning] store loadConfig failed: $e');
      return null;
    }
  }

  static Future<void> saveConfig(ProvisioningConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final map = config.toJson();
    map['schemaVersion'] = currentSchemaVersion;
    await prefs.setString(_configKeyV1, jsonEncode(map));
    await prefs.setString(_statusKey, ConnectionStatus.connected.storageValue);
    await prefs.remove(_errorKey);
  }

  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKeyV1);
    await prefs.setString(_statusKey, ConnectionStatus.notConfigured.storageValue);
    await prefs.remove(_errorKey);
  }

  static Future<bool> isProvisioned() async {
    final config = await loadConfig();
    return config?.isComplete == true;
  }

  static Future<ConnectionStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (await isProvisioned()) return ConnectionStatus.connected;
    return ConnectionStatusX.fromStorage(prefs.getString(_statusKey));
  }

  static Future<void> setStatus(ConnectionStatus status, {String? errorMessage}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, status.storageValue);
    if (errorMessage != null && errorMessage.isNotEmpty) {
      await prefs.setString(_errorKey, errorMessage);
    } else if (status != ConnectionStatus.error) {
      await prefs.remove(_errorKey);
    }
  }

  static Future<String?> getLastError() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_errorKey);
  }

  static Future<void> saveApiUrlDraft(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlDraftKey, url.trim());
  }

  static Future<String?> getApiUrlDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiUrlDraftKey);
  }
}
