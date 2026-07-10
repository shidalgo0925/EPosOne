import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

enum StartupRoute { splash, platformWelcome, onboarding, pin, cashOpen, pos }

class AppStartupState {
  final StartupRoute route;
  final BusinessConfig? config;
  final bool hasCashiers;
  final bool hasOpenRegister;

  const AppStartupState({
    required this.route,
    this.config,
    this.hasCashiers = false,
    this.hasOpenRegister = false,
  });
}

final appStartupProvider = FutureProvider<AppStartupState>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  final configRepo = BusinessConfigRepository(isar);
  final cashierRepo = CashierRepository(isar);
  final cashRepo = CashRegisterRepository(isar);

  final config = await configRepo.getConfig();
  final cashierCount = await cashierRepo.countCashiers();
  final openRegister = await cashRepo.getOpenRegister();

  await DeviceRegistry.getOrCreateUuid();

  // Hito 1: dispositivo ya provisionado en EN1 → omitir wizard de plataforma.
  final provisioned = await ProvisioningStore.isProvisioned();
  if (provisioned && !await PlatformPrefs.isOnboardingDone()) {
    await PlatformPrefs.completeOnboarding(PlatformMode.platform);
  }

  var platformDone = await PlatformPrefs.isOnboardingDone() || provisioned;

  // Instalaciones locales ya operativas (p. ej. Istmo) no ven el wizard.
  if (!platformDone && config.isSetupComplete && cashierCount > 0) {
    await PlatformPrefs.markCompletedForExistingInstall();
    platformDone = true;
  }

  if (!platformDone) {
    return AppStartupState(route: StartupRoute.platformWelcome, config: config);
  }

  // Provisionado + setup completo + cajeros → PIN (criterio Hito 1).
  if (!config.isSetupComplete || cashierCount == 0) {
    return AppStartupState(route: StartupRoute.onboarding, config: config);
  }

  if (openRegister == null) {
    return AppStartupState(
      route: StartupRoute.cashOpen,
      config: config,
      hasCashiers: true,
    );
  }

  return AppStartupState(
    route: StartupRoute.pin,
    config: config,
    hasCashiers: true,
    hasOpenRegister: true,
  );
});
