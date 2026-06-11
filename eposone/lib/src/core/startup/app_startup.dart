import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

enum StartupRoute { splash, onboarding, pin, cashOpen, pos }

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
