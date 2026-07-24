import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/licensing/data/license_audit_store.dart';
import 'package:eposone/src/features/licensing/data/license_mapper.dart';
import 'package:eposone/src/features/licensing/data/license_repository.dart';
import 'package:eposone/src/features/licensing/domain/feature_manager.dart';
import 'package:eposone/src/features/licensing/domain/grace_manager.dart';
import 'package:eposone/src/features/licensing/domain/license_enums.dart';
import 'package:eposone/src/features/licensing/domain/license_feature.dart';
import 'package:eposone/src/features/licensing/domain/license_snapshot.dart';
import 'package:eposone/src/features/licensing/domain/license_validator.dart';

/// Fachada única del License Engine V1.0 (APK).
///
/// - No crea licencias comerciales.
/// - Consume bootstrap / sync EN1.
/// - Offline-first vía [LicenseRepository].
class LicenseService {
  LicenseService({
    LicenseRepository? repository,
    LicenseMapper? mapper,
    GraceManager? grace,
    LicenseValidator? validator,
  })  : _repo = repository ?? LicenseRepository(),
        _mapper = mapper ?? const LicenseMapper(),
        _grace = grace ?? const GraceManager(),
        _validator = validator ?? LicenseValidator(grace: grace ?? const GraceManager());

  final LicenseRepository _repo;
  final LicenseMapper _mapper;
  final GraceManager _grace;
  final LicenseValidator _validator;

  LicenseSnapshot? _cached;

  Future<LicenseSnapshot?> load({bool force = false}) async {
    if (!force && _cached != null) return _cached;
    _cached = await _repo.load();
    return _cached;
  }

  Future<LicenseValidationResult> validate({DateTime? now}) async {
    final snap = await load();
    return _validator.validate(snap, now: now);
  }

  Future<FeatureManager> featureManager({DateTime? now}) async {
    final snap = await load();
    final validation = _validator.validate(snap, now: now);
    return FeatureManager(license: snap, validation: validation);
  }

  Future<bool> isFeatureEnabled(LicenseFeature feature) async {
    final fm = await featureManager();
    return fm.isEnabled(feature);
  }

  /// Aplica bloque `license` del bootstrap. Si viene null/vacío, no inventa Trial.
  Future<LicenseSnapshot?> applyFromBootstrap(Map<String, dynamic>? licenseJson) async {
    final mapped = _mapper.fromBootstrapJson(licenseJson);
    if (mapped == null) {
      await LicenseAuditStore.record('license.bootstrap_received', meta: {
        'present': false,
      });
      return await load();
    }

    final now = En1DateTimeService.nowUtc();
    final previous = await load(force: true);
    final withValidation = mapped.copyWith(
      lastValidation: now,
      updatedAt: now,
      status: _grace.effectiveStatus(mapped.copyWith(lastValidation: now), now: now),
    );

    await _repo.save(withValidation);
    _cached = withValidation;

    if (previous == null) {
      await LicenseAuditStore.record('license.created', meta: {
        'type': withValidation.licenseType.code,
        'plan': withValidation.planCode,
      });
    } else {
      await LicenseAuditStore.record('license.updated', meta: {
        'type': withValidation.licenseType.code,
        'status': withValidation.status.code,
      });
    }
    await LicenseAuditStore.record('license.bootstrap_received', meta: {
      'present': true,
      'type': withValidation.licenseType.code,
    });

    final effective = _grace.effectiveStatus(withValidation, now: now);
    if (effective == LicenseStatus.expired) {
      await LicenseAuditStore.record('license.expired');
    } else if (effective == LicenseStatus.suspended) {
      await LicenseAuditStore.record('license.suspended');
    } else if (effective == LicenseStatus.revoked) {
      await LicenseAuditStore.record('license.revoked');
    }

    return withValidation;
  }

  /// Marca validación tras cualquier contacto EN1 exitoso (heartbeat/sync).
  Future<void> markValidatedFromEn1() async {
    final snap = await load(force: true);
    if (snap == null) return;
    final now = En1DateTimeService.nowUtc();
    final updated = snap.copyWith(
      lastValidation: now,
      updatedAt: now,
      status: _grace.effectiveStatus(snap.copyWith(lastValidation: now), now: now),
    );
    await _repo.save(updated);
    _cached = updated;
  }
}
