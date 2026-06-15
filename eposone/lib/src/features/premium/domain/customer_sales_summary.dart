import 'package:eposone/src/features/sales/domain/entities/sale.dart';

class CustomerSalesSummary {
  final List<Sale> sales;
  final double lifetimeTotal;

  const CustomerSalesSummary({required this.sales, required this.lifetimeTotal});
}
