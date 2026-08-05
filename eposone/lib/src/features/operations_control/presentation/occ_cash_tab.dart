import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

/// OCC → Cajas — cierres, arqueos, bitácoras (Cash Shift vive aquí).
class OccCashTab extends StatelessWidget {
  const OccCashTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Cajas',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: EposBrand.navy)),
        const SizedBox(height: 8),
        const Text(
          'Cierres · arqueos · bitácoras. No es el nombre del dominio OCC.',
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.point_of_sale),
          title: const Text('Caja / turno actual'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/cash-register'),
        ),
        ListTile(
          leading: const Icon(Icons.lock_clock_outlined),
          title: const Text('Cerrar turno (arqueo)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/cash-register/close'),
        ),
        ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: const Text('Tesorería / movimientos'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/cash-register/treasury'),
        ),
        ListTile(
          leading: const Icon(Icons.assessment_outlined),
          title: const Text('Informe de turnos (histórico)'),
          subtitle: const Text('Reporte — fuera del pulso OCC'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/reports/shifts'),
        ),
      ],
    );
  }
}
