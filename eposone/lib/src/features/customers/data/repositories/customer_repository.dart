import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';

part 'customer_repository.g.dart';

@riverpod
CustomerRepository customerRepository(CustomerRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return CustomerRepository(db);
}

class CustomerRepository {
  final Isar _isar;
  CustomerRepository(this._isar);

  Future<List<Customer>> getAllCustomers() async {
    return _isar.customers.filter().isDeletedEqualTo(false).sortByName().findAll();
  }

  Future<Customer?> getCustomerById(String localId) async {
    return _isar.customers.filter().localIdEqualTo(localId).findFirst();
  }

  Future<List<Customer>> searchCustomers(String query) async {
    return _isar.customers
        .filter()
        .isDeletedEqualTo(false)
        .group((q) => q
            .nameContains(query, caseSensitive: false)
            .or()
            .phoneContains(query, caseSensitive: false)
            .or()
            .documentContains(query, caseSensitive: false))
        .sortByName()
        .findAll();
  }

  Future<void> saveCustomer(Customer customer) => _isar.writeTxn(() => _isar.customers.put(customer));

  Future<void> deleteCustomer(String localId) async {
    final customer = await getCustomerById(localId);
    if (customer != null) {
      await _isar.writeTxn(() => _isar.customers.put(customer.markAsDeleted()));
    }
  }
}