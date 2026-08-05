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
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Negocio'),
            subtitle: const Text('Logo, nombre, RUC, encabezado de recibo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/business'),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Cajeros'),
            subtitle: const Text('PIN, roles, catálogo EN1'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/cashiers'),
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Impresora'),
            subtitle: const Text('Caja: Bluetooth o red (IP), cajón'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/printer'),
          ),
          ListTile(
            leading: const Icon(Icons.soup_kitchen_outlined),
            title: const Text('Producción (Cocina / Bar)'),
            subtitle: const Text('Destinos, impresora o pantalla, routing'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/production'),
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
            leading: const Icon(Icons.percent_outlined),
            title: const Text('Fiscal / Impuestos'),
            subtitle: const Text('Contrato ITBMS, tipo de establecimiento'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/tax'),
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
            leading: const Icon(Icons.restaurant_menu_outlined),
            title: const Text('Pedidos EN1'),
            subtitle: const Text('Hito 3B · Pedido offline + sync'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/orders'),
          ),
          ListTile(
            leading: const Icon(Icons.smartphone_outlined),
            title: const Text('Este dispositivo'),
            subtitle: const Text('UUID, modo, versión'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/platform/device'),
          ),
          ListTile(
            leading: const Icon(Icons.discount_outlined),
            title: const Text('Programas de descuento'),
            subtitle: const Text('Legal / comercial · Discount Domain V1'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/discounts'),
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
