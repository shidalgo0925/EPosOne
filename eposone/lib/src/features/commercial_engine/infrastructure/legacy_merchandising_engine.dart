import 'package:eposone/src/features/commercial_engine/domain/engines.dart';
import 'package:eposone/src/features/commercial_engine/domain/totals_models.dart';

/// Bridge temporal a la fórmula de cupón pre-V6.
class LegacyMerchandisingEngine implements MerchandisingEngine {
  @override
  double couponDiscount({
    required CommercialOrderInput order,
    required bool isPercent,
    required double value,
  }) {
    var base = 0.0;
    for (final line in order.lines) {
      base += line.quantity * line.unitPrice - line.lineDiscount;
    }
    final global = base * (order.documentDiscountPercent / 100);
    base = (base - global).clamp(0, double.infinity);
    return isPercent
        ? (base * value / 100).clamp(0, base)
        : value.clamp(0, base);
  }

  @override
  double sumPriceAdjustments(Iterable<double> amounts) {
    return amounts.fold<double>(0, (sum, amount) => sum + amount);
  }
}
