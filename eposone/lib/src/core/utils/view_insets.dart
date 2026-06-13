import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Insets del sistema — fallback para tablets que no reportan la barra de navegación.
abstract final class ViewInsets {
  static double bottom(BuildContext context, {double extra = 8}) {
    final mq = MediaQuery.of(context);
    final reported = math.max(mq.viewPadding.bottom, mq.padding.bottom);
    if (reported > 0) return reported + extra;
    // Gestural nav bar en tablets Allwinner/Xiaomi sin inset reportado.
    if (defaultTargetPlatform == TargetPlatform.android) return 48 + extra;
    return extra;
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
