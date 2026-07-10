import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/connection_status.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';
import 'package:eposone/src/features/platform/domain/provisioning_config.dart';

/// Orquesta provisioning EN1-02: registrar dispositivo, guardar token/config, estado.
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

  /// Registra (o reprovisiona) el dispositivo. Solo URL + código de provisioning.
  Future<ProvisioningConfig> provision({
    required String apiBaseUrl,
    required String provisioningCode,
  }) async {
    final code = provisioningCode.trim();
    if (code.isEmpty) {
      throw En1ProvisioningException(
        userMessage: 'Código de provisioning requerido.',
        technicalDetail: 'Empty provisioningCode',
        kind: En1ProvisioningErrorKind.validation,
      );
    }

    await ProvisioningStore.saveApiUrlDraft(apiBaseUrl);
    await ProvisioningStore.setStatus(ConnectionStatus.registering);

    try {
      final snapshot = await DeviceRegistry.snapshot(appVersion: _appVersion);
      final request = DeviceRegistrationRequest(
        deviceUuid: snapshot.uuid,
        deviceName: snapshot.deviceName,
        platform: snapshot.platform,
        deviceModel: snapshot.model,
        androidVersion: snapshot.androidVersion,
        appVersion: snapshot.appVersion,
        provisioningCode: code,
      );

      final config = await _api.registerDevice(
        apiBaseUrl: apiBaseUrl,
        request: request,
      );

      // Reprovision: siempre persiste el nuevo token (el anterior deja de valer).
      await ProvisioningStore.saveConfig(config);
      await PlatformPrefs.completeOnboarding(PlatformMode.platform);
      return config;
    } catch (e) {
      if (e is En1ProvisioningException) {
        await ProvisioningStore.setStatus(
          ConnectionStatus.error,
          errorMessage: e.userMessage,
        );
      } else {
        await ProvisioningStore.setStatus(
          ConnectionStatus.error,
          errorMessage: 'No se pudo conectar con EasyNodeOne. Intenta de nuevo.',
        );
      }
      rethrow;
    }
  }

  /// Refresca configuración desde EN1 con el token guardado.
  Future<ProvisioningConfig> refreshConfig() async {
    final current = await ProvisioningStore.loadConfig();
    if (current == null) {
      throw En1ProvisioningException(
        userMessage: 'Dispositivo no provisionado.',
        technicalDetail: 'refreshConfig without local config',
        kind: En1ProvisioningErrorKind.validation,
      );
    }
    await ProvisioningStore.setStatus(ConnectionStatus.registering);
    try {
      final updated = await _api.fetchConfig(
        apiBaseUrl: current.apiBaseUrl,
        accessToken: current.accessToken,
        deviceUuid: current.deviceUuid,
        previous: current,
      );
      await ProvisioningStore.saveConfig(updated);
      return updated;
    } catch (e) {
      if (e is En1ProvisioningException) {
        await ProvisioningStore.setStatus(
          ConnectionStatus.error,
          errorMessage: e.userMessage,
        );
      } else {
        await ProvisioningStore.setStatus(
          ConnectionStatus.error,
          errorMessage: 'No se pudo actualizar la configuración desde EN1.',
        );
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await ProvisioningStore.clearConfig();
  }
}
