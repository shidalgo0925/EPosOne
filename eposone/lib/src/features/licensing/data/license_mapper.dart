import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/licensing/domain/license_enums.dart';
import 'package:eposone/src/features/licensing/domain/license_snapshot.dart';

/// Mapea el bloque `license` del bootstrap / sync EN1 → [LicenseSnapshot].
class LicenseMapper {
  const LicenseMapper();

  /// Acepta el objeto `license` del contrato propuesto (tolerant a aliases).
  LicenseSnapshot? fromBootstrapJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    final now = En1DateTimeService.nowUtc();
    final snap = LicenseSnapshot.fromJson({
      ...json,
      'source': json['source'] ?? 'bootstrap',
      'activation_method':
          json['activation_method'] ?? json['activationMethod'] ?? 'EN1',
      'updated_at': json['updated_at'] ?? json['updatedAt'] ?? En1DateTimeService.toUtcIso(now),
      'last_validation':
          json['last_validation'] ?? json['lastValidation'] ?? En1DateTimeService.toUtcIso(now),
    });
    if (snap.licenseType == LicenseType.unknown &&
        (snap.planCode == null || snap.planCode!.isEmpty) &&
        snap.features.isEmpty &&
        snap.expiresAt == null) {
      return null;
    }
    return snap;
  }
}
