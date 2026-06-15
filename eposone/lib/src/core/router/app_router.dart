import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:eposone/src/features/auth/presentation/screens/pin_screen.dart';
import 'package:eposone/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:eposone/src/features/cash_register/presentation/screens/cash_open_screen.dart';
import 'package:eposone/src/features/cash_register/presentation/screens/cash_close_screen.dart';
import 'package:eposone/src/features/cash_register/presentation/screens/cash_register_screen.dart';
import 'package:eposone/src/features/cash_register/presentation/screens/treasury_screen.dart';
import 'package:eposone/src/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:eposone/src/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:eposone/src/features/home/presentation/screens/home_screen.dart';
import 'package:eposone/src/features/pos/presentation/screens/barcode_scanner_screen.dart';
import 'package:eposone/src/features/pos/presentation/screens/payment_screen.dart';
import 'package:eposone/src/features/pos/presentation/screens/split_bill_screen.dart';
import 'package:eposone/src/features/pos/presentation/screens/pos_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/category_list_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/product_form_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/product_list_screen.dart';
import 'package:eposone/src/features/pos/presentation/utils/pos_layout.dart';
import 'package:eposone/src/features/sales/presentation/screens/receipt_screen.dart';
import 'package:eposone/src/features/sales/presentation/screens/sale_detail_screen.dart';
import 'package:eposone/src/features/sales/presentation/screens/sales_history_screen.dart';
import 'package:eposone/src/features/pos/presentation/screens/pick_ticket_screen.dart';
import 'package:eposone/src/features/pos/presentation/screens/split_open_ticket_screen.dart';
import 'package:eposone/src/features/settings/presentation/screens/open_tickets_settings_screen.dart';
import 'package:eposone/src/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/modifier_groups_screen.dart';
import 'package:eposone/src/features/settings/presentation/screens/pos_pages_settings_screen.dart';
import 'package:eposone/src/features/settings/presentation/screens/printer_settings_screen.dart';
import 'package:eposone/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:eposone/src/features/fiscal/presentation/screens/fiscal_settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Solo cambia en login/logout/apertura de caja — no en touch() de actividad.
int _sessionRouterGate(PosSession? session) {
  if (session == null) return 0;
  if (session.cashRegisterId == null) return 1;
  return 2;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);

  ref.listen<int>(
    posSessionProvider.select(_sessionRouterGate),
    (_, __) => refresh.value++,
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refresh,
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = ref.read(posSessionProvider);
      final path = state.uri.path;
      const publicRoutes = ['/splash', '/onboarding', '/pin'];
      final isPublic = publicRoutes.contains(path);

      if (session == null) {
        if (path == '/pos' || path == '/payment' || path.startsWith('/receipt')) {
          return '/pin';
        }
        return null;
      }

      if (session.cashRegisterId == null && path == '/pos') {
        return '/cash/open';
      }

      if (path == '/pin') {
        return session.cashRegisterId != null ? '/pos' : '/cash/open';
      }

      if (isPublic && path != '/splash') {
        return '/pos';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/pin', builder: (_, __) => const PinScreen()),
      GoRoute(path: '/cash/open', builder: (_, __) => const CashOpenScreen()),
      GoRoute(path: '/pos', builder: (_, __) => const PosScreen()),
      GoRoute(path: '/pos/scan', builder: (_, __) => const BarcodeScannerScreen()),
      GoRoute(path: '/payment', builder: (_, __) => const PaymentScreen()),
      GoRoute(path: '/payment/split', builder: (_, __) => const SplitBillScreen()),
      GoRoute(
        path: '/receipt/:id',
        builder: (_, state) => ReceiptScreen(saleId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/products', builder: (_, __) => const ProductListScreen()),
      GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
      GoRoute(path: '/products/new', builder: (_, __) => const ProductFormScreen()),
      GoRoute(
        path: '/products/:id/edit',
        builder: (_, state) => ProductFormScreen(productId: state.pathParameters['id']),
      ),
      GoRoute(path: '/categories', builder: (_, __) => const CategoryListScreen()),
      GoRoute(path: '/customers', builder: (_, __) => const CustomerListScreen()),
      GoRoute(path: '/customers/new', builder: (_, __) => const CustomerFormScreen()),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (_, state) => CustomerFormScreen(customerId: state.pathParameters['id']),
      ),
      GoRoute(path: '/cash-register', builder: (_, __) => const CashRegisterScreen()),
      GoRoute(path: '/cash-register/treasury', builder: (_, __) => const TreasuryScreen()),
      GoRoute(path: '/cash-register/close', builder: (_, __) => const CashCloseScreen()),
      GoRoute(
        path: '/sales',
        builder: (_, state) => SalesHistoryScreen(
          initialSaleId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: '/sales/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          if (PosLayout.isTablet(context)) {
            return SalesHistoryScreen(initialSaleId: id);
          }
          return SaleDetailScreen(saleId: id);
        },
      ),
      GoRoute(path: '/tickets/pick', builder: (_, __) => const PickTicketScreen()),
      GoRoute(
        path: '/tickets/pick/move/:id',
        builder: (_, state) => PickTicketScreen(moveTicketId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/tickets/:id/split',
        builder: (_, state) => SplitOpenTicketScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/settings/open-tickets', builder: (_, __) => const OpenTicketsSettingsScreen()),
      GoRoute(path: '/settings/printer', builder: (_, __) => const PrinterSettingsScreen()),
      GoRoute(path: '/settings/modifiers', builder: (_, __) => const ModifierGroupsScreen()),
      GoRoute(path: '/settings/modifiers/new', builder: (_, __) => const ModifierGroupFormScreen()),
      GoRoute(
        path: '/settings/modifiers/:id/edit',
        builder: (_, state) => ModifierGroupFormScreen(groupId: state.pathParameters['id']),
      ),
      GoRoute(path: '/settings/pos-pages', builder: (_, __) => const PosPagesSettingsScreen()),
      GoRoute(path: '/settings/pos-pages/new', builder: (_, __) => const PosPageFormScreen()),
      GoRoute(
        path: '/settings/pos-pages/:id/edit',
        builder: (_, state) => PosPageFormScreen(pageId: state.pathParameters['id']),
      ),
      GoRoute(path: '/settings/fiscal', builder: (_, __) => const FiscalSettingsScreen()),
      GoRoute(path: '/settings/fiscal/documents', builder: (_, __) => const FiscalDocumentsScreen()),
    ],
  );
});
