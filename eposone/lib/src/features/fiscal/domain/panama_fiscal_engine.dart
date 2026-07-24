import 'package:eposone/src/features/fiscal/domain/business_fiscal_contract.dart';
import 'package:eposone/src/features/fiscal/domain/fiscal_category.dart';

/// Snapshot fiscal de una línea (Tax Contract §5–6).
class FiscalLineSnapshot {
  const FiscalLineSnapshot({
    required this.lineId,
    required this.fiscalCategoryCode,
    required this.effectiveRatePercent,
    required this.taxableBase,
    required this.taxAmount,
    required this.taxCode,
  });

  final String lineId;
  final String fiscalCategoryCode;
  final double effectiveRatePercent;
  final double taxableBase;
  final double taxAmount;

  /// Código de impuesto aplicado (catálogo), p. ej. ITBMS_7 / EXENTO.
  final String taxCode;
}

/// Resultado agregado del motor fiscal por documento.
class FiscalDocumentBreakdown {
  const FiscalDocumentBreakdown({
    required this.lines,
    required this.taxTotal,
    required this.baseByRate,
    required this.taxByRate,
    required this.exemptBase,
  });

  final List<FiscalLineSnapshot> lines;
  final double taxTotal;

  /// Bases imponibles agrupadas por tasa efectiva (ej. 7.0 → base).
  final Map<double, double> baseByRate;

  /// Impuesto agrupado por tasa efectiva.
  final Map<double, double> taxByRate;

  /// Suma de bases con tasa 0%.
  final double exemptBase;
}

/// Motor fiscal Panamá: categoría de producto + contrato del comercio.
class PanamaFiscalEngine {
  const PanamaFiscalEngine();

  /// Resuelve la tasa efectiva según contrato + categoría.
  double resolveRate(
    BusinessFiscalContract contract,
    String? fiscalCategoryCode,
  ) {
    if (contract.isExemptEstablishment) return 0;

    final cat = FiscalCategory.byCode(fiscalCategoryCode);

    switch (cat.code) {
      case 'ITBMS_10':
        return FiscalCategory.itbms10.baseRatePercent;
      case 'ITBMS_15':
        return FiscalCategory.itbms15.baseRatePercent;
      case 'ITBMS_7':
        return FiscalCategory.itbms7.baseRatePercent;
      case 'EXENTO':
        if (contract.chargesRestaurantService) {
          return FiscalCategory.itbms7.baseRatePercent;
        }
        return 0;
      default:
        return cat.baseRatePercent;
    }
  }

  String taxCodeForRate(double rate) {
    if (rate <= 0) return FiscalCategory.exento.code;
    if ((rate - 7).abs() < 0.01) return FiscalCategory.itbms7.code;
    if ((rate - 10).abs() < 0.01) return FiscalCategory.itbms10.code;
    if ((rate - 15).abs() < 0.01) return FiscalCategory.itbms15.code;
    return 'ITBMS_${rate.toStringAsFixed(0)}';
  }

  /// Impuesto de una línea sobre [taxableBase] (ya neto de descuentos).
  double taxOnBase({
    required double taxableBase,
    required double ratePercent,
    required bool taxIncluded,
  }) {
    if (taxableBase <= 0 || ratePercent <= 0) return 0;
    if (taxIncluded) {
      return taxableBase - (taxableBase / (1 + ratePercent / 100));
    }
    return taxableBase * (ratePercent / 100);
  }

  FiscalLineSnapshot calculateLine({
    required String lineId,
    required String? fiscalCategoryCode,
    required double taxableBase,
    required BusinessFiscalContract contract,
  }) {
    final cat = FiscalCategory.byCode(fiscalCategoryCode);
    final rate = resolveRate(contract, cat.code);
    final tax = taxOnBase(
      taxableBase: taxableBase,
      ratePercent: rate,
      taxIncluded: contract.taxIncluded,
    );
    return FiscalLineSnapshot(
      lineId: lineId,
      fiscalCategoryCode: cat.code,
      effectiveRatePercent: rate,
      taxableBase: taxableBase,
      taxAmount: double.parse(tax.toStringAsFixed(2)),
      taxCode: taxCodeForRate(rate),
    );
  }

  FiscalDocumentBreakdown aggregate(List<FiscalLineSnapshot> lines) {
    final baseByRate = <double, double>{};
    final taxByRate = <double, double>{};
    var exemptBase = 0.0;
    var taxTotal = 0.0;

    for (final line in lines) {
      taxTotal += line.taxAmount;
      if (line.effectiveRatePercent <= 0) {
        exemptBase += line.taxableBase;
        continue;
      }
      final r = line.effectiveRatePercent;
      baseByRate[r] = (baseByRate[r] ?? 0) + line.taxableBase;
      taxByRate[r] = (taxByRate[r] ?? 0) + line.taxAmount;
    }

    return FiscalDocumentBreakdown(
      lines: lines,
      taxTotal: double.parse(taxTotal.toStringAsFixed(2)),
      baseByRate: baseByRate,
      taxByRate: {
        for (final e in taxByRate.entries)
          e.key: double.parse(e.value.toStringAsFixed(2)),
      },
      exemptBase: double.parse(exemptBase.toStringAsFixed(2)),
    );
  }
}
