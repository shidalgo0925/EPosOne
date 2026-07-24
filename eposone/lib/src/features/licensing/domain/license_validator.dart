import 'package:eposone/src/features/licensing/domain/grace_manager.dart';
import 'package:eposone/src/features/licensing/domain/license_enums.dart';
import 'package:eposone/src/features/licensing/domain/license_snapshot.dart';

class LicenseValidationResult {
  final LicenseStatus effectiveStatus;
  final bool canOperatePos;
  final bool needsSync;
  final String message;

  const LicenseValidationResult({
    required this.effectiveStatus,
    required this.canOperatePos,
    required this.needsSync,
    required this.message,
  });
}

/// Validación única del snapshot local. Nunca validar “disperso” en pantallas.
class LicenseValidator {
  LicenseValidator({GraceManager? grace}) : _grace = grace ?? const GraceManager();

  final GraceManager _grace;

  LicenseValidationResult validate(LicenseSnapshot? license, {DateTime? now}) {
    if (license == null) {
      // Standalone / sin snapshot EN1: POS operativo; no hay licencia comercial local.
      return const LicenseValidationResult(
        effectiveStatus: LicenseStatus.unknown,
        canOperatePos: true,
        needsSync: false,
        message: 'Sin snapshot EN1 (modo local / pendiente bootstrap).',
      );
    }

    final status = _grace.effectiveStatus(license, now: now);
    final withinOffline =
        _grace.isWithinOfflineValidationWindow(license, now: now);
    final canOperate = switch (status) {
      LicenseStatus.active || LicenseStatus.grace || LicenseStatus.pending =>
        true,
      LicenseStatus.expired ||
      LicenseStatus.suspended ||
      LicenseStatus.revoked =>
        false,
      LicenseStatus.unknown => true,
    };

    final needsSync = !withinOffline ||
        status == LicenseStatus.grace ||
        status == LicenseStatus.expired;

    return LicenseValidationResult(
      effectiveStatus: status,
      canOperatePos: canOperate,
      needsSync: needsSync,
      message: status.label,
    );
  }
}
