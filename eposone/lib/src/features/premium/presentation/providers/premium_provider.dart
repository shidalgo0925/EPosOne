import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/premium/data/repositories/coupon_repository.dart';
import 'package:eposone/src/features/premium/domain/customer_sales_summary.dart';
import 'package:eposone/src/features/premium/domain/entities/coupon.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';

final couponsListProvider = FutureProvider<List<Coupon>>((ref) async {
  return ref.watch(couponRepositoryProvider).getAll();
});

final customerSalesProvider = FutureProvider.family<CustomerSalesSummary, String>((ref, customerId) async {
  final repo = ref.watch(saleRepositoryProvider);
  final sales = await repo.getSalesByCustomerId(customerId);
  final lifetime = await repo.getCustomerLifetimeTotal(customerId);
  return CustomerSalesSummary(sales: sales, lifetimeTotal: lifetime);
});
