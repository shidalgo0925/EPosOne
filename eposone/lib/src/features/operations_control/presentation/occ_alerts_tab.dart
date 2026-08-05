import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/operations_control/application/occ_pulse_provider.dart';

/// OCC → Alertas — bandeja mínima Fase A (sin motor de reglas aún).
class OccAlertsTab extends ConsumerWidget {
  const OccAlertsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(occPulseProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (p) {
        final items = <({String title, String body, String route})>[];
        if (p.failedSync > 0 && p.syncError != null) {
          items.add((
            title: 'Sync con error',
            body: p.syncError!,
            route: '/settings/sync',
          ));
        }
        if (p.pendingSync > 0) {
          items.add((
            title: 'Cola pendiente',
            body: '${p.pendingSync} operaciones por sincronizar',
            route: '/settings/sync',
          ));
        }
        if (p.bootstrapError != null && p.bootstrapError!.isNotEmpty) {
          items.add((
            title: 'Error de bootstrap',
            body: p.bootstrapError!,
            route: '/platform/device',
          ));
        }
        if (p.provisioningError != null &&
            p.provisioningError!.isNotEmpty) {
          items.add((
            title: 'Error de provisioning',
            body: p.provisioningError!,
            route: '/platform/device',
          ));
        }
        if (!p.shiftOpen) {
          items.add((
            title: 'Sin turno abierto',
            body: 'No hay caja abierta en este dispositivo',
            route: '/cash/open',
          ));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Alertas',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: EposBrand.navy)),
            const SizedBox(height: 8),
            Text(
              items.isEmpty
                  ? 'Sin alertas derivadas (Fase A).'
                  : '${items.length} señal(es) · motor de reglas = Fase B',
              style: const TextStyle(color: EposBrand.textSecondary),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text('Operación sin señales de atención'),
                ),
              )
            else
              for (final a in items)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined,
                        color: EposBrand.orange),
                    title: Text(a.title),
                    subtitle: Text(a.body),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(a.route),
                  ),
                ),
          ],
        );
      },
    );
  }
}
