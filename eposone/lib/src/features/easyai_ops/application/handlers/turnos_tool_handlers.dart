import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

class TurnosToolHandlers {
  TurnosToolHandlers({this.loadCurrentShift});

  final Future<Map<String, Object?>> Function()? loadCurrentShift;

  List<OpsToolDefinition> definitions() => [
        OpsToolDefinition(
          id: 'turnos.consultar.actual',
          context: OpsContext.turnos,
          verb: OpsVerb.consultar,
          title: 'Turno actual',
          description: 'Turno/caja abierta en este dispositivo',
          risk: OpsRisk.low,
          wired: loadCurrentShift != null,
          handler: (input, session) async {
            if (loadCurrentShift != null) return loadCurrentShift!();
            return {
              'wired': false,
              'open': false,
              'message': 'Shift loader no inyectado (Fase 0)',
            };
          },
        ),
      ];
}
