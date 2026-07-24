import 'package:eposone/src/features/commercial_engine/domain/engines.dart';
import 'package:eposone/src/features/commercial_engine/domain/totals_models.dart';
import 'package:eposone/src/features/orders/domain/en1_tender_methods.dart';

/// Bridge temporal al settlement ya congelado de Pedido.
///
/// Centraliza el acceso sin cambiar sus reglas antes del freeze V6.
class LegacyPaymentEngine implements PaymentEngine {
  @override
  TenderLiveStatus evaluate({
    required double balanceDue,
    required List<TenderAmount> entered,
  }) {
    return evaluateTenders(balanceDue: balanceDue, entered: entered);
  }

  @override
  double sumPaid(Iterable<double> amounts) {
    final total = amounts.fold<double>(0, (sum, amount) => sum + amount);
    return double.parse(total.toStringAsFixed(2));
  }

  @override
  double outstanding({required double total, required double paid}) {
    return double.parse(
      (total - paid).clamp(0, double.infinity).toStringAsFixed(2),
    );
  }

  @override
  PaymentCompletion complete({
    required double total,
    required double enteredAmount,
    required bool allowsChange,
  }) {
    final paid = enteredAmount > 0 ? enteredAmount : total;
    final change = allowsChange
        ? (paid - total).clamp(0, double.infinity).toDouble()
        : 0.0;
    return PaymentCompletion(
      amountPaid: paid,
      change: change,
      isSufficient: paid + 0.001 >= total,
    );
  }
}
