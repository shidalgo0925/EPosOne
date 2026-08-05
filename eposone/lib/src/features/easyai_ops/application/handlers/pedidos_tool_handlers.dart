import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Pedidos — solo lectura Fase 1 (abiertos). Escrituras = Fase 2.
class PedidosToolHandlers {
  PedidosToolHandlers({this.loadAbiertos});

  final Future<Map<String, Object?>> Function()? loadAbiertos;

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
      ];
}
