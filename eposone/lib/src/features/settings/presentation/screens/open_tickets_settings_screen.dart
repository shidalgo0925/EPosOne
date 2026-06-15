import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/features/pos/data/repositories/predefined_ticket_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/domain/entities/predefined_ticket.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';

final predefinedTicketsAdminProvider = FutureProvider<List<PredefinedTicket>>((ref) async {
  return ref.watch(predefinedTicketRepositoryProvider).getAll();
});

class OpenTicketsSettingsScreen extends ConsumerStatefulWidget {
  const OpenTicketsSettingsScreen({super.key});

  @override
  ConsumerState<OpenTicketsSettingsScreen> createState() => _OpenTicketsSettingsScreenState();
}

class _OpenTicketsSettingsScreenState extends ConsumerState<OpenTicketsSettingsScreen> {
  bool _saving = false;

  Future<void> _saveConfig({
    bool? openTicketsEnabled,
    bool? usePredefinedTickets,
    OrderType? defaultOrderType,
  }) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(businessConfigRepositoryProvider);
      final config = await repo.getConfig();
      await repo.saveConfig(config.copyWith(
        openTicketsEnabled: openTicketsEnabled,
        usePredefinedTickets: usePredefinedTickets,
        defaultOrderType: defaultOrderType,
      ));
      ref.invalidate(businessConfigAsyncProvider);
      ref.invalidate(availablePredefinedSlotsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPredefined() async {
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo ticket predefinido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *', hintText: 'Mesa 1, Barra 2…'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: groupCtrl,
              decoration: const InputDecoration(labelText: 'Grupo (opcional)', hintText: 'Mesas, Barra…'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final list = await ref.read(predefinedTicketRepositoryProvider).getAll();
    await ref.read(predefinedTicketRepositoryProvider).save(
          PredefinedTicket.create(
            name: nameCtrl.text.trim(),
            groupName: groupCtrl.text.trim().isEmpty ? null : groupCtrl.text.trim(),
            sortOrder: list.length,
          ),
        );
    ref.invalidate(predefinedTicketsAdminProvider);
    ref.invalidate(availablePredefinedSlotsProvider);
  }

  Future<void> _editPredefined(PredefinedTicket ticket) async {
    final nameCtrl = TextEditingController(text: ticket.name);
    final groupCtrl = TextEditingController(text: ticket.groupName ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar ticket predefinido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre *')),
            const SizedBox(height: 12),
            TextField(controller: groupCtrl, decoration: const InputDecoration(labelText: 'Grupo')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok != true || nameCtrl.text.trim().isEmpty) return;

    await ref.read(predefinedTicketRepositoryProvider).save(
          ticket.copyWith(
            name: nameCtrl.text.trim(),
            groupName: groupCtrl.text.trim().isEmpty ? null : groupCtrl.text.trim(),
            clearGroupName: groupCtrl.text.trim().isEmpty,
          ),
        );
    ref.invalidate(predefinedTicketsAdminProvider);
    ref.invalidate(availablePredefinedSlotsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(businessConfigAsyncProvider);
    final ticketsAsync = ref.watch(predefinedTicketsAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tickets abiertos')),
      body: configAsync.when(
        data: (config) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Habilitar tickets abiertos'),
              subtitle: const Text('Permite guardar ventas pendientes de cobro'),
              value: config.openTicketsEnabled,
              onChanged: _saving ? null : (v) => _saveConfig(openTicketsEnabled: v),
            ),
            SwitchListTile(
              title: const Text('Usar tickets predefinidos'),
              subtitle: const Text('Lista fija de nombres (Mesa 1, Barra 2…)'),
              value: config.usePredefinedTickets,
              onChanged: !config.openTicketsEnabled || _saving
                  ? null
                  : (v) => _saveConfig(usePredefinedTickets: v),
            ),
            ListTile(
              title: const Text('Tipo de orden por defecto'),
              trailing: DropdownButton<OrderType>(
                value: config.defaultOrderType,
                items: OrderType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(orderTypeLabel(t))))
                    .toList(),
                onChanged: _saving ? null : (v) => _saveConfig(defaultOrderType: v),
              ),
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Text('Nombres predefinidos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: _addPredefined, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 8),
            ticketsAsync.when(
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Sin nombres predefinidos. Agrega Mesa 1, Barra 2, Ticket 001…',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tickets.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final items = [...tickets];
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);
                    await ref.read(predefinedTicketRepositoryProvider).reorder(items);
                    ref.invalidate(predefinedTicketsAdminProvider);
                  },
                  itemBuilder: (_, i) {
                    final t = tickets[i];
                    return ListTile(
                      key: ValueKey(t.localId),
                      leading: const Icon(Icons.drag_handle),
                      title: Text(t.name),
                      subtitle: t.groupName != null ? Text(t.groupName!) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: t.isActive,
                            onChanged: (v) async {
                              await ref.read(predefinedTicketRepositoryProvider).save(t.copyWith(isActive: v));
                              ref.invalidate(predefinedTicketsAdminProvider);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editPredefined(t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await ref.read(predefinedTicketRepositoryProvider).delete(t.localId);
                              ref.invalidate(predefinedTicketsAdminProvider);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
