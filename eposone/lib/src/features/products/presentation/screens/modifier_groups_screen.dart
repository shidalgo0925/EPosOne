import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/products/data/repositories/modifier_repository.dart';
import 'package:eposone/src/features/products/domain/entities/modifier.dart';
import 'package:eposone/src/features/products/domain/entities/modifier_group.dart';
import 'package:eposone/src/features/products/presentation/providers/modifier_provider.dart';

class ModifierGroupsScreen extends ConsumerWidget {
  const ModifierGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(modifierGroupsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modificadores')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/settings/modifiers/new'),
        child: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Text(
                'Sin grupos de modificadores.\nEj: Extras, Tamaño, Sin...',
                textAlign: TextAlign.center,
                style: TextStyle(color: EposBrand.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final g = groups[i];
              return Card(
                child: ListTile(
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    g.isSingleChoice
                        ? 'Elección única${g.isRequired ? ' · Obligatorio' : ''}'
                        : 'Múltiple (máx. ${g.maxSelect})${g.isRequired ? ' · Obligatorio' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/modifiers/${g.localId}/edit'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class ModifierGroupFormScreen extends ConsumerStatefulWidget {
  final String? groupId;
  const ModifierGroupFormScreen({super.key, this.groupId});

  @override
  ConsumerState<ModifierGroupFormScreen> createState() => _ModifierGroupFormScreenState();
}

class _ModifierOptionRow {
  String? id;
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: '0');
  bool isDefault;

  _ModifierOptionRow({this.id, String name = '', double price = 0, this.isDefault = false}) {
    nameCtrl.text = name;
    priceCtrl.text = price.toStringAsFixed(2);
  }

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _ModifierGroupFormScreenState extends ConsumerState<ModifierGroupFormScreen> {
  final _nameCtrl = TextEditingController();
  bool _required = false;
  bool _singleChoice = true;
  bool _loading = false;
  final _options = <_ModifierOptionRow>[];

  bool get _isEdit => widget.groupId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _load();
    } else {
      _options.add(_ModifierOptionRow());
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ref.read(modifierRepositoryProvider);
    final group = await repo.getGroupById(widget.groupId!);
    if (group != null && mounted) {
      _nameCtrl.text = group.name;
      _required = group.isRequired;
      _singleChoice = group.isSingleChoice;
      final mods = await repo.getModifiersForGroup(group.localId);
      _options.clear();
      for (final m in mods) {
        _options.add(_ModifierOptionRow(id: m.localId, name: m.name, price: m.priceDelta, isDefault: m.isDefault));
      }
      if (_options.isEmpty) _options.add(_ModifierOptionRow());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indica un nombre de grupo')));
      return;
    }
    final validOptions = _options.where((o) => o.nameCtrl.text.trim().isNotEmpty).toList();
    if (validOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos una opción')));
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(modifierRepositoryProvider);
      final existing = _isEdit ? await repo.getGroupById(widget.groupId!) : null;
      final group = existing != null
          ? existing
              .copyWith(
                name: name,
                minSelect: _required ? 1 : 0,
                maxSelect: _singleChoice ? 1 : 99,
              )
              .markAsModified()
          : ModifierGroup.create(
              name: name,
              minSelect: _required ? 1 : 0,
              maxSelect: _singleChoice ? 1 : 99,
            );

      await repo.saveGroup(group);

      final existingMods = _isEdit ? await repo.getModifiersForGroup(group.localId) : <Modifier>[];
      final keptIds = validOptions.map((o) => o.id).whereType<String>().toSet();
      for (final old in existingMods) {
        if (!keptIds.contains(old.localId)) {
          await repo.deleteModifier(old.localId);
        }
      }

      for (var i = 0; i < validOptions.length; i++) {
        final row = validOptions[i];
        final price = double.tryParse(row.priceCtrl.text.replaceAll(',', '')) ?? 0;
        if (row.id != null) {
          final old = existingMods.firstWhere((m) => m.localId == row.id);
          await repo.saveModifier(
            old.copyWith(name: row.nameCtrl.text.trim(), priceDelta: price, isDefault: row.isDefault, sortOrder: i).markAsModified(),
          );
        } else {
          await repo.saveModifier(
            Modifier.create(
              groupId: group.localId,
              name: row.nameCtrl.text.trim(),
              priceDelta: price,
              isDefault: row.isDefault,
              sortOrder: i,
            ),
          );
        }
      }

      ref.invalidate(modifierGroupsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grupo guardado'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: const Text('Se quitará de todos los productos vinculados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await ref.read(modifierRepositoryProvider).deleteGroup(widget.groupId!);
    ref.invalidate(modifierGroupsListProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar grupo' : 'Nuevo grupo'),
        actions: [
          if (_isEdit)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _loading ? null : _delete),
        ],
      ),
      body: _loading && _isEdit && _options.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del grupo', hintText: 'Ej: Extras, Tamaño'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Obligatorio'),
                    value: _required,
                    onChanged: (v) => setState(() => _required = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Elección única'),
                    subtitle: const Text('Desactivar para permitir varias opciones'),
                    value: _singleChoice,
                    onChanged: (v) => setState(() => _singleChoice = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('Opciones', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._options.map(
                    (row) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(
                              controller: row.nameCtrl,
                              decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Extra queso'),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: row.priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Precio adicional', prefixText: 'B/. '),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Preseleccionado'),
                                value: row.isDefault,
                                onChanged: (v) => setState(() => row.isDefault = v ?? false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _options.add(_ModifierOptionRow())),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar opción'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar grupo'),
                  ),
                ],
              ),
            ),
    );
  }
}
