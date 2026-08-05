/// Money helpers for Discount Domain — integer cents only.
abstract final class MoneyCents {
  static int fromDecimalString(String value) {
    final t = value.trim();
    if (t.isEmpty) return 0;
    final neg = t.startsWith('-');
    final raw = neg ? t.substring(1) : t;
    final parts = raw.split('.');
    final whole = int.parse(parts[0].isEmpty ? '0' : parts[0]);
    var frac = 0;
    if (parts.length > 1) {
      final f = parts[1].padRight(2, '0').substring(0, 2);
      frac = int.parse(f);
    }
    final cents = whole * 100 + frac;
    return neg ? -cents : cents;
  }

  static String toDecimalString(int cents) {
    final neg = cents < 0;
    final a = cents.abs();
    final whole = a ~/ 100;
    final frac = (a % 100).toString().padLeft(2, '0');
    return '${neg ? '-' : ''}$whole.$frac';
  }

  /// Spread [total] across [weights] so sum(parts) == total (largest remainder).
  static List<int> allocateByWeight(int total, List<int> weights) {
    if (weights.isEmpty) return const [];
    final sumW = weights.fold<int>(0, (a, b) => a + b);
    if (sumW <= 0 || total == 0) {
      return List<int>.filled(weights.length, 0);
    }
    final exact = <double>[];
    final floors = <int>[];
    var assigned = 0;
    for (final w in weights) {
      final e = total * (w / sumW);
      exact.add(e);
      final f = e.floor();
      floors.add(f);
      assigned += f;
    }
    var rem = total - assigned;
    final order = List.generate(weights.length, (i) => i)
      ..sort((a, b) {
        final fa = exact[a] - floors[a];
        final fb = exact[b] - floors[b];
        return fb.compareTo(fa);
      });
    final out = List<int>.from(floors);
    for (var i = 0; rem > 0 && i < order.length; i++) {
      out[order[i]] += 1;
      rem -= 1;
    }
    return out;
  }
}
