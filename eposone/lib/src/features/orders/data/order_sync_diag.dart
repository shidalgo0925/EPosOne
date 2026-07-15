import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Diagnóstico Hito 3C — solo instrumentación Sync Pedido.
/// No cambia reglas de negocio.
class OrderSyncDiag {
  OrderSyncDiag._();

  static final List<String> _lines = [];
  static const _max = 400;

  static List<String> get lines => List.unmodifiable(_lines);

  static String get asText => _lines.join('\n');

  static void clear() => _lines.clear();

  static void log(String message) {
    final line = '${DateTime.now().toIso8601String()}  $message';
    _lines.add(line);
    while (_lines.length > _max) {
      _lines.removeAt(0);
    }
    // print (no solo debugPrint) para ver en logcat release.
    // ignore: avoid_print
    print('[EN1 Order Sync] $message');
    debugPrint('[EN1 Order Sync] $message');
  }

  static void section(String title) {
    log('──────── $title ────────');
  }

  static void jsonBlock(String label, Object? value) {
    try {
      if (value == null) {
        log('$label: <null>');
        return;
      }
      final pretty = const JsonEncoder.withIndent('  ').convert(value);
      log('$label:\n$pretty');
    } catch (_) {
      log('$label: $value');
    }
  }

  static String maskBearer(String token) {
    final t = token.trim();
    if (t.length <= 12) return 'Bearer ***';
    return 'Bearer ${t.substring(0, 6)}…${t.substring(t.length - 4)} (len=${t.length})';
  }
}
