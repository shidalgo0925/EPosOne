import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';

void main() {
  group('CommercialEngine dual mode parity', () {
    const order = CommercialOrderInput(
      lines: [
        CommercialLineInput(
          lineId: 'coffee-line',
          productId: 'coffee',
          quantity: 2,
          unitPrice: 5,
          lineDiscount: 1,
        ),
      ],
      documentDiscountPercent: 10,
      couponDiscount: 0.50,
      tipPercent: 10,
    );

    test('local and EN1 policy sources produce identical CalculationResult',
        () {
      final standalone = _facade(CommercialDataOrigin.local);
      final integrated = _facade(CommercialDataOrigin.en1);

      final local = standalone.calculateTotals(order);
      final en1 = integrated.calculateTotals(order);

      expect(en1.subtotal, local.subtotal);
      expect(en1.discounts, local.discounts);
      expect(en1.promotions, local.promotions);
      expect(en1.taxes, local.taxes);
      expect(en1.tips, local.tips);
      expect(en1.rounding, local.rounding);
      expect(en1.total, local.total);
      expect(en1.detail.length, local.detail.length);
    });

    test('facade is the payment calculation entry point', () {
      final engine = _facade(CommercialDataOrigin.local);
      final result = engine.completePayment(
        total: 10,
        enteredAmount: 12,
        allowsChange: true,
      );

      expect(result.amountPaid, 12);
      expect(result.change, 2);
      expect(result.isSufficient, isTrue);
    });
  });
}

CommercialEngineFacade _facade(CommercialDataOrigin origin) {
  return CommercialEngineFacade(
    totals: LegacyTotalsEngine(),
    tax: StubTaxEngine(),
    tip: StubTipEngine(),
    payment: LegacyPaymentEngine(),
    merchandising: LegacyMerchandisingEngine(),
    policies: _Resolver(_PolicySource(origin)),
  );
}

class _Resolver implements CommercialPolicyResolver {
  const _Resolver(this.source);

  final CommercialPolicySource source;

  @override
  CommercialPolicySource resolve() => source;
}

class _PolicySource implements CommercialPolicySource {
  const _PolicySource(this.origin);

  @override
  final CommercialDataOrigin origin;

  @override
  double get taxRatePercent => 7;

  @override
  bool get taxIncluded => false;

  @override
  String get taxName => 'ITBMS';
}
