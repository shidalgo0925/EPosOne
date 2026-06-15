import 'package:eposone/src/features/cash_register/domain/entities/cash_movement.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

/// Resumen calculado de un turno de caja.
class ShiftSummary {
  final int saleCount;
  final int refundCount;
  final double grossSales;
  final double totalDiscount;
  final double totalTax;
  final double totalRefunds;
  final double totalTips;
  final Map<PaymentMethod, double> byPaymentMethod;
  final double cashFromSales;
  final double cashMovementIn;
  final double cashMovementOut;
  final double openingAmount;
  final double expectedCash;

  const ShiftSummary({
    required this.saleCount,
    required this.refundCount,
    required this.grossSales,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalRefunds,
    required this.totalTips,
    required this.byPaymentMethod,
    required this.cashFromSales,
    required this.cashMovementIn,
    required this.cashMovementOut,
    required this.openingAmount,
    required this.expectedCash,
  });

  double get netSales => grossSales - totalRefunds;

  double paymentTotal(PaymentMethod method) => byPaymentMethod[method] ?? 0;
}

ShiftSummary computeShiftSummary({
  required double openingAmount,
  required List<Sale> completedSales,
  required List<Sale> refundedSales,
  required List<CashMovement> movements,
}) {
  final byPayment = <PaymentMethod, double>{};
  var gross = 0.0;
  var discount = 0.0;
  var tax = 0.0;
  var cashSales = 0.0;
  var tips = 0.0;

  for (final sale in completedSales) {
    gross += sale.total;
    discount += sale.discount;
    tax += sale.taxAmount;
    tips += sale.tipAmount;
    byPayment[sale.paymentMethod] = (byPayment[sale.paymentMethod] ?? 0) + sale.total;
    if (sale.paymentMethod == PaymentMethod.cash) {
      cashSales += sale.total;
    }
  }

  var refundTotal = 0.0;
  var cashRefunds = 0.0;
  for (final sale in refundedSales) {
    refundTotal += sale.total;
    if (sale.paymentMethod == PaymentMethod.cash) {
      cashRefunds += sale.total;
    }
  }

  var moveIn = 0.0;
  var moveOut = 0.0;
  for (final m in movements) {
    if (m.isInflow) {
      moveIn += m.amount.abs();
    } else if (m.isOutflow) {
      moveOut += m.amount.abs();
    }
  }

  final expected = openingAmount + cashSales - cashRefunds + moveIn - moveOut;

  return ShiftSummary(
    saleCount: completedSales.length,
    refundCount: refundedSales.length,
    grossSales: gross,
    totalDiscount: discount,
    totalTax: tax,
    totalRefunds: refundTotal,
    totalTips: tips,
    byPaymentMethod: byPayment,
    cashFromSales: cashSales - cashRefunds,
    cashMovementIn: moveIn,
    cashMovementOut: moveOut,
    openingAmount: openingAmount,
    expectedCash: expected,
  );
}
