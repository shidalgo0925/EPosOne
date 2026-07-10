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
            leading: const Icon(Icons.dashboard_customize_outlined),
            title: const Text('Páginas POS'),
            subtitle: const Text('Pestañas de catálogo en el TPV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/pos-pages'),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Modificadores'),
            subtitle: const Text('Extras, tamaños, personalizaciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/modifiers'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Tickets abiertos'),
            subtitle: const Text('Nombres predefinidos, tipo de orden'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/open-tickets'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('Facturación electrónica'),
            subtitle: const Text('FE DGI Panamá, PAC, correlativos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/fiscal'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('EN1 Cloud'),
            subtitle: const Text('Sync ventas, clientes, catálogo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/sync'),
          ),
          ListTile(
            leading: const Icon(Icons.smartphone_outlined),
            title: const Text('Este dispositivo'),
            subtitle: const Text('UUID, modo, versión'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/platform/device'),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Premium'),
            subtitle: const Text('Cupones, fidelización, CRM'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/premium'),
          ),
        ],
      ),
    );
  }
}
