import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Ventas — agregar del día (no SQL crudo).
class VentasToolHandlers {
  VentasToolHandlers({this.loadResumenHoy});

  final Future<Map<String, Object?>> Function()? loadResumenHoy;

  List<OpsToolDefinition> definitions() => [
        OpsToolDefinition(
          id: 'ventas.analizar.resumen_hoy',
          context: OpsContext.ventas,
          verb: OpsVerb.analizar,
          title: 'Resumen ventas hoy',
          description: 'Totales del día de negocio (UTC→zona EN1)',
          risk: OpsRisk.low,
          wired: loadResumenHoy != null,
          handler: (input, session) async {
            if (loadResumenHoy != null) return loadResumenHoy!();
            return {
              'wired': false,
              'sale_count': 0,
              'gross_total': 0.0,
              'message': 'Ventas loader no inyectado',
            };
          },
        ),
      ];
}
