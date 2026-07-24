import 'package:eposone/src/features/commercial_engine/domain/commercial_policy_source.dart';
import 'package:eposone/src/features/commercial_engine/domain/engines.dart';
import 'package:eposone/src/features/commercial_engine/domain/totals_models.dart';
import 'package:eposone/src/features/fiscal/domain/panama_fiscal_engine.dart';

/// Totales POS con motor fiscal Panamá (categoría × contrato comercio).
///
/// Descuentos de documento se prorratean a líneas antes de ITBMS.
class LegacyTotalsEngine implements TotalsEngine {
  LegacyTotalsEngine({this.fiscal = const PanamaFiscalEngine()});

  final PanamaFiscalEngine fiscal;

  @override
  CommercialTotalsResult calculate({
    required CommercialOrderInput order,
    required CommercialPolicySource policies,
  }) {
    final contract = policies.fiscalContract;
    var subtotal = 0.0;
    var lineDiscounts = 0.0;
    final lineNets = <double>[];

    for (final line in order.lines) {
      final gross = line.quantity * line.unitPrice;
      subtotal += gross;
      lineDiscounts += line.lineDiscount;
      lineNets.add((gross - line.lineDiscount).clamp(0, double.infinity));
    }

    final percentDisc = subtotal * (order.documentDiscountPercent / 100);
    final documentDisc =
        percentDisc + order.documentDiscountAmount + order.couponDiscount;
    final discount = lineDiscounts + documentDisc;
    final netsSum = lineNets.fold<double>(0, (a, b) => a + b);

    final hasPrecalculatedTax =
        order.lines.any((line) => line.precalculatedTaxAmount != null);

    final snapshots = <FiscalLineSnapshot>[];
    final lineDetails = <CalculationDetail>[];

    for (var i = 0; i < order.lines.length; i++) {
      final line = order.lines[i];
      final allocatedDoc = netsSum > 0
          ? documentDisc * (lineNets[i] / netsSum)
          : 0.0;
      final base =
          (lineNets[i] - allocatedDoc).clamp(0, double.infinity).toDouble();

      final FiscalLineSnapshot snap;
      if (hasPrecalculatedTax && line.precalculatedTaxAmount != null) {
        final rate = fiscal.resolveRate(contract, line.fiscalCategoryCode);
        snap = FiscalLineSnapshot(
          lineId: line.lineId,
          fiscalCategoryCode:
              line.fiscalCategoryCode ?? fiscal.taxCodeForRate(rate),
          effectiveRatePercent: rate,
          taxableBase: base,
          taxAmount: double.parse(
            line.precalculatedTaxAmount!.toStringAsFixed(2),
          ),
          taxCode: fiscal.taxCodeForRate(rate),
        );
      } else {
        snap = fiscal.calculateLine(
          lineId: line.lineId,
          fiscalCategoryCode: line.fiscalCategoryCode,
          taxableBase: base,
          contract: contract,
        );
      }
      snapshots.add(snap);

      lineDetails.add(
        CalculationDetail(
          code: 'line_total',
          label: 'Total línea',
          amount: base,
          lineId: line.lineId,
        ),
      );
      lineDetails.add(
        CalculationDetail(
          code: 'line_tax',
          label: 'ITBMS línea',
          amount: snap.taxAmount,
          lineId: line.lineId,
        ),
      );
      lineDetails.add(
        CalculationDetail(
          code: 'line_tax_rate',
          label: 'Tasa línea',
          amount: snap.effectiveRatePercent,
          lineId: line.lineId,
        ),
      );
    }

    final breakdown = fiscal.aggregate(snapshots);
    final taxAmount = breakdown.taxTotal;
    final taxable = (subtotal - discount).clamp(0, double.infinity);
    final merchandiseTotal =
        contract.taxIncluded ? taxable : taxable + taxAmount;
    final tip = order.tipPercent == null
        ? order.tipAmount
        : double.parse(
            (merchandiseTotal * order.tipPercent! / 100).toStringAsFixed(2),
          );

    final taxName = policies.taxName ?? contract.taxName ?? 'ITBMS';
    final detail = <CalculationDetail>[
      ...lineDetails,
      CalculationDetail(
        code: 'legacy_discount',
        label: 'Descuentos',
        amount: discount,
      ),
      CalculationDetail(
        code: 'legacy_tax',
        label: taxName,
        amount: taxAmount,
      ),
      for (final e in breakdown.taxByRate.entries)
        CalculationDetail(
          code: 'tax_bucket',
          label: '$taxName ${e.key.toStringAsFixed(0)}%',
          amount: e.value,
        ),
      if (breakdown.exemptBase > 0.0001)
        CalculationDetail(
          code: 'exempt_base',
          label: 'Base exenta',
          amount: breakdown.exemptBase,
        ),
      CalculationDetail(
        code: 'legacy_tip',
        label: 'Propina',
        amount: tip,
      ),
    ];

    return CalculationResult(
      subtotal: subtotal,
      discounts: discount,
      promotions: 0,
      taxes: taxAmount,
      tips: tip,
      rounding: 0,
      total: merchandiseTotal + tip,
      detail: detail,
    );
  }
}
