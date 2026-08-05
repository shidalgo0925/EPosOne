import '../domain/ops_context.dart';
import '../domain/ops_tool_definition.dart';
import '../domain/ops_tool_result.dart';
import '../domain/ops_verb.dart';
import 'handlers/occ_tool_handlers.dart';
import 'handlers/turnos_tool_handlers.dart';
import 'ops_tool_registry.dart';

/// Única fachada EasyAI ↔ EPOSOne (ADR-017).
///
/// No expone tablas. No ejecuta IA.
class OperationsConnector {
  OperationsConnector({
    OccToolHandlers? occ,
    TurnosToolHandlers? turnos,
  }) : _registry = OpsToolRegistry(occ: occ, turnos: turnos);

  final OpsToolRegistry _registry;

  List<Map<String, Object?>> listContexts() => [
        for (final c in _registry.contexts())
          {'id': c.id, 'label': c.label},
      ];

  List<Map<String, Object?>> listTools({String? contextId}) {
    OpsContext? ctx;
    if (contextId != null) {
      for (final c in OpsContext.values) {
        if (c.id == contextId) {
          ctx = c;
          break;
        }
      }
      if (ctx == null) return const [];
    }
    return [
      for (final t in _registry.listTools(context: ctx)) t.toCatalogJson(),
    ];
  }

  Map<String, Object?>? describeTool(String toolId) =>
      _registry.get(toolId)?.toCatalogJson();

  Future<OpsToolResult> invoke(
    String toolId,
    Map<String, Object?> input, {
    OpsInvokeSession session = const OpsInvokeSession(),
  }) async {
    if (OpsToolRegistry.looksLikeRawDataAccess(toolId)) {
      return OpsToolResult.rejected(
        toolId: toolId,
        code: 'raw_access_forbidden',
        message: 'Acceso directo a datos/tablas prohibido. Use herramientas publicadas.',
      );
    }

    final tool = _registry.get(toolId);
    if (tool == null) {
      return OpsToolResult.rejected(
        toolId: toolId,
        code: 'tool_not_found',
        message: 'Herramienta no publicada: $toolId',
      );
    }

    if (tool.verb.isWrite && (tool.requiresAuth || tool.risk == OpsRisk.high)) {
      if (!session.authorized) {
        return OpsToolResult.rejected(
          toolId: toolId,
          code: 'authorization_required',
          message: 'Verbo de escritura requiere autorización',
        );
      }
    }

    try {
      final data = await tool.handler(input, session);
      return OpsToolResult.ok(toolId, {
        ...data,
        'context': tool.context.id,
        'verb': tool.verb.id,
      });
    } catch (e) {
      return OpsToolResult.error(toolId: toolId, message: '$e');
    }
  }
}
