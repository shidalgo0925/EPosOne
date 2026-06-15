import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/pos/data/repositories/pos_page_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page_item.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_page_provider.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/category_provider.dart';

class PosPagesSettingsScreen extends ConsumerWidget {
  const PosPagesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(posPagesAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Páginas POS')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/settings/pos-pages/new'),
        child: const Icon(Icons.add),
      ),
      body: pagesAsync.when(
        data: (pages) {
          if (pages.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Sin páginas configuradas.\nEl POS mostrará el catálogo completo con filtro por categoría.\n\nCrea al menos 2 páginas para activar pestañas en el TPV.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: EposBrand.textSecondary),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: pages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final page = pages[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: EposBrand.orange.withValues(alpha: 0.15),
                    child: Text('${i + 1}', style: const TextStyle(color: EposBrand.navy, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(page.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(page.isActive ? 'Activa' : 'Inactiva'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/pos-pages/${page.localId}/edit'),
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

class _PageItemDraft {
  PosPageItemType type;
  String refId;
  String label;

  _PageItemDraft({required this.type, required this.refId, required this.label});
}

class PosPageFormScreen extends ConsumerStatefulWidget {
  final String? pageId;
  const PosPageFormScreen({super.key, this.pageId});

  @override
  ConsumerState<PosPageFormScreen> createState() => _PosPageFormScreenState();
}

class _PosPageFormScreenState extends ConsumerState<PosPageFormScreen> {
  final _nameCtrl = TextEditingController();
  bool _isActive = true;
  bool _loading = false;
  final _items = <_PageItemDraft>[];

  bool get _isEdit => widget.pageId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ref.read(posPageRepositoryProvider);
    final page = await repo.getPageById(widget.pageId!);
    if (page == null || !mounted) {
      setState(() => _loading = false);
      return;
    }

    _nameCtrl.text = page.name;
    _isActive = page.isActive;

    final items = await repo.getItems(page.localId);
    final products = await ref.read(productsListProvider.future);
    final categories = await ref.read(categoriesListProvider.future);
    _items.clear();

    for (final item in items) {
      final label = item.itemType == PosPageItemType.product
          ? products.firstWhere((p) => p.localId == item.refId, orElse: () => Product.create(name: '?', price: 0)).name
          : categories.firstWhere((c) => c.localId == item.refId, orElse: () => Category.create(name: '?')).name;
      _items.add(_PageItemDraft(type: item.itemType, refId: item.refId, label: label));
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final products = await ref.read(productsListProvider.future);
    final active = products.where((p) => p.isActive).toList();
    if (!mounted) return;

    final picked = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PickerSheet<Product>(
        title: 'Agregar producto',
        items: active,
        label: (p) => p.name,
      ),
    );
    if (picked == null) return;
    setState(() => _items.add(_PageItemDraft(type: PosPageItemType.product, refId: picked.localId, label: picked.name)));
  }

  Future<void> _pickCategory() async {
    final categories = await ref.read(categoriesListProvider.future);
    if (!mounted) return;

    final picked = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PickerSheet<Category>(
        title: 'Agregar categoría',
        items: categories,
        label: (c) => c.name,
      ),
    );
    if (picked == null) return;
    setState(() => _items.add(_PageItemDraft(type: PosPageItemType.category, refId: picked.localId, label: picked.name)));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indica un nombre de página')));
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(posPageRepositoryProvider);
      final existing = _isEdit ? await repo.getPageById(widget.pageId!) : null;
      final page = existing != null
          ? existing.copyWith(name: name, isActive: _isActive).markAsModified()
          : PosPage.create(name: name, sortOrder: DateTime.now().millisecondsSinceEpoch).copyWith(isActive: _isActive);

      await repo.savePage(page);

      final isarItems = _items
          .asMap()
          .entries
          .map(
            (e) => PosPageItem.create(
              pageId: page.localId,
              itemType: e.value.type,
              refId: e.value.refId,
              sortOrder: e.key,
            ),
          )
          .toList();
      await repo.setPageItems(page.localId, isarItems);

      ref.invalidate(posPagesAdminProvider);
      ref.invalidate(posPagesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Página guardada'), backgroundColor: Colors.green));
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
        title: const Text('Eliminar página'),
        content: const Text('Esta página dejará de aparecer en el POS.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await ref.read(posPageRepositoryProvider).deletePage(widget.pageId!);
    ref.invalidate(posPagesAdminProvider);
    ref.invalidate(posPagesListProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar página' : 'Nueva página'),
        actions: [
          if (_isEdit) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _loading ? null : _delete),
        ],
      ),
      body: _loading && _isEdit && _items.isEmpty && _nameCtrl.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre de la página', hintText: 'Ej: Principal, Bebidas'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activa en POS'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('Contenido', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text(
                    'Vacío = todos los productos. Agrega productos o categorías en el orden deseado.',
                    style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Sin ítems — mostrará todo el catálogo', style: TextStyle(color: EposBrand.textSecondary)),
                    ),
                  ..._items.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          item.type == PosPageItemType.product ? Icons.inventory_2_outlined : Icons.folder_outlined,
                          color: EposBrand.navy,
                        ),
                        title: Text(item.label),
                        subtitle: Text(item.type == PosPageItemType.product ? 'Producto' : 'Categoría completa'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              onPressed: idx == 0
                                  ? null
                                  : () => setState(() {
                                        final tmp = _items[idx - 1];
                                        _items[idx - 1] = _items[idx];
                                        _items[idx] = tmp;
                                      }),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => setState(() => _items.removeAt(idx)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickProduct,
                          icon: const Icon(Icons.add),
                          label: const Text('Producto'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickCategory,
                          icon: const Icon(Icons.folder_outlined),
                          label: const Text('Categoría'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar página'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) label;

  const _PickerSheet({required this.title, required this.items, required this.label});

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = widget.items.where((i) => widget.label(i).toLowerCase().contains(q)).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar...'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: filtered.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(widget.label(filtered[i])),
                onTap: () => Navigator.pop(context, filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
