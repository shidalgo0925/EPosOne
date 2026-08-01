import 'package:shared_preferences/shared_preferences.dart';
import 'package:eposone/src/features/platform/domain/installation_lifecycle_state.dart';

/// Persistencia del estado de instalación (ADR-014). Fuera de Isar / POS Core.
class InstallationLifecycleStore {
  static const _stateKey = 'en1_installation_lifecycle_v1';
  static const _bootstrapDoneKey = 'en1_bootstrap_done_v1';

  static Future<InstallationLifecycleState?> loadStored() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null || raw.isEmpty) return null;
    return InstallationLifecycleStateX.fromStorage(raw);
  }

  static Future<void> save(InstallationLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, state.storageValue);
  }

  static Future<bool> isBootstrapDoneFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bootstrapDoneKey) == true;
  }

  /// Fuerza re-bootstrap tras register / reprovision (ADR-014).
  static Future<void> clearBootstrapDoneFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bootstrapDoneKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
    await prefs.remove(_bootstrapDoneKey);
  }
}
