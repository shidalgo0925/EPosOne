import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/operations_control/application/occ_pulse_provider.dart';

/// OCC → Hoy — pulso ejecutivo + deep links (Fase A Visibilidad).
class OccHoyTab extends ConsumerWidget {
  const OccHoyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(occPulseProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (p) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(occPulseProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hoy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: EposBrand.navy,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              p.cashierName == null
                  ? 'Visibilidad operacional · no es un informe'
                  : 'Cajero: ${p.cashierName}',
              style: const TextStyle(color: EposBrand.textSecondary),
            ),
            if (p.generatedAt != null)
              Text(
                'Actualizado ${En1DateTimeService.formatLocal(p.generatedAt!)}',
                style: const TextStyle(
                    fontSize: 12, color: EposBrand.textSecondary),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PulseCard(
                  title: 'Atención',
                  value: '${p.attentionCount}',
                  subtitle: p.attentionCount == 0
                      ? 'Sin señales críticas'
                      : 'Revisar Alertas',
                  color: p.attentionCount == 0
                      ? Colors.green.shade700
                      : EposBrand.orange,
                  onTap: null,
                ),
                _PulseCard(
                  title: 'Turno',
                  value: p.shiftOpen ? 'Abierto' : 'Cerrado',
                  subtitle: p.shiftLabel,
                  color: EposBrand.navy,
                  onTap: () => context.push('/cash-register'),
                ),
                _PulseCard(
                  title: 'Tickets abiertos',
                  value: '${p.openTickets}',
                  subtitle: 'Ir a POS',
                  color: EposBrand.navy,
                  onTap: () => context.push('/pos'),
                ),
                _PulseCard(
                  title: 'Cola sync',
                  value: '${p.pendingSync}',
                  subtitle: p.failedSync > 0
                      ? '${p.failedSync} con error'
                      : 'Pendientes',
                  color: p.failedSync > 0
                      ? Colors.red.shade700
                      : EposBrand.navy,
                  onTap: () => context.push('/settings/sync'),
                ),
                _PulseCard(
                  title: 'Conectividad',
                  value: p.linkLabel,
                  subtitle: 'Este dispositivo',
                  color: EposBrand.navy,
                  onTap: () => context.push('/platform/device'),
                ),
                _PulseCard(
                  title: 'Licencia',
                  value: p.licenseLabel,
                  subtitle: 'Detalle',
                  color: EposBrand.navy,
                  onTap: () => context.push('/platform/license'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Accesos rápidos',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: EposBrand.navy),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Cerrar / arqueo de caja'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/cash-register/close'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Tesorería'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/cash-register/treasury'),
            ),
            ListTile(
              leading: const Icon(Icons.assessment_outlined),
              title: const Text('Reportes (históricos)'),
              subtitle: const Text('Fuera del OCC — solo enlace'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/reports'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 168,
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EposBrand.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EposBrand.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: EposBrand.textSecondary)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: EposBrand.textSecondary),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}
