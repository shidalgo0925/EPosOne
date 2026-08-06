import 'package:eposone/src/features/licensing/domain/license_service.dart';
import 'package:eposone/src/features/platform/data/en1_device_auth_recovery.dart';
import 'package:eposone/src/features/platform/data/installation_lifecycle_store.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/installation_lifecycle_state.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';

/// Orquesta estados ADR-014 y el gate de operación del POS (modo integrado).
///
/// Standalone: no aplica gate de bootstrap remoto; se trata como operable.
class InstallationLifecycle {
  InstallationLifecycle._();

  /// True si el dispositivo puede entrar a PIN / caja / POS.
  static Future<bool> allowsPosOperation() async {
    final state = await evaluate();
    return state == InstallationLifecycleState.readyToOperate;
  }

  /// True cuando modo plataforma y aún no está listo (debe ir a bootstrap UI).
  static Future<bool> requiresBlockingBootstrap() async {
    final mode = await PlatformPrefs.getMode();
    final provisioned = await ProvisioningStore.isProvisioned();
    final isPlatform = mode == PlatformMode.platform || provisioned;
    if (!isPlatform) return false;
    return !(await allowsPosOperation());
  }

  /// Evalúa hechos locales + licencia; persiste el estado resultante.
  static Future<InstallationLifecycleState> evaluate() async {
    final mode = await PlatformPrefs.getMode();
    final provisioned = await ProvisioningStore.isProvisioned();

    // Standalone: sin gate EN1.
    if (!provisioned && mode != PlatformMode.platform) {
      final state = mode == PlatformMode.local
          ? InstallationLifecycleState.readyToOperate
          : InstallationLifecycleState.notProvisioned;
      await InstallationLifecycleStore.save(state);
      return state;
    }

    if (!provisioned) {
      await InstallationLifecycleStore.save(
        InstallationLifecycleState.notProvisioned,
      );
      return InstallationLifecycleState.notProvisioned;
    }

    final config = await ProvisioningStore.loadConfig();
    if (En1DeviceAuthRecovery.isRevokedDeviceStatus(config?.deviceStatus)) {
      await En1DeviceAuthRecovery.clearCredentialsForReprovision(
        reason:
            'Dispositivo revocado o inactivo en EN1 (${config?.deviceStatus}). '
            'Reaprovisiona con un código de Caja.',
      );
      await InstallationLifecycleStore.save(
        InstallationLifecycleState.notProvisioned,
      );
      return InstallationLifecycleState.notProvisioned;
    }

    final bootstrapDone = await InstallationLifecycleStore.isBootstrapDoneFlag();
    if (!bootstrapDone) {
      final stored = await InstallationLifecycleStore.loadStored();
      final next = stored == InstallationLifecycleState.bootstrapPending
          ? InstallationLifecycleState.bootstrapPending
          : InstallationLifecycleState.deviceRegistered;
      await InstallationLifecycleStore.save(next);
      return next;
    }

    final license = await LicenseService().validate();
    if (!license.canOperatePos) {
      await InstallationLifecycleStore.save(
        InstallationLifecycleState.bootstrapCompleted,
      );
      return InstallationLifecycleState.bootstrapCompleted;
    }

    await InstallationLifecycleStore.save(
      InstallationLifecycleState.readyToOperate,
    );
    return InstallationLifecycleState.readyToOperate;
  }

  static Future<void> onDeviceRegistered() async {
    await InstallationLifecycleStore.clearBootstrapDoneFlag();
    await InstallationLifecycleStore.save(
      InstallationLifecycleState.deviceRegistered,
    );
  }

  static Future<void> onBootstrapStarted() async {
    await InstallationLifecycleStore.save(
      InstallationLifecycleState.bootstrapPending,
    );
  }

  /// Tras bootstrap HTTP OK + persistencia. Luego [evaluate] aplica licencia.
  static Future<InstallationLifecycleState> onBootstrapPersisted() async {
    await InstallationLifecycleStore.save(
      InstallationLifecycleState.bootstrapCompleted,
    );
    return evaluate();
  }

  static Future<void> reset() async {
    await InstallationLifecycleStore.clear();
  }
}
