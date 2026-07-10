/// Configuración local tras provisioning EN1 (contrato EN1-02).
///
/// El código de provisioning está asociado a una Caja en EN1.
/// La tablet solo envía URL + código; la jerarquía viene en la response.
class ProvisioningConfig {
  final String apiBaseUrl;
  final String accessToken;
  final String deviceUuid;
  final String? deviceName;
  final String? deviceStatus;
  final String organizationId;
  final String? organizationName;
  final String branchRef;
  final String? branchName;
  final String posRef;
  final String? posName;
  final String registerRef;
  final String? registerName;
  final int? configVersion;
  final String? businessName;
  final String? currency;
  final String? timezone;
  final DateTime provisionedAt;

  const ProvisioningConfig({
    required this.apiBaseUrl,
    required this.accessToken,
    required this.deviceUuid,
    this.deviceName,
    this.deviceStatus,
    required this.organizationId,
    this.organizationName,
    required this.branchRef,
    this.branchName,
    required this.posRef,
    this.posName,
    required this.registerRef,
    this.registerName,
    this.configVersion,
    this.businessName,
    this.currency,
    this.timezone,
    required this.provisionedAt,
  });

  /// Aliases de UI / BusinessConfig (misma semántica que antes).
  String get deviceId => deviceUuid;
  String get empresaId => organizationId;
  String get sucursalId => branchRef;
  String get posId => posRef;
  String get cajaId => registerRef;
  String? get empresaName => organizationName ?? businessName;
  String? get sucursalName => branchName;
  String? get cajaName => registerName;

  bool get isComplete =>
      apiBaseUrl.isNotEmpty &&
      accessToken.isNotEmpty &&
      deviceUuid.isNotEmpty &&
      organizationId.isNotEmpty &&
      branchRef.isNotEmpty &&
      posRef.isNotEmpty &&
      registerRef.isNotEmpty;

  ProvisioningConfig copyWith({
    String? apiBaseUrl,
    String? accessToken,
    String? deviceUuid,
    String? deviceName,
    String? deviceStatus,
    String? organizationId,
    String? organizationName,
    String? branchRef,
    String? branchName,
    String? posRef,
    String? posName,
    String? registerRef,
    String? registerName,
    int? configVersion,
    String? businessName,
    String? currency,
    String? timezone,
    DateTime? provisionedAt,
  }) {
    return ProvisioningConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      accessToken: accessToken ?? this.accessToken,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      deviceName: deviceName ?? this.deviceName,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      branchRef: branchRef ?? this.branchRef,
      branchName: branchName ?? this.branchName,
      posRef: posRef ?? this.posRef,
      posName: posName ?? this.posName,
      registerRef: registerRef ?? this.registerRef,
      registerName: registerName ?? this.registerName,
      configVersion: configVersion ?? this.configVersion,
      businessName: businessName ?? this.businessName,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      provisionedAt: provisionedAt ?? this.provisionedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiBaseUrl': apiBaseUrl,
        'accessToken': accessToken,
        'deviceUuid': deviceUuid,
        'deviceName': deviceName,
        'deviceStatus': deviceStatus,
        'organizationId': organizationId,
        'organizationName': organizationName,
        'branchRef': branchRef,
        'branchName': branchName,
        'posRef': posRef,
        'posName': posName,
        'registerRef': registerRef,
        'registerName': registerName,
        'configVersion': configVersion,
        'businessName': businessName,
        'currency': currency,
        'timezone': timezone,
        'provisionedAt': provisionedAt.toIso8601String(),
      };

  factory ProvisioningConfig.fromJson(Map<String, dynamic> json) {
    // EN1-02 (schema 2)
    final orgId = (json['organizationId'] as String?)?.trim() ?? '';
    if (orgId.isNotEmpty || json['branchRef'] != null) {
      return ProvisioningConfig(
        apiBaseUrl: (json['apiBaseUrl'] as String?)?.trim() ?? '',
        accessToken: (json['accessToken'] as String?)?.trim() ?? '',
        deviceUuid: (json['deviceUuid'] as String?)?.trim() ?? '',
        deviceName: json['deviceName'] as String?,
        deviceStatus: json['deviceStatus'] as String?,
        organizationId: orgId,
        organizationName: json['organizationName'] as String?,
        branchRef: (json['branchRef'] as String?)?.trim() ?? '',
        branchName: json['branchName'] as String?,
        posRef: (json['posRef'] as String?)?.trim() ?? '',
        posName: json['posName'] as String?,
        registerRef: (json['registerRef'] as String?)?.trim() ?? '',
        registerName: json['registerName'] as String?,
        configVersion: (json['configVersion'] as num?)?.toInt(),
        businessName: json['businessName'] as String?,
        currency: json['currency'] as String?,
        timezone: json['timezone'] as String?,
        provisionedAt:
            DateTime.tryParse(json['provisionedAt'] as String? ?? '') ??
                DateTime.now(),
      );
    }

    // Legacy v0.1 plano (solo lectura; isComplete fallará si incompleto)
    return ProvisioningConfig(
      apiBaseUrl: (json['apiBaseUrl'] as String?)?.trim() ?? '',
      accessToken: (json['accessToken'] as String?)?.trim() ?? '',
      deviceUuid: (json['deviceUuid'] as String?)?.trim() ?? '',
      organizationId: (json['empresaId'] as String?)?.trim() ?? '',
      organizationName: json['empresaName'] as String?,
      branchRef: (json['sucursalId'] as String?)?.trim() ?? '',
      branchName: json['sucursalName'] as String?,
      posRef: (json['posId'] as String?)?.trim() ?? '',
      posName: json['posName'] as String?,
      registerRef: (json['cajaId'] as String?)?.trim() ?? '',
      registerName: json['cajaName'] as String?,
      provisionedAt: DateTime.tryParse(json['provisionedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Request de registro — contrato EN1-02.
///
/// El código va solo en header `X-EN1-Provisioning-Code` (no en el body).
class DeviceRegistrationRequest {
  final String deviceUuid;
  final String deviceName;
  final String platform;
  final String? deviceModel;
  final String? androidVersion;
  final String appVersion;
  final String provisioningCode;

  const DeviceRegistrationRequest({
    required this.deviceUuid,
    required this.deviceName,
    required this.platform,
    this.deviceModel,
    this.androidVersion,
    required this.appVersion,
    required this.provisioningCode,
  });

  /// Body JSON — sin código ni refs de jerarquía.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'device_uuid': deviceUuid,
      'device_name': deviceName,
      'platform': platform,
      'app_version': appVersion,
    };
    final model = deviceModel?.trim();
    if (model != null && model.isNotEmpty) {
      map['device_model'] = model;
    }
    final android = androidVersion?.trim();
    if (android != null && android.isNotEmpty) {
      map['android_version'] = android;
    }
    return map;
  }
}
