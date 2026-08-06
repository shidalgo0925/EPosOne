/// Modelos sesión onboarding (User Bearer) — GATE1_HTTP_FROZEN_FOR_LOCAL.md
class OnboardingLoginResult {
  const OnboardingLoginResult({
    required this.accessToken,
    required this.expiresIn,
    required this.session,
  });

  final String accessToken;
  final int expiresIn;
  final OnboardingSession session;

  factory OnboardingLoginResult.fromJson(Map<String, dynamic> json) {
    final sessionRaw = json['session'];
    if (sessionRaw is! Map) {
      throw const FormatException('login response missing session');
    }
    return OnboardingLoginResult(
      accessToken: json['access_token']?.toString() ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      session: OnboardingSession.fromJson(
        Map<String, dynamic>.from(sessionRaw),
      ),
    );
  }
}

class OnboardingSession {
  const OnboardingSession({
    required this.userId,
    required this.email,
    this.fullName,
    required this.organizationCount,
    this.selectedOrganizationId,
    required this.nextAction,
    required this.organizations,
  });

  final int userId;
  final String email;
  final String? fullName;
  final int organizationCount;
  final int? selectedOrganizationId;
  final String nextAction;
  final List<OnboardingOrganization> organizations;

  factory OnboardingSession.fromJson(Map<String, dynamic> json) {
    final orgs = <OnboardingOrganization>[];
    final rawOrgs = json['organizations'];
    if (rawOrgs is List) {
      for (final o in rawOrgs) {
        if (o is Map) {
          orgs.add(
            OnboardingOrganization.fromJson(Map<String, dynamic>.from(o)),
          );
        }
      }
    }
    return OnboardingSession(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      organizationCount: (json['organization_count'] as num?)?.toInt() ?? orgs.length,
      selectedOrganizationId: (json['selected_organization_id'] as num?)?.toInt(),
      nextAction: json['next_action']?.toString() ?? 'select_organization',
      organizations: orgs,
    );
  }
}

class OnboardingOrganization {
  const OnboardingOrganization({
    required this.organizationId,
    required this.name,
    required this.canIssueProvisioningCode,
    required this.modality,
    required this.planCode,
    required this.registers,
    required this.devices,
    this.subscriptionEntitled = true,
  });

  final int organizationId;
  final String name;
  final bool canIssueProvisioningCode;
  final String modality;
  final String planCode;
  final List<OnboardingRegister> registers;
  final List<OnboardingDevice> devices;
  final bool subscriptionEntitled;

  factory OnboardingOrganization.fromJson(Map<String, dynamic> json) {
    final registers = <OnboardingRegister>[];
    final rawRegs = json['registers'];
    if (rawRegs is List) {
      for (final r in rawRegs) {
        if (r is Map) {
          registers.add(
            OnboardingRegister.fromJson(Map<String, dynamic>.from(r)),
          );
        }
      }
    }
    final devices = <OnboardingDevice>[];
    final rawDevs = json['devices'];
    if (rawDevs is List) {
      for (final d in rawDevs) {
        if (d is Map) {
          devices.add(OnboardingDevice.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }
    final sub = json['subscription'];
    var entitled = true;
    if (sub is Map) {
      entitled = sub['entitled'] != false;
    }
    final commercial = json['commercial'];
    var modality = json['modality']?.toString() ?? 'standalone';
    if (commercial is Map && commercial['modality'] != null) {
      modality = commercial['modality'].toString();
    }
    return OnboardingOrganization(
      organizationId: (json['organization_id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Organización',
      canIssueProvisioningCode: json['can_issue_provisioning_code'] == true,
      modality: modality,
      planCode: json['plan_code']?.toString() ?? '',
      registers: registers,
      devices: devices,
      subscriptionEntitled: entitled,
    );
  }
}

class OnboardingRegister {
  const OnboardingRegister({
    required this.registerRef,
    required this.name,
    this.posRef,
    this.branchRef,
    this.hasActiveCode = false,
    this.activeProvisioningCode,
    this.activeCodeExpiresAt,
  });

  final String registerRef;
  final String name;
  final String? posRef;
  final String? branchRef;
  final bool hasActiveCode;
  final String? activeProvisioningCode;
  final String? activeCodeExpiresAt;

  factory OnboardingRegister.fromJson(Map<String, dynamic> json) =>
      OnboardingRegister(
        registerRef: json['register_ref']?.toString() ?? '',
        name: json['name']?.toString() ?? json['register_ref']?.toString() ?? '',
        posRef: json['pos_ref']?.toString(),
        branchRef: json['branch_ref']?.toString(),
        hasActiveCode: json['has_active_code'] == true,
        activeProvisioningCode: json['active_provisioning_code']?.toString(),
        activeCodeExpiresAt: json['active_code_expires_at']?.toString(),
      );
}

class OnboardingDevice {
  const OnboardingDevice({
    required this.deviceUuid,
    this.deviceLabel,
    this.status,
    this.registerRef,
  });

  final String deviceUuid;
  final String? deviceLabel;
  final String? status;
  final String? registerRef;

  factory OnboardingDevice.fromJson(Map<String, dynamic> json) =>
      OnboardingDevice(
        deviceUuid: json['device_uuid']?.toString() ?? '',
        deviceLabel: json['device_label']?.toString(),
        status: json['status']?.toString(),
        registerRef: json['register_ref']?.toString(),
      );
}

class OnboardingIssuedCode {
  const OnboardingIssuedCode({
    required this.organizationId,
    required this.registerRef,
    required this.code,
    this.expiresAt,
    this.status,
  });

  final int organizationId;
  final String registerRef;
  final String code;
  final String? expiresAt;
  final String? status;

  factory OnboardingIssuedCode.fromJson(Map<String, dynamic> json) =>
      OnboardingIssuedCode(
        organizationId: (json['organization_id'] as num?)?.toInt() ?? 0,
        registerRef: json['register_ref']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        expiresAt: json['expires_at']?.toString(),
        status: json['status']?.toString(),
      );
}

/// Extrae código de provisioning desde QR (string puro o deep link).
String? extractProvisioningCodeFromScan(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final uri = Uri.tryParse(t);
  if (uri != null &&
      (uri.scheme == 'eposone' || t.contains('provision')) &&
      uri.queryParameters['code'] != null) {
    final c = uri.queryParameters['code']!.trim();
    return c.isEmpty ? null : c;
  }
  // Código plano (contrato: QR = solo el string del code).
  if (t.contains('://')) return null;
  return t;
}
