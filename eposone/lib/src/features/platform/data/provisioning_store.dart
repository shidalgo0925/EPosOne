import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:eposone/src/features/platform/domain/connection_status.dart';
import 'package:eposone/src/features/platform/domain/provisioning_config.dart';

/// Persistencia local del provisioning (SharedPreferences — fuera del POS Core / Isar).
class ProvisioningStore {
  static const _configKey = 'en1_provisioning_config_v1';
  static const _statusKey = 'en1_connection_status_v1';
  static const _errorKey = 'en1_connection_error_v1';
  static const _apiUrlDraftKey = 'en1_api_url_draft_v1';

  static Future<ProvisioningConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final config = ProvisioningConfig.fromJson(map);
      return config.isComplete ? config : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveConfig(ProvisioningConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
    await prefs.setString(_statusKey, ConnectionStatus.connected.storageValue);
    await prefs.remove(_errorKey);
  }

  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
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
