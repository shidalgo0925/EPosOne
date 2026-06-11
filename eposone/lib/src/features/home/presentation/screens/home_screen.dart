import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ePosOne'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _MenuCard(
              icon: Icons.point_of_sale,
              label: 'Vender',
              color: Colors.green,
              onTap: () => context.push('/pos'),
            ),
            _MenuCard(
              icon: Icons.inventory_2,
              label: 'Productos',
              color: Colors.blue,
              onTap: () => context.push('/products'),
            ),
            _MenuCard(
              icon: Icons.people,
              label: 'Clientes',
              color: Colors.orange,
              onTap: () => context.push('/customers'),
            ),
            _MenuCard(
              icon: Icons.account_balance_wallet,
              label: 'Caja',
              color: Colors.purple,
              onTap: () => context.push('/cash-register'),
            ),
            _MenuCard(
              icon: Icons.receipt_long,
              label: 'Ventas',
              color: Colors.teal,
              onTap: () => context.push('/sales'),
            ),
            _MenuCard(
              icon: Icons.settings,
              label: 'Configuración',
              color: Colors.grey,
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}