import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eposone/src/features/pos/presentation/screens/pos_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/product_list_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/product_form_screen.dart';
import 'package:eposone/src/features/products/presentation/screens/category_list_screen.dart';
import 'package:eposone/src/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:eposone/src/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:eposone/src/features/cash_register/presentation/screens/cash_register_screen.dart';
import 'package:eposone/src/features/sales/presentation/screens/sales_history_screen.dart';
import 'package:eposone/src/features/sales/presentation/screens/sale_detail_screen.dart';
import 'package:eposone/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:eposone/src/features/home/presentation/screens/home_screen.dart';

// No generated file needed - plain Provider

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Home / Dashboard
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      // POS - Vender
      GoRoute(
        path: '/pos',
        builder: (context, state) => const PosScreen(),
      ),
      // Productos
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/products/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (context, state) => ProductFormScreen(productId: state.pathParameters['id']),
      ),
      // Categorías
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoryListScreen(),
      ),
      // Clientes
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerListScreen(),
      ),
      GoRoute(
        path: '/customers/new',
        builder: (context, state) => const CustomerFormScreen(),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (context, state) => CustomerFormScreen(customerId: state.pathParameters['id']),
      ),
      // Caja
      GoRoute(
        path: '/cash-register',
        builder: (context, state) => const CashRegisterScreen(),
      ),
      // Ventas / Historial
      GoRoute(
        path: '/sales',
        builder: (context, state) => const SalesHistoryScreen(),
      ),
      GoRoute(
        path: '/sales/:id',
        builder: (context, state) => SaleDetailScreen(saleId: state.pathParameters['id']!),
      ),
      // Configuración
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});