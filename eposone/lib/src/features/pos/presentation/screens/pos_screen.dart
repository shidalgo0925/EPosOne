import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';
import 'package:eposone/src/features/pos/presentation/widgets/pos_product_grid.dart';
import 'package:eposone/src/features/pos/presentation/widgets/pos_ticket_panel.dart';
import 'package:eposone/src/features/pos/presentation/utils/pos_layout.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/presentation/providers/category_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PosLayout.lockLandscapeIfTablet(context);
    });
  }

  @override
  void dispose() {
    PosLayout.unlockOrientations();
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: EposOneLogo(fontSize: 22),
                ),
                ListTile(
                  leading: Icon(Icons.point_of_sale, color: EposBrand.orange),
                  title: const Text('Ventas / POS'),
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: Icon(Icons.inventory_2, color: EposBrand.navy),
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
      },
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
    final trackInventory = config?.trackInventory ?? false;
    final productsAsync = _searchQuery.isEmpty
        ? ref.watch(productsListProvider)
        : ref.watch(productsSearchProvider(_searchQuery));
    final categoriesAsync = ref.watch(categoriesProvider);
    final cart = ref.watch(cartProvider);
    final isTablet = PosLayout.isTablet(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gridColumns = isTablet
        ? PosLayout.gridColumns(screenWidth * 0.6)
        : PosLayout.gridColumns(screenWidth);

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
          const OpenTicketsButton(),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Guardar ticket',
            onPressed: cart.items.isEmpty
                ? null
                : () async {
                    try {
                      await ref.read(openTicketActionsProvider).saveCurrentCart();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket guardado')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
      body: isTablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: _CatalogPane(
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    categoryFilter: _categoryFilter,
                    categoriesAsync: categoriesAsync,
                    productsAsync: productsAsync,
                    symbol: symbol,
                    trackInventory: trackInventory,
                    crossAxisCount: gridColumns,
                    onSearchChanged: (v) => setState(() => _searchQuery = v),
                    onCategoryChanged: (id) => setState(() => _categoryFilter = id),
                    onProductTap: _addProduct,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: const PosTicketPanel(expanded: true),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: _CatalogPane(
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    categoryFilter: _categoryFilter,
                    categoriesAsync: categoriesAsync,
                    productsAsync: productsAsync,
                    symbol: symbol,
                    trackInventory: trackInventory,
                    crossAxisCount: gridColumns,
                    onSearchChanged: (v) => setState(() => _searchQuery = v),
                    onCategoryChanged: (id) => setState(() => _categoryFilter = id),
                    onProductTap: _addProduct,
                  ),
                ),
                if (cart.items.isNotEmpty)
                  SizedBox(
                    height: 220 + ViewInsets.bottom(context),
                    child: PosTicketPanel(expanded: false),
                  ),
              ],
            ),
    );
  }
}

class _CatalogPane extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String? categoryFilter;
  final AsyncValue<List<Category>> categoriesAsync;
  final AsyncValue<List<Product>> productsAsync;
  final String symbol;
  final bool trackInventory;
  final int crossAxisCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<Product> onProductTap;

  const _CatalogPane({
    required this.searchController,
    required this.searchQuery,
    required this.categoryFilter,
    required this.categoriesAsync,
    required this.productsAsync,
    required this.symbol,
    required this.trackInventory,
    required this.crossAxisCount,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Buscar nombre, SKU o código...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: onSearchChanged,
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
                    selected: categoryFilter == null,
                    onSelected: (_) => onCategoryChanged(null),
                  ),
                ),
                ...categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c.name),
                      selected: categoryFilter == c.localId,
                      onSelected: (_) => onCategoryChanged(c.localId),
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
              var list = products.where((Product p) => p.isActive).toList();
              if (categoryFilter != null) {
                list = list.where((Product p) => p.categoryId == categoryFilter).toList();
              }
              return PosProductGrid(
                products: list,
                symbol: symbol,
                trackInventory: trackInventory,
                crossAxisCount: crossAxisCount,
                onProductTap: onProductTap,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
