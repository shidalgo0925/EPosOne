/// Configuración local tras provisioning EN1 (Hito 1).
///
/// Contrato cliente v0.1 — alineado con lo que EN1 debe publicar.
/// Sync de catálogo/ventas queda fuera de este modelo (Hito 2+).
class ProvisioningConfig {
  final String apiBaseUrl;
  final String accessToken;
  final String deviceUuid;
  final String deviceId;
  final String empresaId;
  final String sucursalId;
  final String posId;
  final String cajaId;
  final String? empresaName;
  final String? sucursalName;
  final String? posName;
  final String? cajaName;
  final DateTime provisionedAt;

  const ProvisioningConfig({
    required this.apiBaseUrl,
    required this.accessToken,
    required this.deviceUuid,
    required this.deviceId,
    required this.empresaId,
    required this.sucursalId,
    required this.posId,
    required this.cajaId,
    this.empresaName,
    this.sucursalName,
    this.posName,
    this.cajaName,
    required this.provisionedAt,
  });

  bool get isComplete =>
      apiBaseUrl.isNotEmpty &&
      accessToken.isNotEmpty &&
      deviceId.isNotEmpty &&
      empresaId.isNotEmpty &&
      sucursalId.isNotEmpty &&
      posId.isNotEmpty &&
      cajaId.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'apiBaseUrl': apiBaseUrl,
        'accessToken': accessToken,
        'deviceUuid': deviceUuid,
        'deviceId': deviceId,
        'empresaId': empresaId,
        'sucursalId': sucursalId,
        'posId': posId,
        'cajaId': cajaId,
        'empresaName': empresaName,
        'sucursalName': sucursalName,
        'posName': posName,
        'cajaName': cajaName,
        'provisionedAt': provisionedAt.toIso8601String(),
      };

  factory ProvisioningConfig.fromJson(Map<String, dynamic> json) {
    return ProvisioningConfig(
      apiBaseUrl: (json['apiBaseUrl'] as String?)?.trim() ?? '',
      accessToken: (json['accessToken'] as String?)?.trim() ?? '',
      deviceUuid: (json['deviceUuid'] as String?)?.trim() ?? '',
      deviceId: (json['deviceId'] as String?)?.trim() ?? '',
      empresaId: (json['empresaId'] as String?)?.trim() ?? '',
      sucursalId: (json['sucursalId'] as String?)?.trim() ?? '',
      posId: (json['posId'] as String?)?.trim() ?? '',
      cajaId: (json['cajaId'] as String?)?.trim() ?? '',
      empresaName: json['empresaName'] as String?,
      sucursalName: json['sucursalName'] as String?,
      posName: json['posName'] as String?,
      cajaName: json['cajaName'] as String?,
      provisionedAt: DateTime.tryParse(json['provisionedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Request de registro de dispositivo (contrato v0.1).
class DeviceRegistrationRequest {
  final String uuid;
  final String model;
  final String os;
  final String appVersion;
  final String activationCode;

  const DeviceRegistrationRequest({
    required this.uuid,
    required this.model,
    required this.os,
    required this.appVersion,
    required this.activationCode,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'model': model,
        'os': os,
        'app_version': appVersion,
        'activation_code': activationCode,
      };
}
