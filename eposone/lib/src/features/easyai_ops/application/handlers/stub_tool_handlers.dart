import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Tools declared in catalog but not wired — still published as Plan stubs.
class StubToolHandlers {
  List<OpsToolDefinition> plannedDefinitions() {
    final specs = <(String, OpsContext, OpsVerb, String)>[
      ('caja.consultar.estado', OpsContext.caja, OpsVerb.consultar, 'Estado de caja'),
      ('caja.cerrar', OpsContext.caja, OpsVerb.cerrar, 'Cerrar caja / arqueo'),
      ('caja.abrir', OpsContext.caja, OpsVerb.abrir, 'Abrir caja'),
      ('pedidos.consultar.abiertos', OpsContext.pedidos, OpsVerb.consultar,
          'Pedidos/tickets abiertos'),
      ('pedidos.cancelar', OpsContext.pedidos, OpsVerb.cancelar, 'Cancelar/anular pedido'),
      ('clientes.consultar', OpsContext.clientes, OpsVerb.consultar, 'Consultar clientes'),
      ('inventario.consultar.stock', OpsContext.inventario, OpsVerb.consultar,
          'Consultar stock'),
      ('productos.consultar', OpsContext.productos, OpsVerb.consultar, 'Consultar productos'),
      ('ventas.analizar.resumen_hoy', OpsContext.ventas, OpsVerb.analizar,
          'Resumen ventas hoy'),
      ('dispositivos.consultar.este', OpsContext.dispositivos, OpsVerb.consultar,
          'Este dispositivo'),
      ('telemetria.consultar.cola', OpsContext.telemetria, OpsVerb.consultar,
          'Cola de sync'),
      ('licencias.consultar', OpsContext.licencias, OpsVerb.consultar, 'Licencia'),
      ('reportes.consultar.disponibles', OpsContext.reportes, OpsVerb.consultar,
          'Informes disponibles'),
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
