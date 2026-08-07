import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/startup/app_startup.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/ui/user_facing_error.dart';
import 'package:eposone/src/features/auth/presentation/screens/pin_screen.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_repository.dart';
import 'package:eposone/src/features/platform/data/en1_device_auth_recovery.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_repository.dart';
import 'package:eposone/src/features/platform/data/installation_lifecycle.dart';
import 'package:eposone/src/features/platform/domain/en1_bootstrap_models.dart';
import 'package:eposone/src/features/platform/domain/installation_lifecycle_state.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_page_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';

/// Checklist visible P0.21 (orden = fases reales del repositorio).
const _kBootstrapSteps = <({String id, String label, Set<String> phases})>[
  (
    id: 'config',
    label: 'Descargando configuración',
    phases: {'fetch', 'catalog'},
  ),
  (
    id: 'params',
    label: 'Descargando catálogo y parámetros',
    phases: {'categories', 'products', 'images'},
  ),
  (
    id: 'cashiers',
    label: 'Descargando cajeros',
    phases: {'cashiers'},
  ),
  (
    id: 'license',
    label: 'Descargando licencia',
    phases: {'license'},
  ),
  (
    id: 'done',
    label: 'Finalizando',
    phases: {'pos', 'cleanup', 'done'},
  ),
];

/// Bootstrap bloqueante post-provisioning (ADR-014). Sin bypass al POS.
///
/// P0.21 progreso checklist · P0.22 reintentar/cancelar · P0.23 no re-register ·
/// P0.24 auto-reintento offline · P0.29 pantalla “está listo”.
class PlatformBootstrapScreen extends ConsumerStatefulWidget {
  const PlatformBootstrapScreen({super.key});

  @override
  ConsumerState<PlatformBootstrapScreen> createState() =>
      _PlatformBootstrapScreenState();
}

class _PlatformBootstrapScreenState
    extends ConsumerState<PlatformBootstrapScreen> {
  bool _running = false;
  bool _success = false;
  String _label = 'Preparando EPOSOne…';
  double? _fraction;
  String? _error;
  String? _phase;
  InstallationLifecycleState? _blockedState;
  final Set<String> _completedStepIds = {};
  Timer? _offlineRetry;
  int _offlineAttempts = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  @override
  void dispose() {
    _offlineRetry?.cancel();
    super.dispose();
  }

  bool get _isOfflineError {
    final e = (_error ?? '').toLowerCase();
    return e.contains('sin conexión') || e.contains('internet') || e.contains('red');
  }

  void _markStepsForPhase(String phase) {
    for (final step in _kBootstrapSteps) {
      if (step.phases.contains(phase)) {
        // Marcar pasos anteriores como hechos.
        final idx = _kBootstrapSteps.indexOf(step);
        for (var i = 0; i < idx; i++) {
          _completedStepIds.add(_kBootstrapSteps[i].id);
        }
      }
    }
    if (phase == 'done') {
      for (final s in _kBootstrapSteps) {
        _completedStepIds.add(s.id);
      }
    }
  }

  Future<void> _run() async {
    if (_running) return;
    _offlineRetry?.cancel();
    setState(() {
      _running = true;
      _success = false;
      _error = null;
      _blockedState = null;
      _label = 'Preparando EPOSOne…';
      _fraction = null;
      _phase = null;
      _completedStepIds.clear();
    });

    await InstallationLifecycle.onBootstrapStarted();

    try {
      final isar = await ref.read(databaseProvider.future);
      final result = await En1BootstrapRepository(isar: isar).runBootstrap(
        onProgress: (En1BootstrapProgress p) {
          if (!mounted) return;
          setState(() {
            _label = p.label;
            _fraction = p.fraction;
            _phase = p.phase;
            _markStepsForPhase(p.phase);
          });
        },
      );

      final cfg = await En1ProvisioningRepository().getConfig();
      if (En1DeviceAuthRecovery.isRevokedDeviceStatus(cfg?.deviceStatus)) {
        final route = await En1DeviceAuthRecovery.recoverAndLockSession(
          ref,
          reason:
              'Este dispositivo ya no está autorizado. Solicite un código nuevo en el Portal.',
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
              ? 'La descarga terminó, pero la licencia no permite operar. '
                  'Revise la licencia en el Portal EN1 e intente de nuevo.'
              : 'La instalación aún no está completa. Intente de nuevo.';
          _label = result.message;
        });
        return;
      }

      // P0.29 — éxito antes de PIN.
      setState(() {
        _running = false;
        _success = true;
        for (final s in _kBootstrapSteps) {
          _completedStepIds.add(s.id);
        }
      });
    } catch (e) {
      if (!mounted) return;

      if (En1DeviceAuthRecovery.isUnauthorized(e)) {
        final route = await En1DeviceAuthRecovery.recoverAndLockSession(
          ref,
          reason: e is En1ProvisioningException
              ? e.userMessage
              : 'Dispositivo no autorizado. Solicite un código nuevo.',
        );
        if (!mounted) return;
        context.go(route);
        return;
      }

      final message = userFacingError(
        e,
        fallback:
            'No se pudo completar la preparación. Verifique la conexión e intente de nuevo.',
      );
      setState(() {
        _running = false;
        _error = message;
        _label = 'Preparación pendiente';
      });
      _scheduleOfflineRetryIfNeeded();
    }
  }

  void _scheduleOfflineRetryIfNeeded() {
    if (!_isOfflineError) return;
    if (_offlineAttempts >= 8) return;
    _offlineRetry?.cancel();
    _offlineRetry = Timer(const Duration(seconds: 5), () {
      if (!mounted || _running || _success) return;
      _offlineAttempts++;
      _run();
    });
  }

  Future<void> _goToPin() async {
    final startup = await ref.read(appStartupProvider.future);
    if (!mounted) return;
    switch (startup.route) {
      case StartupRoute.platformWelcome:
        context.go('/platform/welcome');
      case StartupRoute.connect:
        context.go(En1DeviceAuthRecovery.connectRoute);
      case StartupRoute.bootstrap:
        setState(() {
          _success = false;
          _error = 'El dispositivo aún no está listo. Intente de nuevo.';
        });
      case StartupRoute.onboarding:
        // Preferir PIN si hay cajeros; onboarding local es último recurso.
        context.go('/pin');
      case StartupRoute.pin:
        context.go('/pin');
    }
  }

  /// P0.22 Cancelar: no borra Device Bearer (P0.23).
  void _cancelSoft() {
    _offlineRetry?.cancel();
    context.go('/platform/welcome');
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
                const SizedBox(height: 16),
                const EposBrandIcon(size: 64),
                const SizedBox(height: 20),
                Text(
                  _success ? 'EPOSOne está listo' : 'Preparando EPOSOne',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: EposBrand.navy,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _success
                      ? 'Ahora puede abrir su caja y comenzar a vender.'
                      : 'Descargando la configuración oficial. '
                          'El punto de venta se habilita al terminar.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: EposBrand.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: _success
                      ? const Center(
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 88,
                            color: EposBrand.orange,
                          ),
                        )
                      : _buildChecklist(context),
                ),
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
                    const LinearProgressIndicator(
                      minHeight: 8,
                      color: EposBrand.orange,
                      backgroundColor: EposBrand.divider,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: EposBrand.textPrimary),
                  ),
                ] else if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade800, height: 1.35),
                  ),
                  if (_isOfflineError) ...[
                    const SizedBox(height: 8),
                    Text(
                      _offlineAttempts > 0
                          ? 'Reintentando automáticamente… ($_offlineAttempts)'
                          : 'Se reintentará automáticamente al recuperar la red.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: EposBrand.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (_blockedState != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Estado: ${_blockedState!.label}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: EposBrand.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      _offlineAttempts = 0;
                      _run();
                    },
                    child: const Text('Reintentar'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _cancelSoft,
                    child: const Text('Cancelar'),
                  ),
                  if (_blockedState ==
                      InstallationLifecycleState.bootstrapCompleted) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/platform/license'),
                      child: const Text('Ver licencia'),
                    ),
                  ],
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () async {
                      final route =
                          await En1DeviceAuthRecovery.recoverAndLockSession(
                        ref,
                      );
                      if (!context.mounted) return;
                      context.go(route);
                    },
                    child: const Text('Usar otro código'),
                  ),
                ] else if (_success) ...[
                  FilledButton(
                    onPressed: _goToPin,
                    child: const Text('Continuar'),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklist(BuildContext context) {
    return ListView(
      children: [
        for (final step in _kBootstrapSteps)
          _BootstrapStepRow(
            label: step.label,
            done: _completedStepIds.contains(step.id),
            active: _running &&
                _phase != null &&
                step.phases.contains(_phase) &&
                !_completedStepIds.contains(step.id),
          ),
      ],
    );
  }
}

class _BootstrapStepRow extends StatelessWidget {
  const _BootstrapStepRow({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final icon = done
        ? const Icon(Icons.check_box, color: EposBrand.orange)
        : active
            ? const SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Icon(Icons.check_box_outline_blank, color: Colors.grey.shade400);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 28, height: 28, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: active || done ? FontWeight.w600 : FontWeight.w400,
                color: done || active
                    ? EposBrand.textPrimary
                    : EposBrand.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
