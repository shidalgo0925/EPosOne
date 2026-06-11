import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/presentation/providers/category_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addProduct(Product product) {
    final config = ref.read(businessConfigProvider);
    if (config?.trackInventory == true && product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name}: sin stock'), backgroundColor: Colors.red),
      );
      return;
    }

    final cart = ref.read(cartProvider);
    final existing = cart.items.where((i) => i.product.localId == product.localId);
    final qtyInCart = existing.isEmpty ? 0.0 : existing.first.quantity;
    if (config?.trackInventory == true && qtyInCart + 1 > product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuficiente: ${product.name}'), backgroundColor: Colors.orange),
      );
      return;
    }

    ref.read(cartProvider.notifier).addProduct(product);
    ref.read(posSessionProvider.notifier).touch();
  }

  void _openMenu() {
    final session = ref.read(posSessionProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Ventas / POS'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Productos'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/products');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Clientes'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/customers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Historial'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/sales');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Caja'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/cash-register');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/settings');
              },
            ),
            if (session?.role == CashierRole.admin)
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Panel admin'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/admin');
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Bloquear pantalla'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(posSessionProvider.notifier).lock();
                context.go('/pin');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(posSessionProvider);
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pin');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';
    final productsAsync = _searchQuery.isEmpty
        ? ref.watch(productsListProvider)
        : ref.watch(productsSearchProvider(_searchQuery));
    final categoriesAsync = ref.watch(categoriesProvider);
    final cart = ref.watch(cartProvider);
    final totals = ref.watch(saleTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: _openMenu),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config?.businessName ?? 'EPOSOne', style: const TextStyle(fontSize: 16)),
            Text(session.cashierName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar nombre, SKU o código...',
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          categoriesAsync.when(
            data: (categories) => SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Todos'),
                      selected: _categoryFilter == null,
                      onSelected: (_) => setState(() => _categoryFilter = null),
                    ),
                  ),
                  ...categories.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: _categoryFilter == c.localId,
                        onSelected: (_) => setState(() => _categoryFilter = c.localId),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 44),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                var list = products.where((p) => p.isActive).toList();
                if (_categoryFilter != null) {
                  list = list.where((p) => p.categoryId == _categoryFilter).toList();
                }
                if (list.isEmpty) {
                  return const Center(child: Text('Sin productos'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final out = p.stock <= 0;
                    return Material(
                      color: out ? Colors.grey.shade900 : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: out ? null : () => _addProduct(p),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, color: out ? Colors.grey : null),
                              ),
                              const Spacer(),
                              if (config?.trackInventory == true)
                                Text(
                                  out ? 'Sin stock' : 'Stock: ${p.stock.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 11, color: out ? Colors.red : Colors.grey),
                                ),
                              Text(
                                '$symbol${p.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: out ? Colors.grey : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          if (cart.items.isNotEmpty) _TicketPanel(symbol: symbol, totals: totals, cart: cart),
        ],
      ),
    );
  }
}

class _TicketPanel extends ConsumerWidget {
  final String symbol;
  final SaleTotals totals;
  final CartState cart;

  const _TicketPanel({required this.symbol, required this.totals, required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cart.items.length,
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text('${item.quantity.toStringAsFixed(0)} x $symbol${item.unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Row(
                            children: [
                              Text('$symbol${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              InkWell(
                                onTap: () => ref.read(cartProvider.notifier).removeItem(item.id),
                                child: const Icon(Icons.close, size: 16, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${cart.itemCount} items', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('$symbol${totals.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => ref.read(cartProvider.notifier).clear(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Limpiar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => context.push('/payment'),
                    style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
                    child: const Text('Cobrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
