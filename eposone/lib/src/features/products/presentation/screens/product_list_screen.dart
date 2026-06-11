import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = _searchQuery.isEmpty
        ? ref.watch(productsListProvider)
        : ref.watch(productsSearchProvider(_searchQuery));

    // Escuchar cambios del notifier para refrescar lista
    ref.listen(productNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) => ref.invalidate(productsListProvider),
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o SKU...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _showInactive = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: false, child: Text('Solo activos')),
              const PopupMenuItem(value: true, child: Text('Mostrar inactivos')),
            ],
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final filtered = _showInactive
              ? products
              : products.where((p) => p.isActive).toList();

          if (filtered.isEmpty) {
            return _EmptyState(
              isSearch: _searchQuery.isNotEmpty,
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final product = filtered[index];
              return _ProductCard(
                product: product,
                onTap: () => _editProduct(context, product),
                onToggleActive: () => ref.read(productNotifierProvider.notifier).toggleActive(product),
                onDelete: () => _confirmDelete(context, product),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  void _editProduct(BuildContext context, Product product) {
    context.push('/products/${product.localId}/edit');
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${product.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(productNotifierProvider.notifier).deleteProduct(product.localId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowStock = product.minStockAlert != null && product.stock <= product.minStockAlert!;
    final isOutOfStock = product.stock <= 0;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => onToggleActive(),
            backgroundColor: product.isActive ? Colors.orange : Colors.green,
            foregroundColor: Colors.white,
            icon: product.isActive ? Icons.visibility_off : Icons.visibility,
            label: product.isActive ? 'Desactivar' : 'Activar',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Eliminar',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        color: product.isActive ? null : colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Indicador de stock
                Container(
                  width: 8,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.red
                        : isLowStock
                            ? Colors.orange
                            : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: product.isActive ? null : TextDecoration.lineThrough,
                            ),
                      ),
                      if (product.barcode != null && product.barcode!.isNotEmpty)
                        Text(
                          'Código: ${product.barcode}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (product.sku != null && product.sku!.isNotEmpty)
                        Text(
                          'SKU: ${product.sku}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StockBadge(
                            stock: product.stock,
                            isLow: isLowStock,
                            isOut: isOutOfStock,
                          ),
                          const Spacer(),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final double stock;
  final bool isLow;
  final bool isOut;

  const _StockBadge({
    required this.stock,
    required this.isLow,
    required this.isOut,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOut
        ? Colors.red
        : isLow
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        'Stock: ${stock.toStringAsFixed(stock == stock.toInt() ? 0 : 2)}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  final VoidCallback onClearSearch;

  const _EmptyState({required this.isSearch, required this.onClearSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No se encontraron productos' : 'Sin productos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Intenta con otra búsqueda'
                : 'Agrega tu primer producto con el botón +',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          if (isSearch) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onClearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }
}