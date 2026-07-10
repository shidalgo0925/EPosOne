import 'package:shared_preferences/shared_preferences.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';

/// Preferencias de la capa Plataforma (fuera del POS Core / Isar).
///
/// El wizard de bienvenida se muestra una sola vez. Instalaciones ya
/// configuradas se marcan automáticamente como completadas.
class PlatformPrefs {
  static const _onboardingDoneKey = 'platform_onboarding_done';
  static const _modeKey = 'platform_mode';

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  static Future<PlatformMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return PlatformModeX.fromStorage(prefs.getString(_modeKey));
  }

  static Future<void> completeOnboarding(PlatformMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
    await prefs.setString(_modeKey, mode.storageValue);
  }

  /// Migración silenciosa: negocio ya operativo → no mostrar wizard.
  static Future<void> markCompletedForExistingInstall() async {
    await completeOnboarding(PlatformMode.local);
  }
}
