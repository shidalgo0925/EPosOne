import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Pedidos — lectura + cancelar (Fase 2). Crear/actualizar/cerrar = pendiente.
class PedidosToolHandlers {
  PedidosToolHandlers({
    this.loadAbiertos,
    this.loadPorId,
    this.cancelar,
  });

  final Future<Map<String, Object?>> Function()? loadAbiertos;
  final Future<Map<String, Object?>> Function(Map<String, Object?> input)?
      loadPorId;
  final OpsWriteFn? cancelar;

  List<OpsToolDefinition> definitions() => [
        OpsToolDefinition(
          id: 'pedidos.consultar.abiertos',
          context: OpsContext.pedidos,
          verb: OpsVerb.consultar,
          title: 'Pedidos abiertos',
          description: 'Tickets / OpenTicket abiertos en este dispositivo',
          risk: OpsRisk.low,
          wired: loadAbiertos != null,
          handler: (input, session) async {
            if (loadAbiertos != null) return loadAbiertos!();
            return {
              'wired': false,
              'count': 0,
              'tickets': <Object?>[],
              'message': 'Pedidos loader no inyectado',
            };
          },
        ),
        OpsToolDefinition(
          id: 'pedidos.consultar.por_id',
          context: OpsContext.pedidos,
          verb: OpsVerb.consultar,
          title: 'Detalle pedido',
          description: 'Ticket abierto o cancelado por id local',
          risk: OpsRisk.low,
          wired: loadPorId != null,
          inputSchema: const {'ticket_id': 'string'},
          handler: (input, session) async {
            if (loadPorId != null) return loadPorId!(input);
            return {
              'wired': false,
              'message': 'Detalle loader no inyectado',
            };
          },
        ),
        OpsToolDefinition(
          id: 'pedidos.cancelar',
          context: OpsContext.pedidos,
          verb: OpsVerb.cancelar,
          title: 'Cancelar pedido',
          description: 'Cancela OpenTicket local (requiere auth)',
          risk: OpsRisk.high,
          requiresAuth: true,
          wired: cancelar != null,
          inputSchema: const {
            'ticket_id': 'string',
            'reason': 'string?',
          },
          handler: (input, session) async {
            if (cancelar == null) {
              return {
                'wired': false,
                'tool_id': 'pedidos.cancelar',
                'message': 'Cancelar pedido no cableado',
              };
            }
            return cancelar!(input, session);
          },
        ),
      ];
}
