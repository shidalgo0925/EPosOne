import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Telemetría operacional — cola y errores (no SQL).
class TelemetriaToolHandlers {
  TelemetriaToolHandlers({this.loadCola, this.loadErrores});

  final Future<Map<String, Object?>> Function()? loadCola;
  final Future<Map<String, Object?>> Function()? loadErrores;

  List<OpsToolDefinition> definitions() => [
        OpsToolDefinition(
          id: 'telemetria.consultar.cola',
          context: OpsContext.telemetria,
          verb: OpsVerb.consultar,
          title: 'Cola de sync',
          description: 'Pendientes y fallos por tipo de entidad',
          risk: OpsRisk.low,
          wired: loadCola != null,
          handler: (input, session) async {
            if (loadCola != null) return loadCola!();
            return {
              'wired': false,
              'pending': 0,
              'failed': 0,
              'message': 'Cola loader no inyectado',
            };
          },
        ),
        OpsToolDefinition(
          id: 'telemetria.analizar.errores',
          context: OpsContext.telemetria,
          verb: OpsVerb.analizar,
          title: 'Errores recientes',
          description: 'Últimos errores bootstrap / provisioning / sync',
          risk: OpsRisk.low,
          wired: loadErrores != null,
          handler: (input, session) async {
            if (loadErrores != null) return loadErrores!();
            return {
              'wired': false,
              'errors': <Object?>[],
              'message': 'Errores loader no inyectado',
            };
          },
        ),
      ];
}
