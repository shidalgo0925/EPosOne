import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Licencias — snapshot + riesgo vencimiento (ADR-007).
class LicenciasToolHandlers {
  LicenciasToolHandlers({this.loadSnapshot, this.loadVencimiento});

  final Future<Map<String, Object?>> Function()? loadSnapshot;
  final Future<Map<String, Object?>> Function()? loadVencimiento;

  List<OpsToolDefinition> definitions() => [
        OpsToolDefinition(
          id: 'licencias.consultar',
          context: OpsContext.licencias,
          verb: OpsVerb.consultar,
          title: 'Licencia',
          description: 'Snapshot + estado efectivo (sin crear licencias)',
          risk: OpsRisk.low,
          wired: loadSnapshot != null,
          handler: (input, session) async {
            if (loadSnapshot != null) return loadSnapshot!();
            return {
              'wired': false,
              'present': false,
              'message': 'License loader no inyectado',
            };
          },
        ),
        OpsToolDefinition(
          id: 'licencias.analizar.vencimiento',
          context: OpsContext.licencias,
          verb: OpsVerb.analizar,
          title: 'Riesgo de vencimiento',
          description: 'Gracia / expiración / suspensión',
          risk: OpsRisk.medium,
          wired: loadVencimiento != null,
          handler: (input, session) async {
            if (loadVencimiento != null) return loadVencimiento!();
            return {
              'wired': false,
              'risk': 'unknown',
              'message': 'Vencimiento loader no inyectado',
            };
          },
        ),
      ];
}
