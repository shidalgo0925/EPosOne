import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:eposone/src/features/auth/presentation/screens/pin_screen.dart';
import 'package:eposone/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:eposone/src/features/cash_register/presentation/screens/cash_open_screen.dart';
import 'package:eposone/src/features/cash_register/presentation/screens/cash_register_screen.dart';
import 'package:eposone/src/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:eposone/src/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:eposone/src/features/home/presentation/screens/home_screen.dart';
import 'package:eposone/src/features/pos/presentation/screens/payment_screen.dart';
import 'package:eposone/src/features/pos/presentation/screens/pos_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/category_list_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/product_form_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/product_list_screen.dart';
import 'package:eposone/src/features/sales/presentation/screens/receipt_screen.dart';
import 'package:eposone/src/features/sales/presentation/screens/sale_detail_screen.dart';
import 'package:eposone/src/features/sales/presentation/screens/sales_history_screen.dart';
import 'package:eposone/src/features/settings/presentation/screens/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(posSessionProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
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
      GoRoute(path: '/payment', builder: (_, __) => const PaymentScreen()),
      GoRoute(
        path: '/receipt/:id',
        builder: (_, state) => ReceiptScreen(saleId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/products', builder: (_, __) => const ProductListScreen()),
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
      GoRoute(path: '/sales', builder: (_, __) => const SalesHistoryScreen()),
      GoRoute(
        path: '/sales/:id',
        builder: (_, state) => SaleDetailScreen(saleId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
