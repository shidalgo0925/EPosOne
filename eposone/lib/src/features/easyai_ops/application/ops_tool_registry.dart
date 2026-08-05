import '../domain/ops_context.dart';
import '../domain/ops_tool_definition.dart';
import '../domain/ops_verb.dart';
import 'handlers/occ_tool_handlers.dart';
import 'handlers/stub_tool_handlers.dart';
import 'handlers/turnos_tool_handlers.dart';

/// Catálogo in-process. Sin SQL / Isar expuesto.
class OpsToolRegistry {
  OpsToolRegistry({
    OccToolHandlers? occ,
    TurnosToolHandlers? turnos,
  }) : _tools = _build(
          occ: occ ?? OccToolHandlers(),
          turnos: turnos ?? TurnosToolHandlers(),
        );

  final Map<String, OpsToolDefinition> _tools;

  static Map<String, OpsToolDefinition> _build({
    required OccToolHandlers occ,
    required TurnosToolHandlers turnos,
  }) {
    final stubs = StubToolHandlers();
    final list = <OpsToolDefinition>[
      ...occ.definitions(),
      ...turnos.definitions(),
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

/// Forbidden verb / id helpers.
abstract final class OpsVerbGuard {
  static bool isAllowedVerb(String verb) =>
      OpsVerb.values.any((v) => v.id == verb);
}
