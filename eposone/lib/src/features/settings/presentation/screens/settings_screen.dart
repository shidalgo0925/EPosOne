import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Impresora térmica'),
            subtitle: const Text('Bluetooth, cajón monedero'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/printer'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Tickets abiertos'),
            subtitle: const Text('Nombres predefinidos, tipo de orden'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/open-tickets'),
          ),
        ],
      ),
    );
  }
}
