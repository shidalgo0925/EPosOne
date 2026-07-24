import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

/// Hub Reportes — consulta primero; imprimir es una acción (Loyverse).
class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Consulta la información y, si la necesitas en papel, pulsa Imprimir.',
            style: TextStyle(color: EposBrand.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _ReportTile(
            icon: Icons.point_of_sale,
            title: 'Ventas',
            subtitle: 'Día, rango, métodos y detalle',
            onTap: () => context.push('/reports/sales'),
          ),
          _ReportTile(
            icon: Icons.account_balance_wallet,
            title: 'Caja / Turnos',
            subtitle: 'Aperturas y cierres',
            onTap: () => context.push('/reports/shifts'),
          ),
          _ReportTile(
            icon: Icons.badge_outlined,
            title: 'Empleados / Productos',
            subtitle: 'Ventas por cajero o por producto',
            onTap: () => context.push('/reports/employees'),
          ),
          _ReportTile(
            icon: Icons.people_outline,
            title: 'Clientes',
            subtitle: 'Usa Clientes en el menú (historial por ficha)',
            onTap: () => context.push('/customers'),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: EposBrand.orange.withValues(alpha: 0.15),
          child: Icon(icon, color: EposBrand.orange),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
