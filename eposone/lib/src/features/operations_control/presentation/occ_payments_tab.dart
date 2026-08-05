import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

/// OCC → Pagos — Fase A: enlaces; inteligencia de medios = Fase C.
class OccPaymentsTab extends StatelessWidget {
  const OccPaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Pagos',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: EposBrand.navy)),
        const SizedBox(height: 8),
        const Text(
          'Fase A: accesos. Desglose por medio e insights → Fase C.',
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: const Text('Historial de ventas'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/sales'),
        ),
        ListTile(
          leading: const Icon(Icons.assessment_outlined),
          title: const Text('Reporte de ventas'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/reports/sales'),
        ),
      ],
    );
  }
}
