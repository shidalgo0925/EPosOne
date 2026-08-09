import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/core/utils/money_math.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';
import 'package:eposone/src/features/fiscal/domain/business_fiscal_contract.dart';
import 'package:eposone/src/features/fiscal/domain/establishment_type.dart';

void main() {
  group('MoneyMath.truncate', () {
    test('drops extra digits without rounding up', () {
      expect(MoneyMath.truncate(1.055), 1.05);
      expect(MoneyMath.truncate(1.059), 1.05);
      expect(MoneyMath.truncate(10.999), 10.99);
      expect(MoneyMath.truncate(-1.059), -1.05);
    });
  });

  group('LegacyTotalsEngine tip', () {
    test('percent tip truncates; total does not round up', () {
      // merchandise = 10.55 → 10% tip raw 1.055 → tip 1.05 → total 11.60
      // (half-up would have been tip 1.06 / total 11.61)
      final engine = LegacyTotalsEngine();
      final result = engine.calculate(
        order: const CommercialOrderInput(
          lines: [
            CommercialLineInput(
              lineId: 'l1',
              productId: 'p1',
              quantity: 1,
              unitPrice: 10.55,
            ),
          ],
          tipPercent: 10,
        ),
        policies: _Policies(),
      );
      expect(result.tips, 1.05);
      expect(result.total, 11.60);
    });
  });
}

class _Policies implements CommercialPolicySource {
  @override
  CommercialDataOrigin get origin => CommercialDataOrigin.local;

  @override
  double get taxRatePercent => 7;

  @override
  bool get taxIncluded => true;

  @override
  String? get taxName => 'ITBMS';

  @override
  BusinessFiscalContract get fiscalContract => const BusinessFiscalContract(
        establishmentType: EstablishmentType.other,
        chargesRestaurantService: false,
        sellsAlcohol: false,
        isExemptEstablishment: false,
        taxIncluded: true,
        taxName: 'ITBMS',
      );
}
