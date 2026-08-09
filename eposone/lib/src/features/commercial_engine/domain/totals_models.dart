/// Resultado único del motor comercial.
///
/// Es el único objeto que la UI debe presentar. Los campos de desglose ya
/// existen aunque el bridge legacy todavía devuelva promociones/redondeo en 0.
class CalculationResult {
  const CalculationResult({
    required this.subtotal,
    required this.discounts,
    required this.promotions,
    required this.taxes,
    required this.tips,
    required this.rounding,
    required this.total,
    this.detail = const [],
  });

  final double subtotal;
  final double discounts;
  final double promotions;
  final double taxes;
  final double tips;
  final double rounding;

  /// Total final a cobrar, incluyendo propina (propina/total truncados a 2 dec.).
  final double total;

  final List<CalculationDetail> detail;

  double get totalBeforeTips => total - tips - rounding;
  double get netBeforeTaxes => subtotal - discounts - promotions;

  double lineTotal(String lineId) {
    for (final item in detail) {
      if (item.code == 'line_total' && item.lineId == lineId) {
        return item.amount;
      }
    }
    return 0;
  }

  double lineTaxAmount(String lineId) {
    for (final item in detail) {
      if (item.code == 'line_tax' && item.lineId == lineId) {
        return item.amount;
      }
    }
    return 0;
  }

  double lineTaxRate(String lineId) {
    for (final item in detail) {
      if (item.code == 'line_tax_rate' && item.lineId == lineId) {
        return item.amount;
      }
    }
    return 0;
  }

  /// Impuestos por tasa (solo montos > 0), ordenados por tasa.
  Map<double, double> get taxByRate {
    final map = <double, double>{};
    for (final item in detail) {
      if (item.code != 'tax_bucket') continue;
      final match = RegExp(r'(\d+(?:\.\d+)?)%').firstMatch(item.label);
      if (match == null) continue;
      final rate = double.tryParse(match.group(1)!) ?? 0;
      map[rate] = (map[rate] ?? 0) + item.amount;
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  double get exemptBase {
    for (final item in detail) {
      if (item.code == 'exempt_base') return item.amount;
    }
    return 0;
  }

  // Compatibilidad temporal de presentación mientras se migra el POS.
  double get discount => discounts + promotions;
  double get taxAmount => taxes;
  double get tipAmount => tips;
  double get grandTotal => total;
}

class CalculationDetail {
  const CalculationDetail({
    required this.code,
    required this.label,
    required this.amount,
    this.lineId,
  });

  final String code;
  final String label;
  final double amount;
  final String? lineId;
}

class PaymentCompletion {
  const PaymentCompletion({
    required this.amountPaid,
    required this.change,
    required this.isSufficient,
  });

  final double amountPaid;
  final double change;
  final bool isSufficient;
}

@Deprecated('Use CalculationResult')
typedef CommercialTotalsResult = CalculationResult;

/// Línea de entrada al motor (desacoplada de widgets).
class CommercialLineInput {
  const CommercialLineInput({
    required this.lineId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.lineDiscount = 0,
    this.fiscalCategoryCode,
    this.precalculatedTaxAmount,
  });

  final String lineId;
  final String productId;
  final double quantity;
  final double unitPrice;
  final double lineDiscount;
  final String? fiscalCategoryCode;
  final double? precalculatedTaxAmount;
}

/// Pedido / carrito normalizado hacia el motor.
class CommercialOrderInput {
  const CommercialOrderInput({
    required this.lines,
    this.documentDiscountAmount = 0,
    this.documentDiscountPercent = 0,
    this.couponDiscount = 0,
    this.tipAmount = 0,
    this.tipPercent,
  });

  final List<CommercialLineInput> lines;
  final double documentDiscountAmount;
  final double documentDiscountPercent;
  final double couponDiscount;
  final double tipAmount;
  final double? tipPercent;
}
