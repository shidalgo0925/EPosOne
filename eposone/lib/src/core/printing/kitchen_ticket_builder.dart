import 'package:eposone/src/core/printing/thermal_ops_text.dart';
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

/// Kitchen / Bar ticket — mismo ancho de papel que el resto.
class KitchenTicketBuilder {
  static List<String> build({
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
    final out = <String>[
      ThermalOpsText.center(config?.businessName ?? 'EPOSOne'),
      ThermalOpsText.center(destinationName.toUpperCase()),
      ThermalOpsText.center(
          En1DateTimeService.formatLocal(when, 'dd-MM-yyyy HH:mm')),
      ThermalOpsText.line(),
      if (orderLabel != null && orderLabel.trim().isNotEmpty)
        'Pedido: ${orderLabel.trim()}',
      if (orderType != null) 'Tipo: ${orderTypeLabel(orderType)}',
      if (customerName != null && customerName.trim().isNotEmpty)
        'Cliente: ${customerName.trim()}',
      if (comment != null && comment.trim().isNotEmpty)
        'Nota: ${comment.trim()}',
      ThermalOpsText.line(),
    ];

    for (final line in lines) {
      final qty = line.quantity % 1 == 0
          ? line.quantity.toStringAsFixed(0)
          : line.quantity.toStringAsFixed(2);
      out.add('$qty x ${line.productName}');
      final mods = ModifierCodec.modifiersLabel(line.modifiers);
      if (mods.isNotEmpty) out.add('  + $mods');
      if (line.note != null && line.note!.trim().isNotEmpty) {
        out.add('  * ${line.note!.trim()}');
      }
    }

    out.addAll([
      ThermalOpsText.line(),
      ThermalOpsText.center('*** COMANDA ***'),
    ]);
    return out;
  }
}
