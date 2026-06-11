import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/customers/data/repositories/customer_repository.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';

/// Provider de lista de clientes
final customersListProvider = FutureProvider<List<Customer>>((ref) async {
  final isar = await ref.read(databaseProvider.future);
  final repo = CustomerRepository(isar);
  return repo.getAllCustomers();
});

/// Provider de búsqueda de clientes
final customersSearchProvider = FutureProvider.family<List<Customer>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    final isar = await ref.read(databaseProvider.future);
    return CustomerRepository(isar).getAllCustomers();
  }
  final isar = await ref.read(databaseProvider.future);
  return CustomerRepository(isar).searchCustomers(query.trim());
});

/// Provider de cliente por ID
final customerByIdProvider = FutureProvider.family<Customer?, String>((ref, localId) async {
  final isar = await ref.read(databaseProvider.future);
  return CustomerRepository(isar).getCustomerById(localId);
});

/// Notifier para operaciones de cliente
class CustomerNotifier extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repo;
  CustomerNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> saveCustomer(Customer customer) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveCustomer(customer);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCustomer(String localId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteCustomer(localId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final customerNotifierProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<void>>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (isar) => CustomerNotifier(CustomerRepository(isar)),
    loading: () => throw StateError('Database not initialized'),
    error: (e, _) => throw StateError('Database error: $e'),
  );
});