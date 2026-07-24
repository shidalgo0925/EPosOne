import 'package:eposone/src/features/licensing/domain/license_enums.dart';
import 'package:eposone/src/features/licensing/domain/license_feature.dart';

/// Snapshot de licencia comercial (dueño = EN1). La APK no crea licencias comerciales.
class LicenseSnapshot {
  final String? id;
  final String? organizationId;
  final String? branchId;
  final String? posId;
  final String? registerId;

  final LicenseType licenseType;
  final LicenseStatus status;
  final String? planCode;
  final LicenseActivationMethod activationMethod;

  final DateTime? issuedAt;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final DateTime? graceUntil;
  final DateTime? lastValidation;

  /// Feature code → enabled. Ausente = false cuando hay snapshot.
  final Map<String, bool> features;

  final int? maxBranches;
  final int? maxPos;
  final int? maxRegisters;
  final int? maxDevices;
  final int? maxCashiers;
  final int? maxProducts;
  final int? maxUsers;

  final String? signature;
  final String? source;
  final DateTime updatedAt;

  const LicenseSnapshot({
    this.id,
    this.organizationId,
    this.branchId,
    this.posId,
    this.registerId,
    required this.licenseType,
    required this.status,
    this.planCode,
    this.activationMethod = LicenseActivationMethod.en1,
    this.issuedAt,
    this.startsAt,
    this.expiresAt,
    this.graceUntil,
    this.lastValidation,
    this.features = const {},
    this.maxBranches,
    this.maxPos,
    this.maxRegisters,
    this.maxDevices,
    this.maxCashiers,
    this.maxProducts,
    this.maxUsers,
    this.signature,
    this.source,
    required this.updatedAt,
  });

  bool featureEnabled(LicenseFeature feature) =>
      features[feature.code] == true;

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationId': organizationId,
        'branchId': branchId,
        'posId': posId,
        'registerId': registerId,
        'licenseType': licenseType.code,
        'status': status.code,
        'planCode': planCode,
        'activationMethod': activationMethod.code,
        'issuedAt': issuedAt?.toUtc().toIso8601String(),
        'startsAt': startsAt?.toUtc().toIso8601String(),
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'graceUntil': graceUntil?.toUtc().toIso8601String(),
        'lastValidation': lastValidation?.toUtc().toIso8601String(),
        'features': features,
        'limits': {
          if (maxBranches != null) 'maxBranches': maxBranches,
          if (maxPos != null) 'maxPOS': maxPos,
          if (maxRegisters != null) 'maxRegisters': maxRegisters,
          if (maxDevices != null) 'maxDevices': maxDevices,
          if (maxCashiers != null) 'maxCashiers': maxCashiers,
          if (maxProducts != null) 'maxProducts': maxProducts,
          if (maxUsers != null) 'maxUsers': maxUsers,
        },
        'signature': signature,
        'source': source,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory LicenseSnapshot.fromJson(Map<String, dynamic> json) {
    DateTime? dt(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v.toUtc();
      return DateTime.tryParse(v.toString())?.toUtc();
    }

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final limitsRaw = json['limits'];
    final limits = limitsRaw is Map
        ? Map<String, dynamic>.from(limitsRaw)
        : <String, dynamic>{};

    return LicenseSnapshot(
      id: json['id']?.toString(),
      organizationId:
          (json['organizationId'] ?? json['organization_id'])?.toString(),
      branchId: (json['branchId'] ?? json['branch_id'])?.toString(),
      posId: (json['posId'] ?? json['pos_id'])?.toString(),
      registerId: (json['registerId'] ?? json['register_id'] ?? json['caja_id'])
          ?.toString(),
      licenseType: LicenseTypeX.parse(
          (json['licenseType'] ?? json['type'] ?? json['license_type'])
              ?.toString()),
      status: LicenseStatusX.parse((json['status'])?.toString()),
      planCode: (json['planCode'] ?? json['plan'] ?? json['plan_code'])
          ?.toString(),
      activationMethod: LicenseActivationMethodX.parse(
          (json['activationMethod'] ?? json['activation_method'])?.toString()),
      issuedAt: dt(json['issuedAt'] ?? json['issued_at']),
      startsAt: dt(json['startsAt'] ?? json['starts_at']),
      expiresAt: dt(json['expiresAt'] ?? json['expires_at']),
      graceUntil: dt(json['graceUntil'] ?? json['grace_until']),
      lastValidation: dt(json['lastValidation'] ?? json['last_validation']),
      features: _parseFeatures(json['features']),
      maxBranches: asInt(limits['maxBranches'] ?? limits['max_branches']),
      maxPos: asInt(limits['maxPOS'] ?? limits['max_pos'] ?? limits['maxPos']),
      maxRegisters: asInt(limits['maxRegisters'] ?? limits['max_registers']),
      maxDevices: asInt(limits['maxDevices'] ?? limits['max_devices']),
      maxCashiers: asInt(limits['maxCashiers'] ?? limits['max_cashiers']),
      maxProducts: asInt(limits['maxProducts'] ?? limits['max_products']),
      maxUsers: asInt(limits['maxUsers'] ?? limits['max_users']),
      signature: json['signature']?.toString(),
      source: json['source']?.toString(),
      updatedAt: dt(json['updatedAt'] ?? json['updated_at']) ??
          DateTime.now().toUtc(),
    );
  }

  static Map<String, bool> _parseFeatures(dynamic raw) {
    final out = <String, bool>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final key = k.toString().trim().toLowerCase().replaceAll('-', '_');
        if (key.isEmpty) return;
        out[key] = v == true || v == 1 || '$v'.toLowerCase() == 'true';
      });
      return out;
    }
    if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          final key = item.trim().toLowerCase().replaceAll('-', '_');
          if (key.isNotEmpty) out[key] = true;
        } else if (item is Map) {
          final code = (item['code'] ?? item['feature'] ?? item['name'])
              ?.toString()
              .trim()
              .toLowerCase()
              .replaceAll('-', '_');
          if (code == null || code.isEmpty) continue;
          final enabled = item['enabled'] ?? item['active'] ?? true;
          out[code] =
              enabled == true || enabled == 1 || '$enabled'.toLowerCase() == 'true';
        }
      }
    }
    return out;
  }

  LicenseSnapshot copyWith({
    LicenseStatus? status,
    DateTime? lastValidation,
    DateTime? updatedAt,
    Map<String, bool>? features,
  }) =>
      LicenseSnapshot(
        id: id,
        organizationId: organizationId,
        branchId: branchId,
        posId: posId,
        registerId: registerId,
        licenseType: licenseType,
        status: status ?? this.status,
        planCode: planCode,
        activationMethod: activationMethod,
        issuedAt: issuedAt,
        startsAt: startsAt,
        expiresAt: expiresAt,
        graceUntil: graceUntil,
        lastValidation: lastValidation ?? this.lastValidation,
        features: features ?? this.features,
        maxBranches: maxBranches,
        maxPos: maxPos,
        maxRegisters: maxRegisters,
        maxDevices: maxDevices,
        maxCashiers: maxCashiers,
        maxProducts: maxProducts,
        maxUsers: maxUsers,
        signature: signature,
        source: source,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
