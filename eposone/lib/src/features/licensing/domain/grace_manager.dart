import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/licensing/domain/license_enums.dart';
import 'package:eposone/src/features/licensing/domain/license_snapshot.dart';

/// Política de gracia offline / vencimiento (configurable por tipo).
class GraceManager {
  const GraceManager({
    this.trialGraceDays = 0,
    this.monthlyGraceDays = 30,
    this.annualGraceDays = 30,
    this.offlineValidationDays = 30,
  });

  final int trialGraceDays;
  final int monthlyGraceDays;
  final int annualGraceDays;

  /// Días máximos desde [lastValidation] sin contacto EN1 (ADR-007).
  final int offlineValidationDays;

  int graceDaysFor(LicenseType type) => switch (type) {
        LicenseType.trial => trialGraceDays,
        LicenseType.monthly => monthlyGraceDays,
        LicenseType.annual => annualGraceDays,
        LicenseType.perpetual => -1, // sin límite de gracia comercial
        LicenseType.partner ||
        LicenseType.oem ||
        LicenseType.internal ||
        LicenseType.educational =>
          monthlyGraceDays,
        LicenseType.unknown => monthlyGraceDays,
      };

  /// Estado efectivo local a partir del snapshot + reloj UTC.
  LicenseStatus effectiveStatus(
    LicenseSnapshot license, {
    DateTime? now,
  }) {
    final remote = license.status;
    if (remote == LicenseStatus.revoked ||
        remote == LicenseStatus.suspended ||
        remote == LicenseStatus.pending) {
      return remote;
    }

    final at = (now ?? En1DateTimeService.nowUtc()).toUtc();

    if (license.licenseType == LicenseType.perpetual) {
      return LicenseStatus.active;
    }

    final starts = license.startsAt;
    if (starts != null && at.isBefore(starts)) {
      return LicenseStatus.pending;
    }

    final expires = license.expiresAt;
    if (expires == null) {
      return remote == LicenseStatus.unknown ? LicenseStatus.active : remote;
    }

    if (!at.isAfter(expires)) {
      return LicenseStatus.active;
    }

    final graceUntil = license.graceUntil ??
        expires.add(Duration(days: graceDaysFor(license.licenseType).clamp(0, 3650)));
    if (graceDaysFor(license.licenseType) < 0 || !at.isAfter(graceUntil)) {
      return LicenseStatus.grace;
    }

    return LicenseStatus.expired;
  }

  /// ¿La última validación EN1 está dentro de la ventana offline?
  bool isWithinOfflineValidationWindow(
    LicenseSnapshot license, {
    DateTime? now,
  }) {
    final last = license.lastValidation;
    if (last == null) return false;
    final at = (now ?? En1DateTimeService.nowUtc()).toUtc();
    return at.difference(last.toUtc()) <= Duration(days: offlineValidationDays);
  }
}
