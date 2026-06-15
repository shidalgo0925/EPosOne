import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/utils/save_open_ticket_flow.dart';
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

  Future<void> _scanBarcode() async {
    final code = await context.push<String>('/pos/scan');
    if (code == null || !mounted) return;

    final product = await ref.read(productByBarcodeProvider(code).future);
    if (!mounted) return;

    if (product == null || !product.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto no encontrado: $code'), backgroundColor: Colors.orange),
      );
      return;
    }

    _addProduct(product);
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
                  child: Row(
                    children: [
                      EposBrandIcon(size: 28),
                      SizedBox(width: 10),
                      EposOneLogo(fontSize: 22),
                    ],
                  ),
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
                  title: const Text('Turno / Caja'),
                  subtitle: const Text('Resumen, tesorería, cierre'),
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
        ? PosLayout.gridColumns(screenWidth * 0.68)
        : PosLayout.gridColumns(screenWidth);

    ref.listen(currentCashRegisterProvider, (prev, next) {
      next.whenData((reg) {
        final s = ref.read(posSessionProvider);
        if (reg == null && s?.cashRegisterId != null && mounted) {
          ref.read(posSessionProvider.notifier).clearCashRegister();
          context.go('/cash/open');
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isTablet ? 44 : kToolbarHeight,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: _openMenu),
        title: isTablet
            ? Text(config?.businessName ?? 'EPOSOne', style: const TextStyle(fontSize: 15))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config?.businessName ?? 'EPOSOne', style: const TextStyle(fontSize: 16)),
                  Text(session.cashierName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                ],
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            tooltip: 'Escanear código',
            onPressed: _scanBarcode,
          ),
          if (ref.watch(businessConfigProvider)?.openTicketsEnabled ?? true)
            IconButton(
              icon: const Icon(Icons.save_outlined, size: 22),
              tooltip: 'Guardar ticket',
              onPressed: cart.items.isEmpty
                  ? null
                  : () async {
                      try {
                        await saveOpenTicketFlow(context, ref);
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
      body: Column(
        children: [
          if (session.cashRegisterId != null)
            Container(
              height: 28,
              color: EposBrand.orange.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 14, color: EposBrand.orange.withValues(alpha: 0.9)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Turno abierto',
                      style: TextStyle(fontSize: 11, color: EposBrand.navy),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () => context.push('/cash-register'),
                    child: const Text('Ver turno'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () => context.push('/cash-register/close'),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isTablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
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
                  flex: 3,
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
        SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
            child: Row(
              children: [
                categoriesAsync.when(
                  data: (categories) => _CategoryDropdown(
                    categories: categories,
                    selectedId: categoryFilter,
                    onChanged: onCategoryChanged,
                  ),
                  loading: () => const SizedBox(width: 140, height: 36),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: const TextStyle(fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: EposBrand.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: EposBrand.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: EposBrand.divider),
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
              ],
            ),
          ),
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

class _CategoryDropdown extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  String _label() {
    if (selectedId == null) return 'Todos los artículos';
    for (final c in categories) {
      if (c.localId == selectedId) return c.name;
    }
    return 'Todos los artículos';
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      initialValue: selectedId,
      tooltip: 'Categoría',
      onSelected: onChanged,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: EposBrand.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EposBrand.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _label(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18, color: EposBrand.textSecondary),
          ],
        ),
      ),
      itemBuilder: (ctx) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('Todos los artículos'),
        ),
        ...categories.map(
          (c) => PopupMenuItem<String?>(
            value: c.localId,
            child: Text(c.name),
          ),
        ),
      ],
    );
  }
}
