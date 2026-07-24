import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/licensing/domain/feature_manager.dart';
import 'package:eposone/src/features/licensing/domain/license_service.dart';
import 'package:eposone/src/features/licensing/domain/license_snapshot.dart';
import 'package:eposone/src/features/licensing/domain/license_validator.dart';

final licenseServiceProvider = Provider<LicenseService>((ref) => LicenseService());

final licenseSnapshotProvider = FutureProvider<LicenseSnapshot?>((ref) async {
  return ref.watch(licenseServiceProvider).load(force: true);
});

final licenseValidationProvider =
    FutureProvider<LicenseValidationResult>((ref) async {
  return ref.watch(licenseServiceProvider).validate();
});

final featureManagerProvider = FutureProvider<FeatureManager>((ref) async {
  return ref.watch(licenseServiceProvider).featureManager();
});
