/// Operaciones monetarias a centavos (2 decimales).
abstract final class MoneyMath {
  /// Trunca hacia cero a [decimals] lugares — **sin redondear**.
  ///
  /// Ej.: `1.055` → `1.05`, `1.059` → `1.05` (no half-up via `toStringAsFixed`).
  static double truncate(double value, [int decimals = 2]) {
    if (value.isNaN || value.isInfinite) return 0;
    var factor = 1.0;
    for (var i = 0; i < decimals; i++) {
      factor *= 10;
    }
    return (value * factor).truncateToDouble() / factor;
  }
}
