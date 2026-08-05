import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

/// OCC → Auditoría — Fase A: enlaces; bitácora formal = Fase B.
class OccAuditTab extends StatelessWidget {
  const OccAuditTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Auditoría',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: EposBrand.navy)),
        const SizedBox(height: 8),
        const Text(
          'Quién · qué · cuándo. Fase A enlaza historiales existentes.',
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Historial de sync'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/sync/history'),
        ),
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Cajeros'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/cashiers'),
        ),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('Informe empleados'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/reports/employees'),
        ),
        ListTile(
          leading: const Icon(Icons.smartphone_outlined),
          title: const Text('Diagnóstico dispositivo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/platform/device'),
        ),
      ],
    );
  }
}
