import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Turnos = CashRegister en EPOSOne V1 (mismo dominio que caja).
class TurnosToolHandlers {
  TurnosToolHandlers({
    this.loadCurrentShift,
    this.loadHistorial,
    this.openTurno,
    this.closeTurno,
  });

  final Future<Map<String, Object?>> Function()? loadCurrentShift;
  final Future<Map<String, Object?>> Function(Map<String, Object?> input)?
      loadHistorial;
  final OpsWriteFn? openTurno;
  final OpsWriteFn? closeTurno;

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
              'message': 'Shift loader no inyectado',
            };
          },
        ),
        OpsToolDefinition(
          id: 'turnos.consultar.historial',
          context: OpsContext.turnos,
          verb: OpsVerb.consultar,
          title: 'Historial de turnos',
          description: 'Últimos N turnos de caja',
          risk: OpsRisk.low,
          wired: loadHistorial != null,
          inputSchema: const {'limit': 'int?'},
          handler: (input, session) async {
            if (loadHistorial != null) return loadHistorial!(input);
            return {
              'wired': false,
              'items': <Object?>[],
              'message': 'Historial loader no inyectado',
            };
          },
        ),
        OpsToolDefinition(
          id: 'turnos.abrir',
          context: OpsContext.turnos,
          verb: OpsVerb.abrir,
          title: 'Abrir turno',
          description: 'Alias operacional de caja.abrir',
          risk: OpsRisk.high,
          requiresAuth: true,
          wired: openTurno != null,
          inputSchema: const {'opening_amount': 'number'},
          handler: (input, session) async {
            if (openTurno == null) {
              return {
                'wired': false,
                'tool_id': 'turnos.abrir',
                'message': 'Abrir turno no cableado',
              };
            }
            return openTurno!(input, session);
          },
        ),
        OpsToolDefinition(
          id: 'turnos.cerrar',
          context: OpsContext.turnos,
          verb: OpsVerb.cerrar,
          title: 'Cerrar turno',
          description: 'Alias operacional de caja.cerrar',
          risk: OpsRisk.high,
          requiresAuth: true,
          wired: closeTurno != null,
          inputSchema: const {
            'counted_amount': 'number',
            'notes': 'string?',
          },
          handler: (input, session) async {
            if (closeTurno == null) {
              return {
                'wired': false,
                'tool_id': 'turnos.cerrar',
                'message': 'Cerrar turno no cableado',
              };
            }
            return closeTurno!(input, session);
          },
        ),
      ];
}
