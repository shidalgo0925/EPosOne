import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/startup/app_startup.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/auth/presentation/screens/pin_screen.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_repository.dart';
import 'package:eposone/src/features/platform/data/en1_device_auth_recovery.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_repository.dart';
import 'package:eposone/src/features/platform/data/installation_lifecycle.dart';
import 'package:eposone/src/features/platform/domain/installation_lifecycle_state.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_page_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';

/// Bootstrap bloqueante post-provisioning (ADR-014). Sin bypass al POS.
class PlatformBootstrapScreen extends ConsumerStatefulWidget {
  const PlatformBootstrapScreen({super.key});

  @override
  ConsumerState<PlatformBootstrapScreen> createState() =>
      _PlatformBootstrapScreenState();
}

class _PlatformBootstrapScreenState
    extends ConsumerState<PlatformBootstrapScreen> {
  bool _running = false;
  String _label = 'Preparando sincronización inicial…';
  double? _fraction;
  String? _error;
  InstallationLifecycleState? _blockedState;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _error = null;
      _blockedState = null;
      _label = 'Iniciando bootstrap EN1…';
      _fraction = null;
    });

    await InstallationLifecycle.onBootstrapStarted();

    try {
      final isar = await ref.read(databaseProvider.future);
      final result = await En1BootstrapRepository(isar: isar).runBootstrap(
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _label = p.label;
            _fraction = p.fraction;
          });
        },
      );

      // device.status revocado desde EN1 → forzar Connect.
      final cfg = await En1ProvisioningRepository().getConfig();
      if (En1DeviceAuthRecovery.isRevokedDeviceStatus(cfg?.deviceStatus)) {
        final route = await En1DeviceAuthRecovery.recoverAndLockSession(
          ref,
          reason:
              'Dispositivo revocado o inactivo en EN1 (${cfg?.deviceStatus}). '
              'Reaprovisiona con un código de Caja.',
        );
        if (!mounted) return;
        context.go(route);
        return;
      }

      final state = await InstallationLifecycle.evaluate();
      ref.invalidate(productsListProvider);
      ref.invalidate(categoriesListProvider);
      ref.invalidate(posPagesListProvider);
      ref.invalidate(syncOperationsProvider);
      ref.invalidate(loginCashiersProvider);
      ref.invalidate(appStartupProvider);

      if (!mounted) return;

      if (state != InstallationLifecycleState.readyToOperate) {
        setState(() {
          _running = false;
          _blockedState = state;
          _error = state == InstallationLifecycleState.bootstrapCompleted
              ? 'Bootstrap descargado, pero la licencia no permite operar. '
                  'Revisa la licencia de la caja en EN1 e intenta de nuevo.'
              : 'Instalación incompleta (${state.label}). Reintenta el bootstrap.';
          _label = result.message;
        });
        return;
      }

      final startup = await ref.read(appStartupProvider.future);
      if (!mounted) return;

      switch (startup.route) {
        case StartupRoute.platformWelcome:
          context.go('/platform/welcome');
        case StartupRoute.connect:
          context.go(En1DeviceAuthRecovery.connectRoute);
        case StartupRoute.bootstrap:
          // No debería ocurrir si ready; reintenta UI.
          setState(() {
            _running = false;
            _error = 'El dispositivo aún no está listo. Reintenta.';
          });
        case StartupRoute.onboarding:
          context.go('/onboarding');
        case StartupRoute.pin:
          context.go('/pin');
      }
    } catch (e) {
      if (!mounted) return;

      if (En1DeviceAuthRecovery.isUnauthorized(e)) {
        final route = await En1DeviceAuthRecovery.recoverAndLockSession(
          ref,
          reason: e is En1ProvisioningException
              ? e.userMessage
              : 'Dispositivo no autorizado. Reaprovisiona el dispositivo.',
        );
        if (!mounted) return;
        context.go(route);
        return;
      }

      final message = switch (e) {
        En1ProvisioningException(:final userMessage) => userMessage,
        En1BootstrapException(:final message) => message,
        _ =>
          'No se pudo completar el bootstrap. Verifica la conexión e intenta de nuevo.',
      };
      setState(() {
        _running = false;
        _error = message;
        _label = 'Bootstrap pendiente';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: EposBrand.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const EposBrandIcon(size: 64),
                const SizedBox(height: 20),
                Text(
                  'Sincronización inicial',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: EposBrand.navy,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Descargando datos oficiales de EasyNodeOne. '
                  'El POS permanece bloqueado hasta completar este paso.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: EposBrand.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                if (_running) ...[
                  if (_fraction != null)
                    LinearProgressIndicator(
                      value: _fraction,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      color: EposBrand.orange,
                      backgroundColor: EposBrand.divider,
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                  Text(
                    _label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: EposBrand.textPrimary),
                  ),
                ] else if (_error != null) ...[
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade800, height: 1.35),
                  ),
                  if (_blockedState != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Estado: ${_blockedState!.label}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: EposBrand.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _run,
                    child: const Text('Reintentar'),
                  ),
                  if (_blockedState ==
                      InstallationLifecycleState.bootstrapCompleted) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.push('/platform/license'),
                      child: const Text('Ver licencia'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        final route =
                            await En1DeviceAuthRecovery.recoverAndLockSession(
                          ref,
                          reason:
                              'Reaprovisionamiento solicitado tras bloqueo de licencia.',
                        );
                        if (!mounted) return;
                        context.go(route);
                      },
                      child: const Text('Reaprovisionar dispositivo'),
                    ),
                  ] else if (_error != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        final route =
                            await En1DeviceAuthRecovery.recoverAndLockSession(
                          ref,
                        );
                        if (!mounted) return;
                        context.go(route);
                      },
                      child: const Text('Reaprovisionar dispositivo'),
                    ),
                  ],
                ],
                const Spacer(),
                const Text(
                  'ADR-014 · Sin bypass · Modo integrado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: EposBrand.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
