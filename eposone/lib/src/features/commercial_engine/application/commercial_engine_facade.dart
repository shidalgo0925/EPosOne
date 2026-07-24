import 'package:eposone/src/features/commercial_engine/domain/engines.dart';
import 'package:eposone/src/features/commercial_engine/domain/totals_models.dart';
import 'package:eposone/src/features/commercial_engine/domain/commercial_policy_source.dart';
import 'package:eposone/src/features/orders/domain/en1_tender_methods.dart';

/// Fachada única que la UI / POS deben invocar.
///
/// No calcula en widgets: captura → [CommercialEngineFacade] → presenta.
class CommercialEngineFacade {
  CommercialEngineFacade({
    required this.totals,
    required this.tax,
    required this.tip,
    required this.payment,
    required this.merchandising,
    required this.policies,
  });

  final TotalsEngine totals;
  final TaxEngine tax;
  final TipEngine tip;
  final PaymentEngine payment;
  final MerchandisingEngine merchandising;
  final CommercialPolicyResolver policies;

  CalculationResult calculateTotals(CommercialOrderInput order) {
    return totals.calculate(order: order, policies: policies.resolve());
  }

  TenderLiveStatus evaluatePayment({
    required double balanceDue,
    required List<TenderAmount> entered,
  }) {
    return payment.evaluate(balanceDue: balanceDue, entered: entered);
  }

  double sumPayments(Iterable<double> amounts) => payment.sumPaid(amounts);

  double outstandingBalance({
    required double total,
    required double paid,
  }) =>
      payment.outstanding(total: total, paid: paid);

  PaymentCompletion completePayment({
    required double total,
    required double enteredAmount,
    required bool allowsChange,
  }) =>
      payment.complete(
        total: total,
        enteredAmount: enteredAmount,
        allowsChange: allowsChange,
      );

  double calculateCouponDiscount({
    required CommercialOrderInput order,
    required bool isPercent,
    required double value,
  }) =>
      merchandising.couponDiscount(
        order: order,
        isPercent: isPercent,
        value: value,
      );

  double sumPriceAdjustments(Iterable<double> amounts) =>
      merchandising.sumPriceAdjustments(amounts);
}

class StubTaxEngine implements TaxEngine {}

class StubTipEngine implements TipEngine {}
