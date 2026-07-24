import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/printing/production_destination.dart';
import 'package:eposone/src/core/printing/production_routing_store.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/products/presentation/providers/category_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';

/// Asigna categoría (default) y producto (override) → destino de producción.
class ProductionRoutingScreen extends ConsumerStatefulWidget {
  const ProductionRoutingScreen({super.key});

  @override
  ConsumerState<ProductionRoutingScreen> createState() =>
      _ProductionRoutingScreenState();
}

class _ProductionRoutingScreenState
    extends ConsumerState<ProductionRoutingScreen> {
  List<ProductionDestination> _dests = [];
  Map<String, String> _catRoutes = {};
  Map<String, String> _prodRoutes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dests = await ProductionDestinationStore.list();
    final cats = await ProductionRoutingStore.categoryRoutes();
    final prods = await ProductionRoutingStore.productRoutes();
    if (!mounted) return;
    setState(() {
      _dests = dests.where((d) => d.active).toList();
      _catRoutes = cats;
      _prodRoutes = prods;
      _loading = false;
    });
  }

  String? _labelFor(String? id) {
    if (id == null) return null;
    for (final d in _dests) {
      if (d.id == id) return d.name;
    }
    return '—';
  }

  Future<void> _pickDestination({
    required String title,
    required String? currentId,
    required Future<void> Function(String? id) onSave,
  }) async {
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Sin producción'),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            for (final d in _dests)
              ListTile(
                leading: Icon(
                  d.isScreen ? Icons.tv : Icons.print,
                  color: EposBrand.orange,
                ),
                title: Text(d.name),
                subtitle: Text('${d.areaLabel} · ${d.channelLabel}'),
                trailing: currentId == d.id
                    ? const Icon(Icons.check, color: EposBrand.orange)
                    : null,
                onTap: () => Navigator.pop(ctx, d.id),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await onSave(chosen.isEmpty ? null : chosen);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Routing producción')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dests.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Primero crea al menos un destino en Producción.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Categoría define el destino por defecto. '
                      'El producto puede sobreescribirlo.',
                      style: TextStyle(
                          fontSize: 13, color: EposBrand.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    const Text('Por categoría',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    categoriesAsync.when(
                      data: (cats) {
                        if (cats.isEmpty) {
                          return const Text('Sin categorías');
                        }
                        return Column(
                          children: [
                            for (final c in cats)
                              Card(
                                child: ListTile(
                                  title: Text(c.name),
                                  subtitle: Text(
                                    _labelFor(_catRoutes[c.localId]) ??
                                        'Sin destino',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _pickDestination(
                                    title: 'Categoría: ${c.name}',
                                    currentId: _catRoutes[c.localId],
                                    onSave: (id) => ProductionRoutingStore
                                        .setCategoryDestination(c.localId, id),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('$e'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Por producto (override)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    productsAsync.when(
                      data: (products) {
                        final active =
                            products.where((p) => p.isActive).toList();
                        if (active.isEmpty) {
                          return const Text('Sin productos');
                        }
                        return Column(
                          children: [
                            for (final p in active.take(80))
                              Card(
                                child: ListTile(
                                  title: Text(p.name),
                                  subtitle: Text(
                                    _prodRoutes.containsKey(p.localId)
                                        ? 'Override: ${_labelFor(_prodRoutes[p.localId])}'
                                        : (p.categoryId != null &&
                                                _catRoutes
                                                    .containsKey(p.categoryId)
                                            ? 'Hereda: ${_labelFor(_catRoutes[p.categoryId!])}'
                                            : 'Sin destino'),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _pickDestination(
                                    title: 'Producto: ${p.name}',
                                    currentId: _prodRoutes[p.localId],
                                    onSave: (id) => ProductionRoutingStore
                                        .setProductDestination(p.localId, id),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('$e'),
                    ),
                  ],
                ),
    );
  }
}
