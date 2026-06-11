import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';

part 'sale_repository.g.dart';

@riverpod
SaleRepository saleRepository(SaleRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SaleRepository(db);
}

class SaleRepository {
  final Isar _isar;
  SaleRepository(this._isar);

  Future<List<Sale>> getAllSales({DateTime? from, DateTime? to}) async {
    var query = _isar.sales.filter().isDeletedEqualTo(false);
    if (from != null) query = query.saleDateGreaterThan(from);
    if (to != null) query = query.saleDateLessThan(to);
    return query.sortBySaleDateDesc().findAll();
  }

  Future<Sale?> getSaleById(String localId) async {
    return _isar.sales.filter().localIdEqualTo(localId).findFirst();
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    return _isar.saleItems.filter().saleIdEqualTo(saleId).findAll();
  }

  Future<Sale> saveSale(Sale sale, List<SaleItem> items) async {
    await _isar.writeTxn(() async {
      await _isar.sales.put(sale);
      await _isar.saleItems.putAll(items);
    });
    return sale;
  }

  Future<void> cancelSale(String localId) async {
    final sale = await getSaleById(localId);
    if (sale != null && sale.status == SaleStatus.completed) {
      final cancelled = sale.copyWith(status: SaleStatus.cancelled, updatedAt: DateTime.now());
      await _isar.writeTxn(() => _isar.sales.put(cancelled));
    }
  }

  Future<double> getTotalSalesForCashRegister(String cashRegisterId) async {
    final sales = await _isar.sales
        .filter()
        .cashRegisterIdEqualTo(cashRegisterId)
        .statusEqualTo(SaleStatus.completed)
        .findAll();
    return sales.fold<double>(0, (sum, s) => sum + s.total);
  }

  Future<int> getSaleCountForCashRegister(String cashRegisterId) async {
    return _isar.sales
        .filter()
        .cashRegisterIdEqualTo(cashRegisterId)
        .statusEqualTo(SaleStatus.completed)
        .count();
  }
}