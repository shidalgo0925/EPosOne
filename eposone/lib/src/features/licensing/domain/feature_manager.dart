import 'package:eposone/src/features/licensing/domain/license_feature.dart';
import 'package:eposone/src/features/licensing/domain/license_snapshot.dart';
import 'package:eposone/src/features/licensing/domain/license_validator.dart';

/// Única puerta de features. No preguntar plan; preguntar permiso.
class FeatureManager {
  FeatureManager({
    required LicenseSnapshot? license,
    required LicenseValidationResult validation,
  })  : _license = license,
        _validation = validation;

  final LicenseSnapshot? _license;
  final LicenseValidationResult _validation;

  bool get canOperatePos => _validation.canOperatePos;

  bool isEnabled(LicenseFeature feature) {
    if (!_validation.canOperatePos &&
        (feature == LicenseFeature.sales ||
            feature == LicenseFeature.payments)) {
      // Operación POS bloqueada por licencia: ventas/cobros off.
      return false;
    }

    final snap = _license;
    if (snap == null) {
      return kStandaloneDefaultFeatures.contains(feature);
    }

    // Snapshot presente: solo lo que EN1 habilitó.
    if (snap.features.containsKey(feature.code)) {
      return snap.features[feature.code] == true;
    }

    // Sin mapa de features en snapshot: core ON si status operativo.
    if (_validation.canOperatePos &&
        kStandaloneDefaultFeatures.contains(feature)) {
      return true;
    }
    return false;
  }

  int? limitMaxRegisters() => _license?.maxRegisters;
  int? limitMaxDevices() => _license?.maxDevices;
  int? limitMaxCashiers() => _license?.maxCashiers;
  int? limitMaxProducts() => _license?.maxProducts;
}
