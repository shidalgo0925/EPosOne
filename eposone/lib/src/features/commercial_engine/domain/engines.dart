import 'package:eposone/src/features/commercial_engine/domain/commercial_policy_source.dart';
import 'package:eposone/src/features/commercial_engine/domain/totals_models.dart';
import 'package:eposone/src/features/orders/domain/en1_tender_methods.dart';

/// Motor de Totales — algoritmo oficial (V6 Totales Spec, post-freeze).
abstract class TotalsEngine {
  CalculationResult calculate({
    required CommercialOrderInput order,
    required CommercialPolicySource policies,
  });
}

/// Motor Fiscal — catálogo / multi-impuesto (post-freeze Tax Contract).
abstract class TaxEngine {}

/// Motor de Propinas (post-freeze Tip Contract).
abstract class TipEngine {}

/// Motor de Pagos — tenders / cambio (post-freeze Payment Contract).
abstract class PaymentEngine {
  TenderLiveStatus evaluate({
    required double balanceDue,
    required List<TenderAmount> entered,
  });

  double sumPaid(Iterable<double> amounts);

  double outstanding({required double total, required double paid});

  PaymentCompletion complete({
    required double total,
    required double enteredAmount,
    required bool allowsChange,
  });
}

/// Motor Comercial — descuentos / promos (post-freeze Commercial Engine Spec).
abstract class MerchandisingEngine {
  double couponDiscount({
    required CommercialOrderInput order,
    required bool isPercent,
    required double value,
  });

  double sumPriceAdjustments(Iterable<double> amounts);
}
