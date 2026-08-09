import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/features/orders/domain/en1_tender_methods.dart';
import 'package:eposone/src/features/pos/domain/payment_method_from_tenders.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

void main() {
  group('paymentMethodFromTenders', () {
    test('visa alone is card, not cash', () {
      expect(
        paymentMethodFromTenders([
          const TenderAmount(code: 'visa', amount: 25.50),
        ]),
        PaymentMethod.card,
      );
    });

    test('clave and yappy map correctly', () {
      expect(
        paymentMethodFromTenders([
          const TenderAmount(code: 'clave', amount: 10),
        ]),
        PaymentMethod.card,
      );
      expect(
        paymentMethodFromTenders([
          const TenderAmount(code: 'yappy', amount: 10),
        ]),
        PaymentMethod.yappy,
      );
    });

    test('dominant non-cash wins over residual cash', () {
      // Bug previo: any cash → PaymentMethod.cash
      expect(
        paymentMethodFromTenders([
          const TenderAmount(code: 'visa', amount: 20.00),
          const TenderAmount(code: 'cash', amount: 0.50),
        ]),
        PaymentMethod.card,
      );
    });

    test('cash alone stays cash', () {
      expect(
        paymentMethodFromTenders([
          const TenderAmount(code: 'cash', amount: 15),
        ]),
        PaymentMethod.cash,
      );
    });

    test('cash majority stays cash', () {
      expect(
        paymentMethodFromTenders([
          const TenderAmount(code: 'cash', amount: 18),
          const TenderAmount(code: 'yappy', amount: 2),
        ]),
        PaymentMethod.cash,
      );
    });
  });
}
