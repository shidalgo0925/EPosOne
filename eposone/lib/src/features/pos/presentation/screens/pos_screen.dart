import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';
import 'package:eposone/src/features/auth/domain/cashier_display.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/auth/presentation/utils/cashier_session_guard.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/utils/save_open_ticket_flow.dart';
import 'package:eposone/src/features/pos/presentation/widgets/pos_product_grid.dart';
import 'package:eposone/src/features/pos/presentation/widgets/pos_ticket_panel.dart';
import 'package:eposone/src/features/pos/presentation/widgets/open_tickets_sheet.dart';
import 'package:eposone/src/features/pos/presentation/utils/pos_layout.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/presentation/providers/category_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/products/data/repositories/modifier_repository.dart';
import 'package:eposone/src/features/products/domain/entities/selected_modifier.dart';
import 'package:eposone/src/features/pos/presentation/widgets/modifier_picker_sheet.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_page_provider.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page_item.dart';
import 'package:eposone/src/features/pos/data/repositories/pos_page_repository.dart';
import 'package:eposone/src/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:eposone/src/features/sync/presentation/providers/en1_connection_status.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';
import 'package:eposone/src/features/sync/presentation/widgets/en1_status_chip.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_repository.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter;
  String? _selectedPageId;
  bool _pageRepairTried = false;
  /// Solo phone: ticket sheet expandido (swipe ↑). Tablet no lo usa.
  bool _phoneTicketOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PosLayout.lockLandscapeIfTablet(context);
      _maybeRepairEmptyEn1Pages();
      enforceActiveEn1CashierSession(ref, context: context);
    });
  }

  /// Si Comida/Bar EN1 están rotas (sin productos o sin categorías), reparar sin red.
  Future<void> _maybeRepairEmptyEn1Pages() async {
    if (_pageRepairTried || !mounted) return;
    _pageRepairTried = true;
    try {
      final pages = await ref.read(posPagesListProvider.future);
      final en1Pages =
          pages.where((p) => p.localId.startsWith('en1_page_')).toList();
      if (en1Pages.isEmpty) return;

      final repo = ref.read(posPageRepositoryProvider);
      final products = await ref.read(productsListProvider.future);
      final active = products.where((p) => p.isActive).toList();
      final allCats = await ref.read(categoriesProvider.future);
      final catById = {for (final c in allCats) c.localId: c};
      var needsRepair = false;
      for (final page in en1Pages) {
        final resolved =
            await repo.resolveProductsForPage(page.localId, active);
        final items = await repo.getItems(page.localId);
        final hasProductItem =
            items.any((i) => i.itemType == PosPageItemType.product);
        final hasCatItem =
            items.any((i) => i.itemType == PosPageItemType.category);
        if (!hasProductItem && hasCatItem) {
          final viaCat = active.where(
            (p) => items.any(
              (i) =>
                  i.itemType == PosPageItemType.category &&
                  p.categoryId == i.refId,
            ),
          );
          if (viaCat.isEmpty) needsRepair = true;
        }
        if (items.isEmpty && resolved.isEmpty) needsRepair = true;
        // Productos sí, categorías no → chips vacíos (regresión recurrente).
        if (resolved.isNotEmpty && !hasCatItem) {
          final hasDerivedCat = resolved.any(
            (p) => p.categoryId != null && catById.containsKey(p.categoryId),
          );
          if (hasDerivedCat) needsRepair = true;
        }
        if (hasCatItem) {
          final resolvedCats = items.where(
            (i) =>
                i.itemType == PosPageItemType.category &&
                catById.containsKey(i.refId),
          );
          if (resolvedCats.isEmpty && resolved.isNotEmpty) needsRepair = true;
        }
      }
      if (!needsRepair) return;

      final isar = await ref.read(databaseProvider.future);
      await En1BootstrapRepository(isar: isar).repairEn1PosPagesFromLocal();
      ref.invalidate(posPagesListProvider);
      ref.invalidate(productsListProvider);
      ref.invalidate(categoriesProvider);
      if (mounted) setState(() {});
    } catch (_) {
      // Silencioso: el cajero puede reparar desde Este dispositivo.
    }
  }

  @override
  void dispose() {
    PosLayout.unlockOrientations();
    _searchController.dispose();
    super.dispose();
  }

  void _addProduct(Product product) async {
    final config = ref.read(businessConfigProvider);
    if (config?.trackInventory == true && product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${product.name}: sin stock'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final cart = ref.read(cartProvider);
    final existing =
        cart.items.where((i) => i.product.localId == product.localId);
    final qtyInCart =
        existing.isEmpty ? 0.0 : existing.fold(0.0, (s, i) => s + i.quantity);
    if (config?.trackInventory == true && qtyInCart + 1 > product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Stock insuficiente: ${product.name}'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final modifierRepo = ref.read(modifierRepositoryProvider);
    final groups = await modifierRepo.getGroupsForProduct(product.localId);
    if (!mounted) return;

    List<SelectedModifier> modifiers = const [];
    if (groups.isNotEmpty) {
      final selected = await showModifierPickerSheet(
        context,
        groups: groups,
        symbol: config?.currencySymbol ?? 'B/.',
        engine: ref.read(commercialEngineProvider),
      );
      if (selected == null || !mounted) return;
      modifiers = selected;
    }

    ref.read(cartProvider.notifier).addProduct(product, modifiers: modifiers);
    ref.read(posSessionProvider.notifier).touch();
  }

  Future<void> _scanBarcode() async {
    final code = await context.push<String>('/pos/scan');
    if (code == null || !mounted) return;

    final product = await ref.read(productByBarcodeProvider(code).future);
    if (!mounted) return;

    if (product == null || !product.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Producto no encontrado: $code'),
            backgroundColor: Colors.orange),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Categorías'),
                  subtitle: const Text('Organizar catálogo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/categories');
                  },
                ),
                if (ref.read(businessConfigProvider)?.openTicketsEnabled ??
                    true)
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Tickets abiertos'),
                    subtitle: const Text('Recuperar tickets guardados'),
                    onTap: () {
                      Navigator.pop(ctx);
                      showOpenTicketsSheet(context, ref);
                    },
                  ),
                if (ref.read(businessConfigProvider)?.trackInventory == true)
                  ListTile(
                    leading: const Icon(Icons.warehouse_outlined),
                    title: const Text('Inventario'),
                    subtitle: const Text('Bajo stock, ajustes'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/inventory');
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
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('Reportes'),
                  subtitle: const Text('Ventas, consultar e imprimir'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/reports');
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
                if (ref.read(businessConfigProvider)?.isEn1SyncReady == true)
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_outlined),
                    title: const Text('EN1 Cloud'),
                    subtitle: const Text('Sincronización pendiente'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/settings/sync');
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
                  leading: const Icon(Icons.switch_account),
                  title: const Text('Cambiar cajero'),
                  subtitle: const Text('El turno permanece abierto'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(posSessionProvider.notifier).lock();
                    context.go('/pin?switch=1');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Bloquear pantalla'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(posSessionProvider.notifier).lock();
                    context.go('/pin');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Salir'),
                  subtitle: const Text('Cerrar sesión del cajero'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(posSessionProvider.notifier).logout();
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
    final en1SyncReady = config?.isEn1SyncReady ?? false;
    final productsAsync = ref.watch(productsListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cart = ref.watch(cartProvider);
    final posPagesAsync = ref.watch(posPagesListProvider);
    final posPages = posPagesAsync.valueOrNull ?? [];
    if (posPages.isNotEmpty &&
        (_selectedPageId == null ||
            !posPages.any((p) => p.localId == _selectedPageId))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedPageId = posPages.first.localId);
      });
    }
    final isTablet = PosLayout.isTablet(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Split 6:4 → catálogo ~60% del ancho (antes 7:3 / 68%).
    final gridColumns = isTablet
        ? PosLayout.gridColumns(screenWidth * 0.60)
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
        toolbarHeight: isTablet ? 56 : kToolbarHeight,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: _openMenu),
        title: FutureBuilder(
          future: ProvisioningStore.loadConfig(),
          builder: (context, snap) {
            final caja = snap.data?.cajaName ?? snap.data?.cajaId ?? 'Caja';
            final cashier = CashierDisplay.displayName(
              name: session.cashierName,
              contactId: session.cashierContactId,
            );
            final turno =
                session.cashRegisterId != null ? 'Turno abierto' : 'Sin turno';
            final line = '$caja · $cashier · $turno';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config?.businessName ?? 'EPOSOne',
                  style: TextStyle(
                      fontSize: isTablet ? 15 : 16,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  line,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            );
          },
        ),
        actions: [
          // Hito 3B.1: auto-sync 30s + indicador EN1
          Builder(builder: (_) {
            ref.watch(en1AutoSyncKeeperProvider);
            return const En1StatusChip(compact: true);
          }),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            tooltip: 'Escanear código',
            onPressed: _scanBarcode,
          ),
          if (ref.watch(businessConfigProvider)?.openTicketsEnabled ??
              true) ...[
            const OpenTicketsButton(),
            IconButton(
              icon: const Icon(Icons.save_outlined, size: 22),
              tooltip: 'Guardar pedido',
              onPressed: cart.items.isEmpty
                  ? null
                  : () async {
                      try {
                        await saveOpenTicketFlow(context, ref);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('$e'), backgroundColor: Colors.red),
                        );
                      }
                    },
            ),
          ],
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
                  Icon(Icons.account_balance_wallet,
                      size: 14, color: EposBrand.orange.withValues(alpha: 0.9)),
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
          if (trackInventory)
            Consumer(
              builder: (context, ref, _) {
                final countAsync = ref.watch(lowStockCountProvider);
                return countAsync.when(
                  data: (count) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Material(
                      color: Colors.orange.withValues(alpha: 0.12),
                      child: InkWell(
                        onTap: () => context.push('/inventory'),
                        child: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  size: 14, color: Colors.orange.shade800),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$count producto${count == 1 ? '' : 's'} bajo stock mínimo',
                                  style: const TextStyle(
                                      fontSize: 11, color: EposBrand.navy),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Text('Ver',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: EposBrand.orange,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          if (en1SyncReady)
            Consumer(
              builder: (context, ref, _) {
                final pendingAsync = ref.watch(syncPendingCountProvider);
                return pendingAsync.when(
                  data: (count) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Material(
                      color: EposBrand.navy.withValues(alpha: 0.08),
                      child: InkWell(
                        onTap: () => context.push('/settings/sync'),
                        child: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Icon(Icons.cloud_upload_outlined,
                                  size: 14,
                                  color:
                                      EposBrand.navy.withValues(alpha: 0.85)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$count pendiente${count == 1 ? '' : 's'} de sync EN1',
                                  style: const TextStyle(
                                      fontSize: 11, color: EposBrand.navy),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Text('Sync',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: EposBrand.orange,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          Expanded(
            child: isTablet
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
                          onSearchChanged: (v) =>
                              setState(() => _searchQuery = v),
                          onCategoryChanged: (id) =>
                              setState(() => _categoryFilter = id),
                          onProductTap: _addProduct,
                          posPages: posPages,
                          selectedPageId: _selectedPageId,
                          onPageSelected: (id) => setState(() {
                            _selectedPageId = id;
                            _categoryFilter = null;
                          }),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: const PosTicketPanel(expanded: true),
                      ),
                    ],
                  )
                : _buildPhoneBody(
                    cart: cart,
                    categoriesAsync: categoriesAsync,
                    productsAsync: productsAsync,
                    symbol: symbol,
                    trackInventory: trackInventory,
                    gridColumns: gridColumns,
                    posPages: posPages,
                  ),
          ),
        ],
      ),
    );
  }

  /// Phone only — tablet sigue en el Row de arriba, intacto.
  Widget _buildPhoneBody({
    required CartState cart,
    required AsyncValue<List<Category>> categoriesAsync,
    required AsyncValue<List<Product>> productsAsync,
    required String symbol,
    required bool trackInventory,
    required int gridColumns,
    required List<PosPage> posPages,
  }) {
    final hasItems = cart.items.isNotEmpty;
    if (!hasItems && _phoneTicketOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _phoneTicketOpen) {
          setState(() => _phoneTicketOpen = false);
        }
      });
    }

    final collapsedH =
        210 + ViewInsets.bottom(context, compact: true, extra: 4);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Altura relativa al body (no a toda la pantalla) → sin overflow.
        final openH =
            (constraints.maxHeight * 0.88).clamp(collapsedH, constraints.maxHeight);
        return PopScope(
          canPop: !_phoneTicketOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _phoneTicketOpen) {
              setState(() => _phoneTicketOpen = false);
            }
          },
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _CatalogPane(
                      searchController: _searchController,
                      searchQuery: _searchQuery,
                      categoryFilter: _categoryFilter,
                      categoriesAsync: categoriesAsync,
                      productsAsync: productsAsync,
                      symbol: symbol,
                      trackInventory: trackInventory,
                      crossAxisCount: gridColumns,
                      onSearchChanged: (v) =>
                          setState(() => _searchQuery = v),
                      onCategoryChanged: (id) =>
                          setState(() => _categoryFilter = id),
                      onProductTap: _addProduct,
                      posPages: posPages,
                      selectedPageId: _selectedPageId,
                      onPageSelected: (id) => setState(() {
                        _selectedPageId = id;
                        _categoryFilter = null;
                      }),
                    ),
                    if (hasItems && _phoneTicketOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _phoneTicketOpen = false),
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (hasItems)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: _phoneTicketOpen ? openH : collapsedH,
                  child: PosTicketPanel(
                    phoneSheet: true,
                    expanded: _phoneTicketOpen,
                    onPhoneSheetExpand: () =>
                        setState(() => _phoneTicketOpen = true),
                    onPhoneSheetCollapse: () =>
                        setState(() => _phoneTicketOpen = false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogPane extends ConsumerWidget {
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
  final List<PosPage> posPages;
  final String? selectedPageId;
  final ValueChanged<String>? onPageSelected;

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
    this.posPages = const [],
    this.selectedPageId,
    this.onPageSelected,
  });

  /// Con páginas: siempre modo página (búsqueda filtra dentro de Comida/Bar).
  /// Sin páginas: catálogo global.
  bool get _hasPages => posPages.isNotEmpty && selectedPageId != null;

  List<Category> _barCategories(WidgetRef ref) {
    if (_hasPages && selectedPageId != null) {
      return ref
              .watch(posPageCategoriesProvider(selectedPageId!))
              .valueOrNull ??
          const [];
    }
    final all = categoriesAsync.valueOrNull ?? const <Category>[];
    return [...all]..sort((a, b) {
        final order = (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0);
        return order != 0 ? order : a.name.compareTo(b.name);
      });
  }

  List<Product> _filterProducts(List<Product> source) {
    Iterable<Product> list = source.where((p) => p.isActive);
    if (categoryFilter != null) {
      list = list.where((p) => p.categoryId == categoryFilter);
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        final name = p.name.toLowerCase();
        final barcode = (p.barcode ?? '').toLowerCase();
        final sku = (p.sku ?? '').toLowerCase();
        return name.contains(q) || barcode.contains(q) || sku.contains(q);
      });
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageProductsAsync =
        _hasPages ? ref.watch(posPageProductsProvider(selectedPageId!)) : null;
    final barCategories = _barCategories(ref);

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
            child: Row(
              children: [
                Expanded(
                  child: categoriesAsync.when(
                    data: (_) => _CategoryChipBar(
                      categories: barCategories,
                      selectedId: categoryFilter,
                      onChanged: onCategoryChanged,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 148,
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: const TextStyle(fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
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
          child: _buildGrid(pageProductsAsync),
        ),
        if (posPages.isNotEmpty && onPageSelected != null)
          Padding(
            // Tablet: COMIDA/BAR queda bajo la barra/dock del sistema si no hay
            // margen; en celular el ticket inferior ya las empuja hacia arriba.
            padding: EdgeInsets.only(bottom: _pageBarBottomInset(context)),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: EposBrand.background,
                border: Border(top: BorderSide(color: EposBrand.divider)),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                itemCount: posPages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (_, i) {
                  final page = posPages[i];
                  final selected = page.localId == selectedPageId;
                  final countAsync =
                      ref.watch(posPageProductsProvider(page.localId));
                  final count = countAsync.valueOrNull?.length;
                  final label = count == null
                      ? page.name.toUpperCase()
                      : '${page.name.toUpperCase()} ($count)';
                  return Material(
                    color: selected ? EposBrand.orange : EposBrand.surface,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () {
                        onPageSelected?.call(page.localId);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : EposBrand.navy,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Margen bajo pestañas Comida/Bar — solo tablet (dock / gesture bar).
  double _pageBarBottomInset(BuildContext context) {
    if (!PosLayout.isTablet(context)) return 0;
    final mq = MediaQuery.of(context);
    // Con teclado el Scaffold ya reduce altura; basta un respiro mínimo.
    if (mq.viewInsets.bottom > 0) return 8;
    return ViewInsets.bottom(context, extra: 8).clamp(40.0, 72.0);
  }

  Widget _buildGrid(AsyncValue<List<Product>>? pageProductsAsync) {
    if (_hasPages && pageProductsAsync != null) {
      return pageProductsAsync.when(
        data: (list) {
          final filtered = _filterProducts(list);
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Esta página no tiene productos.\n'
                  'Configuración → Este dispositivo → Reparar páginas Comida / Bar\n'
                  'o vuelva a descargar el catálogo EN1.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (filtered.isEmpty) {
            return const Center(child: Text('Sin resultados en esta página'));
          }
          return PosProductGrid(
            products: filtered,
            symbol: symbol,
            trackInventory: trackInventory,
            crossAxisCount: crossAxisCount,
            onProductTap: onProductTap,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      );
    }

    return productsAsync.when(
      data: (products) {
        final list = _filterProducts(products);
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
    );
  }
}

class _CategoryChipBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CategoryChipBar({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  Color? _categoryColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 4),
      itemBuilder: (_, index) {
        if (index == 0) {
          return _CategoryChip(
            label: 'Todos',
            selected: selectedId == null,
            accent: EposBrand.orange,
            onTap: () => onChanged(null),
          );
        }
        final category = categories[index - 1];
        final accent = _categoryColor(category.color) ?? EposBrand.navy;
        return _CategoryChip(
          label: category.name,
          selected: selectedId == category.localId,
          accent: accent,
          onTap: () => onChanged(category.localId),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : EposBrand.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? accent : EposBrand.divider),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : EposBrand.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
