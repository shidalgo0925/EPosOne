import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Insets del sistema — fallback para tablets que no reportan la barra de navegación.
abstract final class ViewInsets {
  /// [compact]: chrome POS (ticket / grid) — evita franja muerta de ~56 px.
  static double bottom(
    BuildContext context, {
    double extra = 8,
    bool compact = false,
  }) {
    final mq = MediaQuery.of(context);
    final reported = math.max(mq.viewPadding.bottom, mq.padding.bottom);
    if (reported > 0) return reported + (compact ? math.min(extra, 4) : extra);
    if (defaultTargetPlatform != TargetPlatform.android) return extra;
    // Sin inset reportado: phone sigue con margen seguro; tablet landscape
    // solo un respiro mínimo (antes 48+extra dejaba hueco bajo COBRAR).
    final isTablet = mq.size.shortestSide >= 600;
    if (compact || isTablet) return (compact ? 6 : 12) + extra;
    return 48 + extra;
  }

  static EdgeInsets screenPadding(BuildContext context, {double horizontal = 0, double top = 0, double extra = 8}) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      bottom(context, extra: extra),
    );
  }
}
