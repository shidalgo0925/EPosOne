import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/auth/presentation/screens/pin_screen.dart';
import 'package:eposone/src/features/platform/data/en1_cashier_catalog_store.dart';

final localCashiersListProvider = FutureProvider<List<Cashier>>((ref) async {
  return ref.watch(cashierRepositoryProvider).listAll();
});

/// CRUD local de cajeros (Standalone). Con catálogo EN1, solo lectura informativa.
class CashiersSettingsScreen extends ConsumerWidget {
  const CashiersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en1Async = ref.watch(_en1CashiersMetaProvider);
    final localAsync = ref.watch(localCashiersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cajeros')),
      body: en1Async.when(
        data: (en1) {
          if (en1.isNotEmpty) {
            return _En1CashiersReadOnly(cashiers: en1);
          }
          return localAsync.when(
            data: (cashiers) {
              if (cashiers.isEmpty) {
                return const Center(
                  child: Text(
                    'Sin cajeros locales',
                    style: TextStyle(color: EposBrand.textSecondary),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: cashiers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = cashiers[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?'),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${c.role == CashierRole.admin ? 'Admin' : 'Cajero'}'
                      '${c.active ? '' : ' · inactivo'}',
                    ),
                    trailing: Switch(
                      value: c.active,
                      onChanged: (v) async {
                        await ref.read(cashierRepositoryProvider).updateCashier(
                              localId: c.localId,
                              active: v,
                            );
                        ref.invalidate(localCashiersListProvider);
                        ref.invalidate(loginCashiersProvider);
                      },
                    ),
                    onTap: () => _showEdit(context, ref, c),
                    onLongPress: () => _confirmDelete(context, ref, c),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: en1Async.maybeWhen(
        data: (en1) => en1.isEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _showCreate(context, ref),
                icon: const Icon(Icons.person_add),
                label: const Text('Nuevo cajero'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Future<void> _showCreate(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    var role = CashierRole.cashier;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuevo cajero'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: 'PIN (mín. 4)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CashierRole>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: CashierRole.cashier, child: Text('Cajero')),
                    DropdownMenuItem(value: CashierRole.admin, child: Text('Admin')),
                  ],
                  onChanged: (v) => setLocal(() => role = v ?? role),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final pin = pinCtrl.text.trim();
    if (name.isEmpty || pin.length < 4) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre y PIN (mín. 4) requeridos')),
        );
      }
      return;
    }

    await ref.read(cashierRepositoryProvider).createCashier(
          name: name,
          pin: pin,
          role: role,
        );
    ref.invalidate(localCashiersListProvider);
    ref.invalidate(loginCashiersProvider);
  }

  Future<void> _showEdit(BuildContext context, WidgetRef ref, Cashier c) async {
    final nameCtrl = TextEditingController(text: c.name);
    final pinCtrl = TextEditingController();
    var role = c.role;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Editar cajero'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CashierRole>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: CashierRole.cashier, child: Text('Cajero')),
                    DropdownMenuItem(value: CashierRole.admin, child: Text('Admin')),
                  ],
                  onChanged: (v) => setLocal(() => role = v ?? role),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo PIN (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    await ref.read(cashierRepositoryProvider).updateCashier(
          localId: c.localId,
          name: name,
          role: role,
        );
    final newPin = pinCtrl.text.trim();
    if (newPin.length >= 4) {
      await ref.read(cashierRepositoryProvider).changePin(
            localId: c.localId,
            newPin: newPin,
          );
    }
    ref.invalidate(localCashiersListProvider);
    ref.invalidate(loginCashiersProvider);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Cashier c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cajero'),
        content: Text('¿Eliminar a ${c.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(cashierRepositoryProvider).softDelete(c.localId);
    ref.invalidate(localCashiersListProvider);
    ref.invalidate(loginCashiersProvider);
  }
}

final _en1CashiersMetaProvider =
    FutureProvider<List<En1CashierLocal>>((ref) async {
  return En1CashierCatalogStore.listMetaOnly();
});

class _En1CashiersReadOnly extends StatelessWidget {
  final List<En1CashierLocal> cashiers;
  const _En1CashiersReadOnly({required this.cashiers});

  @override
  Widget build(BuildContext context) {
    final active = cashiers.where((c) => c.isActive).toList();
    final inactive = cashiers.where((c) => !c.isActive).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Catálogo EN1 activo. Alta, PIN y roles se administran en el Back Office. '
              'El POS solo autentica con el verificador sincronizado.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Activos', style: TextStyle(fontWeight: FontWeight.bold)),
        ...active.map(
          (c) => ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(c.cashierName),
            subtitle: Text(
              [
                if (c.cashierCode != null) c.cashierCode!,
                'ID ${c.cashierContactId}',
                'PIN v${c.pinVersion}',
              ].join(' · '),
            ),
          ),
        ),
        if (inactive.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Inactivos', style: TextStyle(fontWeight: FontWeight.bold)),
          ...inactive.map(
            (c) => ListTile(
              leading: const Icon(Icons.person_off_outlined, color: Colors.grey),
              title: Text(c.cashierName, style: const TextStyle(color: Colors.grey)),
              subtitle: Text('ID ${c.cashierContactId}'),
            ),
          ),
        ],
      ],
    );
  }
}
