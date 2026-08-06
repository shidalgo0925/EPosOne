import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_movement.dart';
import 'package:eposone/src/features/cash_register/domain/shift_summary.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

void main() {
  Sale sale({
    required double total,
    PaymentMethod method = PaymentMethod.cash,
    double discount = 0,
    double tax = 0,
    double tip = 0,
  }) =>
      Sale.create(
        subtotal: total - tax + discount,
        taxAmount: tax,
        total: total,
        amountPaid: total,
        change: 0,
        tipAmount: tip,
        discount: discount,
        paymentMethod: method,
        cashRegisterId: 'reg-1',
      );

  group('computeShiftSummary', () {
    test('opening only → expectedCash = opening', () {
      final s = computeShiftSummary(
        openingAmount: 100,
        completedSales: const [],
        refundedSales: const [],
        movements: const [],
      );
      expect(s.expectedCash, 100);
      expect(s.saleCount, 0);
      expect(s.netSales, 0);
    });

    test('cash sales increase expected; card does not', () {
      final s = computeShiftSummary(
        openingAmount: 50,
        completedSales: [
          sale(total: 20, method: PaymentMethod.cash),
          sale(total: 30, method: PaymentMethod.card),
        ],
        refundedSales: const [],
        movements: const [],
      );
      expect(s.saleCount, 2);
      expect(s.grossSales, 50);
      expect(s.cashFromSales, 20);
      expect(s.expectedCash, 70); // 50 + 20 cash
      expect(s.paymentTotal(PaymentMethod.card), 30);
    });

    test('cash refund and treasury movements adjust expected', () {
      final s = computeShiftSummary(
        openingAmount: 100,
        completedSales: [sale(total: 40, method: PaymentMethod.cash)],
        refundedSales: [sale(total: 10, method: PaymentMethod.cash)],
        movements: [
          CashMovement.create(
            cashRegisterId: 'reg-1',
            type: CashMovementType.income,
            amount: 5,
            reason: 'entrada',
          ),
          CashMovement.create(
            cashRegisterId: 'reg-1',
            type: CashMovementType.withdrawal,
            amount: 15,
            reason: 'retiro',
          ),
        ],
      );
      // 100 + 40 - 10 + 5 - 15 = 120
      expect(s.expectedCash, 120);
      expect(s.refundCount, 1);
      expect(s.totalRefunds, 10);
      expect(s.cashMovementIn, 5);
      expect(s.cashMovementOut, 15);
    });
  });
}
