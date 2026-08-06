import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/platform/data/en1_cashier_catalog_store.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/installation_lifecycle_store.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/connection_status.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recuperación cuando EN1 invalida el Device Token (401/403 / DEVICE_UNAUTHORIZED).
///
/// Limpia credenciales locales, conserva URL para reaprovisionar, fuerza Connect.
/// No inventa endpoints — usa EN1-02 register existente.
class En1DeviceAuthRecovery {
  En1DeviceAuthRecovery._();

  static const connectRoute = '/platform/connect?reprovision=1';

  static bool isUnauthorized(Object error) {
    if (error is En1ProvisioningException) {
      return error.kind == En1ProvisioningErrorKind.unauthorized ||
          error.statusCode == 401 ||
          error.statusCode == 403;
    }
    return false;
  }

  /// True si [deviceStatus] de config indica dispositivo revocado/inactivo.
  static bool isRevokedDeviceStatus(String? status) {
    if (status == null || status.trim().isEmpty) return false;
    final s = status.trim().toLowerCase();
    return s == 'revoked' ||
        s == 'revocada' ||
        s == 'disabled' ||
        s == 'inactive' ||
        s == 'inactivo' ||
        s == 'blocked' ||
        s == 'bloqueado' ||
        s == 'unauthorized';
  }

  /// Limpia token/config; deja modo plataforma + URL draft para Connect.
  static Future<void> clearCredentialsForReprovision({
    required String reason,
  }) async {
    final current = await ProvisioningStore.loadConfig();
    if (current != null && current.apiBaseUrl.isNotEmpty) {
      await ProvisioningStore.saveApiUrlDraft(current.apiBaseUrl);
    }
    await En1CashierCatalogStore.clearAll();
    await ProvisioningStore.clearConfig();
    await InstallationLifecycleStore.clear();
    await PlatformPrefs.completeOnboarding(PlatformMode.platform);
    await ProvisioningStore.setStatus(
      ConnectionStatus.error,
      errorMessage: reason,
    );
  }

  /// Ejecuta recovery + cierra sesión POS. Caller navega a [connectRoute].
  static Future<String> recoverAndLockSession(
    WidgetRef ref, {
    String reason =
        'Dispositivo no autorizado en EN1. Reaprovisiona con un código de Caja.',
  }) async {
    await clearCredentialsForReprovision(reason: reason);
    ref.read(posSessionProvider.notifier).logout();
    return connectRoute;
  }
}
