import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/connection_status.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';
import 'package:eposone/src/features/platform/domain/provisioning_config.dart';

/// Orquesta el Hito 1: registrar dispositivo, guardar token/IDs, estado de conexión.
///
/// Sync de productos/ventas permanece stub (Hito 2).
class En1ProvisioningRepository {
  En1ProvisioningRepository({En1ProvisioningApi? api}) : _api = api ?? En1ProvisioningApi();

  final En1ProvisioningApi _api;
  static const _appVersion = '1.0.0+1';

  Future<bool> isProvisioned() => ProvisioningStore.isProvisioned();

  Future<ProvisioningConfig?> getConfig() => ProvisioningStore.loadConfig();

  Future<ConnectionStatus> getStatus() => ProvisioningStore.getStatus();

  Future<String?> getLastError() => ProvisioningStore.getLastError();

  /// Registra el dispositivo en EN1 y persiste la configuración local.
  Future<ProvisioningConfig> provision({
    required String apiBaseUrl,
    required String activationCode,
  }) async {
    final code = activationCode.trim();
    if (code.isEmpty) {
      throw En1ProvisioningException('Código de activación requerido');
    }

    await ProvisioningStore.saveApiUrlDraft(apiBaseUrl);
    await ProvisioningStore.setStatus(ConnectionStatus.registering);

    try {
      final snapshot = await DeviceRegistry.snapshot(appVersion: _appVersion);
      final request = DeviceRegistrationRequest(
        uuid: snapshot.uuid,
        model: snapshot.model,
        os: snapshot.os,
        appVersion: snapshot.appVersion,
        activationCode: code,
      );

      final config = await _api.registerDevice(
        apiBaseUrl: apiBaseUrl,
        request: request,
      );

      await ProvisioningStore.saveConfig(config);
      await PlatformPrefs.completeOnboarding(PlatformMode.platform);
      return config;
    } catch (e) {
      final message = e is En1ProvisioningException ? e.message : e.toString();
      await ProvisioningStore.setStatus(ConnectionStatus.error, errorMessage: message);
      rethrow;
    }
  }

  /// Refresca configuración desde EN1 usando el token guardado.
  Future<ProvisioningConfig> refreshConfig() async {
    final current = await ProvisioningStore.loadConfig();
    if (current == null) {
      throw En1ProvisioningException('Dispositivo no provisionado');
    }
    await ProvisioningStore.setStatus(ConnectionStatus.registering);
    try {
      final updated = await _api.fetchConfig(
        apiBaseUrl: current.apiBaseUrl,
        accessToken: current.accessToken,
        deviceUuid: current.deviceUuid,
      );
      await ProvisioningStore.saveConfig(updated);
      return updated;
    } catch (e) {
      final message = e is En1ProvisioningException ? e.message : e.toString();
      await ProvisioningStore.setStatus(ConnectionStatus.error, errorMessage: message);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await ProvisioningStore.clearConfig();
  }
}
