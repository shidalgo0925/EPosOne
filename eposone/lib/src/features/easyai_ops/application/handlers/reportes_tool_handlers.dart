import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Reportes — solo catálogo de informes disponibles (OCC ≠ reportes).
class ReportesToolHandlers {
  List<OpsToolDefinition> definitions() => [
        OpsToolDefinition(
          id: 'reportes.consultar.disponibles',
          context: OpsContext.reportes,
          verb: OpsVerb.consultar,
          title: 'Informes disponibles',
          description: 'Lista de reportes de producto (sin datos crudos ni SQL)',
          risk: OpsRisk.low,
          wired: true,
          handler: (input, session) async => {
                'reports': const [
                  {
                    'id': 'ventas',
                    'title': 'Ventas',
                    'route': '/reports/sales',
                  },
                  {
                    'id': 'turnos',
                    'title': 'Caja / Turnos',
                    'route': '/reports/shifts',
                  },
                  {
                    'id': 'empleados',
                    'title': 'Empleados / Productos',
                    'route': '/reports/employees',
                  },
                  {
                    'id': 'clientes',
                    'title': 'Clientes (historial por ficha)',
                    'route': '/customers',
                  },
                ],
                'note': 'OCC no sustituye reportes históricos',
              },
        ),
      ];
}
