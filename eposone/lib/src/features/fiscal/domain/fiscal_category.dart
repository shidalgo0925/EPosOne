/// Catálogo de categorías fiscales Panamá (ITBMS).
///
/// Las tasas viven aquí — no hardcodear 7/10/15 en UI de cobro ni recibo.
class FiscalCategory {
  const FiscalCategory({
    required this.code,
    required this.name,
    required this.baseRatePercent,
  });

  final String code;
  final String name;

  /// Tasa base del catálogo (puede ajustarse por contrato del comercio).
  final double baseRatePercent;

  static const exento = FiscalCategory(
    code: 'EXENTO',
    name: 'Exento / alimento',
    baseRatePercent: 0,
  );

  static const itbms7 = FiscalCategory(
    code: 'ITBMS_7',
    name: 'General / servicio',
    baseRatePercent: 7,
  );

  static const itbms10 = FiscalCategory(
    code: 'ITBMS_10',
    name: 'Alcohol / hospedaje',
    baseRatePercent: 10,
  );

  static const itbms15 = FiscalCategory(
    code: 'ITBMS_15',
    name: 'Tabaco',
    baseRatePercent: 15,
  );

  static const List<FiscalCategory> catalog = [
    exento,
    itbms7,
    itbms10,
    itbms15,
  ];

  static const String defaultCode = 'ITBMS_7';

  static FiscalCategory byCode(String? code) {
    final key = (code ?? defaultCode).trim().toUpperCase();
    for (final c in catalog) {
      if (c.code == key) return c;
    }
    return itbms7;
  }

  static String labelFor(String? code) => byCode(code).name;
}
