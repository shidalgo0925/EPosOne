import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Tools declared in catalog but not wired — still published as Plan stubs.
/// Write verbs stay stubbed until Fase 2 (auth real).
class StubToolHandlers {
  List<OpsToolDefinition> plannedDefinitions() {
    final specs = <(String, OpsContext, OpsVerb, String)>[
      ('caja.cerrar', OpsContext.caja, OpsVerb.cerrar, 'Cerrar caja / arqueo'),
      ('caja.abrir', OpsContext.caja, OpsVerb.abrir, 'Abrir caja'),
      ('turnos.consultar.historial', OpsContext.turnos, OpsVerb.consultar,
          'Historial de turnos'),
      ('turnos.abrir', OpsContext.turnos, OpsVerb.abrir, 'Abrir turno'),
      ('turnos.cerrar', OpsContext.turnos, OpsVerb.cerrar, 'Cerrar turno'),
      ('pedidos.consultar.por_id', OpsContext.pedidos, OpsVerb.consultar,
          'Detalle pedido'),
      ('pedidos.crear', OpsContext.pedidos, OpsVerb.crear, 'Alta pedido'),
      ('pedidos.actualizar', OpsContext.pedidos, OpsVerb.actualizar,
          'Modificar líneas'),
      ('pedidos.cancelar', OpsContext.pedidos, OpsVerb.cancelar, 'Cancelar/anular pedido'),
      ('pedidos.cerrar', OpsContext.pedidos, OpsVerb.cerrar, 'Cobrar / cerrar pedido'),
      ('clientes.consultar', OpsContext.clientes, OpsVerb.consultar, 'Consultar clientes'),
      ('clientes.crear', OpsContext.clientes, OpsVerb.crear, 'Alta cliente'),
      ('clientes.actualizar', OpsContext.clientes, OpsVerb.actualizar, 'Editar cliente'),
      ('inventario.consultar.stock', OpsContext.inventario, OpsVerb.consultar,
          'Consultar stock'),
      ('inventario.actualizar.ajuste', OpsContext.inventario, OpsVerb.actualizar,
          'Ajuste de inventario'),
      ('inventario.analizar.alertas', OpsContext.inventario, OpsVerb.analizar,
          'Alertas bajo mínimo'),
      ('productos.consultar', OpsContext.productos, OpsVerb.consultar, 'Consultar productos'),
      ('productos.crear', OpsContext.productos, OpsVerb.crear, 'Alta producto'),
      ('productos.actualizar', OpsContext.productos, OpsVerb.actualizar,
          'Actualizar producto'),
      ('ventas.consultar', OpsContext.ventas, OpsVerb.consultar, 'Consultar venta'),
      ('ventas.cancelar', OpsContext.ventas, OpsVerb.cancelar, 'Anular / reembolso'),
      ('reportes.analizar.ventas_periodo', OpsContext.reportes, OpsVerb.analizar,
          'Agregado ventas periodo'),
    ];

    return [
      for (final s in specs)
        OpsToolDefinition(
          id: s.$1,
          context: s.$2,
          verb: s.$3,
          title: s.$4,
          description: '${s.$4} (planificado — no cableado)',
          risk: s.$3.isWrite ? OpsRisk.high : OpsRisk.low,
          requiresAuth: s.$3.isWrite,
          wired: false,
          handler: (input, session) async => {
                'wired': false,
                'tool_id': s.$1,
                'message': 'Tool publicado en catálogo; handler dominio pendiente',
              },
        ),
    ];
  }
}
