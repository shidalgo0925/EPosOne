import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/orders/data/en1_orders_api.dart';
import 'package:eposone/src/features/orders/data/order_repository.dart';
import 'package:eposone/src/features/orders/data/order_service.dart';
import 'package:eposone/src/features/orders/domain/entities/order.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return OrderRepository(db);
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(
    repository: ref.watch(orderRepositoryProvider),
    syncRepository: ref.watch(syncRepositoryProvider),
    en1Api: En1OrdersApi(),
  );
});

final localOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return ref.watch(orderRepositoryProvider).listRecent();
});
