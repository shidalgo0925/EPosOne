import 'package:eposone/src/core/printing/esc_pos_bytes.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/products/domain/entities/selected_modifier.dart';
import 'package:eposone/src/features/products/domain/modifier_codec.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Línea de comanda (sin precios).
class KitchenTicketLine {
  final String productName;
  final double quantity;
  final List<SelectedModifier> modifiers;
  final String? note;

  const KitchenTicketLine({
    required this.productName,
    required this.quantity,
    this.modifiers = const [],
    this.note,
  });
}

/// Kitchen / Bar ticket — tipografía grande para lectura en cocina.
class KitchenTicketBuilder {
  /// Compat: solo texto (tamaño normal). Preferir [buildPrintLines].
  static List<String> build({
    required BusinessConfig? config,
    required String destinationName,
    required List<KitchenTicketLine> lines,
    String? orderLabel,
    String? comment,
    OrderType? orderType,
    String? customerName,
    DateTime? at,
  }) =>
      buildPrintLines(
        config: config,
        destinationName: destinationName,
        lines: lines,
        orderLabel: orderLabel,
        comment: comment,
        orderType: orderType,
        customerName: customerName,
        at: at,
      ).map((l) => l.text).toList();

  static List<EscPosPrintLine> buildPrintLines({
    required BusinessConfig? config,
    required String destinationName,
    required List<KitchenTicketLine> lines,
    String? orderLabel,
    String? comment,
    OrderType? orderType,
    String? customerName,
    DateTime? at,
  }) {
    final when = at ?? En1DateTimeService.nowUtc();
    final out = <EscPosPrintLine>[
      EscPosPrintLine(
        config?.businessName ?? 'EPOSOne',
        size: EscPosFontSize.doubleHeight,
        center: true,
      ),
      EscPosPrintLine(
        destinationName.toUpperCase(),
        size: EscPosFontSize.doubleBoth,
        center: true,
      ),
      EscPosPrintLine(
        En1DateTimeService.formatLocal(when, 'dd-MM-yyyy HH:mm'),
        size: EscPosFontSize.normal,
        center: true,
      ),
      const EscPosPrintLine('--------------------------------'),
    ];

    if (orderLabel != null && orderLabel.trim().isNotEmpty) {
      out.addAll(_wrapBig('Pedido: ${orderLabel.trim()}', EscPosFontSize.doubleBoth));
    }
    if (orderType != null) {
      out.add(EscPosPrintLine(
        'Tipo: ${orderTypeLabel(orderType)}',
        size: EscPosFontSize.doubleHeight,
      ));
    }
    if (customerName != null && customerName.trim().isNotEmpty) {
      out.addAll(_wrapBig(
        'Cliente: ${customerName.trim()}',
        EscPosFontSize.doubleHeight,
      ));
    }
    if (comment != null && comment.trim().isNotEmpty) {
      out.addAll(_wrapBig('Nota: ${comment.trim()}', EscPosFontSize.doubleHeight));
    }
    out.add(const EscPosPrintLine('--------------------------------'));

    for (final line in lines) {
      final qty = line.quantity % 1 == 0
          ? line.quantity.toStringAsFixed(0)
          : line.quantity.toStringAsFixed(2);
      out.addAll(
        _wrapBig('$qty x ${line.productName}', EscPosFontSize.doubleBoth),
      );
      final mods = ModifierCodec.modifiersLabel(line.modifiers);
      if (mods.isNotEmpty) {
        out.addAll(_wrapBig('+ $mods', EscPosFontSize.doubleHeight));
      }
      if (line.note != null && line.note!.trim().isNotEmpty) {
        out.addAll(
          _wrapBig('* ${line.note!.trim()}', EscPosFontSize.doubleHeight),
        );
      }
      out.add(const EscPosPrintLine(''));
    }

    out.addAll([
      const EscPosPrintLine('--------------------------------'),
      const EscPosPrintLine(
        '*** COMANDA ***',
        size: EscPosFontSize.doubleHeight,
        center: true,
      ),
    ]);
    return out;
  }

  static List<EscPosPrintLine> _wrapBig(String text, EscPosFontSize size) {
    final cols = EscPosPrintLine.colsFor(size);
    if (text.length <= cols) {
      return [EscPosPrintLine(text, size: size)];
    }
    final words = text.split(RegExp(r'\s+'));
    final rows = <EscPosPrintLine>[];
    var cur = '';
    for (final w in words) {
      final next = cur.isEmpty ? w : '$cur $w';
      if (next.length <= cols) {
        cur = next;
      } else {
        if (cur.isNotEmpty) rows.add(EscPosPrintLine(cur, size: size));
        if (w.length <= cols) {
          cur = w;
        } else {
          // Palabra más larga que el renglón: cortar.
          var rest = w;
          while (rest.length > cols) {
            rows.add(EscPosPrintLine(rest.substring(0, cols), size: size));
            rest = rest.substring(cols);
          }
          cur = rest;
        }
      }
    }
    if (cur.isNotEmpty) rows.add(EscPosPrintLine(cur, size: size));
    return rows;
  }
}
