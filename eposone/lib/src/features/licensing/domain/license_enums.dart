enum LicenseType {
  trial,
  monthly,
  annual,
  perpetual,
  partner,
  oem,
  internal,
  educational,
  unknown,
}

enum LicenseStatus {
  active,
  grace,
  expired,
  suspended,
  revoked,
  pending,
  unknown,
}

enum LicenseActivationMethod {
  en1,
  signedFile,
  activationCode,
  factory,
  unknown,
}

extension LicenseTypeX on LicenseType {
  String get code => switch (this) {
        LicenseType.trial => 'TRIAL',
        LicenseType.monthly => 'MONTHLY',
        LicenseType.annual => 'ANNUAL',
        LicenseType.perpetual => 'PERPETUAL',
        LicenseType.partner => 'PARTNER',
        LicenseType.oem => 'OEM',
        LicenseType.internal => 'INTERNAL',
        LicenseType.educational => 'EDUCATIONAL',
        LicenseType.unknown => 'UNKNOWN',
      };

  String get label => switch (this) {
        LicenseType.trial => 'Trial',
        LicenseType.monthly => 'Mensual',
        LicenseType.annual => 'Anual',
        LicenseType.perpetual => 'Perpetua',
        LicenseType.partner => 'Partner',
        LicenseType.oem => 'OEM',
        LicenseType.internal => 'Interna',
        LicenseType.educational => 'Educativa',
        LicenseType.unknown => 'Desconocido',
      };

  static LicenseType parse(String? raw) {
    final k = (raw ?? '').trim().toUpperCase();
    return switch (k) {
      'TRIAL' || 'DEMO' => LicenseType.trial,
      'MONTHLY' || 'MENSUAL' => LicenseType.monthly,
      'ANNUAL' || 'YEARLY' || 'ANUAL' => LicenseType.annual,
      'PERPETUAL' || 'PERPETUA' => LicenseType.perpetual,
      'PARTNER' => LicenseType.partner,
      'OEM' => LicenseType.oem,
      'INTERNAL' || 'INTERNA' => LicenseType.internal,
      'EDUCATIONAL' || 'EDUCATIVA' => LicenseType.educational,
      _ => LicenseType.unknown,
    };
  }
}

extension LicenseStatusX on LicenseStatus {
  String get code => switch (this) {
        LicenseStatus.active => 'ACTIVE',
        LicenseStatus.grace => 'GRACE',
        LicenseStatus.expired => 'EXPIRED',
        LicenseStatus.suspended => 'SUSPENDED',
        LicenseStatus.revoked => 'REVOKED',
        LicenseStatus.pending => 'PENDING',
        LicenseStatus.unknown => 'UNKNOWN',
      };

  String get label => switch (this) {
        LicenseStatus.active => 'Activa',
        LicenseStatus.grace => 'Gracia',
        LicenseStatus.expired => 'Vencida',
        LicenseStatus.suspended => 'Suspendida',
        LicenseStatus.revoked => 'Revocada',
        LicenseStatus.pending => 'Pendiente',
        LicenseStatus.unknown => 'Desconocido',
      };

  static LicenseStatus parse(String? raw) {
    final k = (raw ?? '').trim().toUpperCase();
    return switch (k) {
      'ACTIVE' || 'ACTIVA' => LicenseStatus.active,
      'GRACE' || 'GRACIA' => LicenseStatus.grace,
      'EXPIRED' || 'VENCIDA' => LicenseStatus.expired,
      'SUSPENDED' || 'SUSPENDIDA' => LicenseStatus.suspended,
      'REVOKED' || 'REVOCADA' => LicenseStatus.revoked,
      'PENDING' || 'PENDIENTE' => LicenseStatus.pending,
      _ => LicenseStatus.unknown,
    };
  }
}

extension LicenseActivationMethodX on LicenseActivationMethod {
  String get code => switch (this) {
        LicenseActivationMethod.en1 => 'EN1',
        LicenseActivationMethod.signedFile => 'SIGNED_FILE',
        LicenseActivationMethod.activationCode => 'ACTIVATION_CODE',
        LicenseActivationMethod.factory => 'FACTORY',
        LicenseActivationMethod.unknown => 'UNKNOWN',
      };

  static LicenseActivationMethod parse(String? raw) {
    final k = (raw ?? '').trim().toUpperCase();
    return switch (k) {
      'EN1' || 'TOKEN_EN1' || 'BOOTSTRAP' => LicenseActivationMethod.en1,
      'SIGNED_FILE' || 'FILE' || 'LICENSE_FILE' =>
        LicenseActivationMethod.signedFile,
      'ACTIVATION_CODE' || 'CODE' => LicenseActivationMethod.activationCode,
      'FACTORY' || 'OEM' => LicenseActivationMethod.factory,
      _ => LicenseActivationMethod.unknown,
    };
  }
}
