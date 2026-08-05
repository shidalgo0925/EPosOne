import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/operations_control/application/occ_pulse_provider.dart';

class OccOperationTab extends ConsumerWidget {
  const OccOperationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulse = ref.watch(occPulseProvider).asData?.value;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Operación',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: EposBrand.navy)),
        const SizedBox(height: 8),
        const Text(
          'Salud de sync, dispositivo y pedidos abiertos.',
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.cloud_sync_outlined),
          title: const Text('Sincronización'),
          subtitle: Text(
            pulse == null
                ? '—'
                : '${pulse.pendingSync} pendientes · ${pulse.failedSync} error · ${pulse.linkLabel}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/sync'),
        ),
        ListTile(
          leading: const Icon(Icons.smartphone_outlined),
          title: const Text('Este dispositivo (2.6)'),
          subtitle: const Text('Provisioning · bootstrap · cola · licencia'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/platform/device'),
        ),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Pedidos / tickets'),
          subtitle: Text(
              '${pulse?.openTickets ?? '—'} tickets abiertos · POS'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/pos'),
        ),
        ListTile(
          leading: const Icon(Icons.list_alt_outlined),
          title: const Text('Operación Order Domain'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/orders'),
        ),
      ],
    );
  }
}
