import '../domain/ops_context.dart';
import '../domain/ops_tool_definition.dart';
import 'handlers/caja_tool_handlers.dart';
import 'handlers/dispositivos_tool_handlers.dart';
import 'handlers/licencias_tool_handlers.dart';
import 'handlers/occ_tool_handlers.dart';
import 'handlers/pedidos_tool_handlers.dart';
import 'handlers/reportes_tool_handlers.dart';
import 'handlers/stub_tool_handlers.dart';
import 'handlers/telemetria_tool_handlers.dart';
import 'handlers/turnos_tool_handlers.dart';
import 'handlers/ventas_tool_handlers.dart';

/// Catálogo in-process. Sin SQL / Isar expuesto.
class OpsToolRegistry {
  OpsToolRegistry({
    OccToolHandlers? occ,
    TurnosToolHandlers? turnos,
    CajaToolHandlers? caja,
    DispositivosToolHandlers? dispositivos,
    TelemetriaToolHandlers? telemetria,
    LicenciasToolHandlers? licencias,
    PedidosToolHandlers? pedidos,
    VentasToolHandlers? ventas,
    ReportesToolHandlers? reportes,
  }) : _tools = _build(
          occ: occ ?? OccToolHandlers(),
          turnos: turnos ?? TurnosToolHandlers(),
          caja: caja ?? CajaToolHandlers(),
          dispositivos: dispositivos ?? DispositivosToolHandlers(),
          telemetria: telemetria ?? TelemetriaToolHandlers(),
          licencias: licencias ?? LicenciasToolHandlers(),
          pedidos: pedidos ?? PedidosToolHandlers(),
          ventas: ventas ?? VentasToolHandlers(),
          reportes: reportes ?? ReportesToolHandlers(),
        );

  final Map<String, OpsToolDefinition> _tools;

  static Map<String, OpsToolDefinition> _build({
    required OccToolHandlers occ,
    required TurnosToolHandlers turnos,
    required CajaToolHandlers caja,
    required DispositivosToolHandlers dispositivos,
    required TelemetriaToolHandlers telemetria,
    required LicenciasToolHandlers licencias,
    required PedidosToolHandlers pedidos,
    required VentasToolHandlers ventas,
    required ReportesToolHandlers reportes,
  }) {
    final stubs = StubToolHandlers();
    final list = <OpsToolDefinition>[
      ...occ.definitions(),
      ...turnos.definitions(),
      ...caja.definitions(),
      ...dispositivos.definitions(),
      ...telemetria.definitions(),
      ...licencias.definitions(),
      ...pedidos.definitions(),
      ...ventas.definitions(),
      ...reportes.definitions(),
      ...stubs.plannedDefinitions(),
    ];
    return {for (final t in list) t.id: t};
  }

  List<OpsContext> contexts() => OpsContext.values;

  List<OpsToolDefinition> listTools({OpsContext? context}) {
    final all = _tools.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (context == null) return all;
    return all.where((t) => t.context == context).toList();
  }

  OpsToolDefinition? get(String toolId) => _tools[toolId];

  /// Rejects any attempt to treat arbitrary strings as table access.
  static bool looksLikeRawDataAccess(String toolId) {
    final t = toolId.toLowerCase();
    return t.contains('sql') ||
        t.contains('isar') ||
        t.contains('table') ||
        t.contains('query_raw') ||
        t.contains('select ') ||
        t.startsWith('db.');
  }
}
