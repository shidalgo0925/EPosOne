import 'ops_context.dart';
import 'ops_verb.dart';

enum OpsRisk { low, medium, high }

typedef OpsToolHandler = Future<Map<String, Object?>> Function(
  Map<String, Object?> input,
  OpsInvokeSession session,
);

/// Escritura de tool (abrir/cerrar/cancelar, …).
typedef OpsWriteFn = Future<Map<String, Object?>> Function(
  Map<String, Object?> input,
  OpsInvokeSession session,
);

/// Sesión de invocación EasyAI → Connector (ADR-017 Fase 2).
///
/// Escrituras exigen [authorized] == true y [actorId] no vacío.
/// Autorización vía PIN ([OpsAuth]) o marcada por el host tras su propio gate.
class OpsInvokeSession {
  const OpsInvokeSession({
    this.actorId,
    this.actorName,
    this.role = 'cashier',
    this.cashierContactId,
    this.channel = 'easyai',
    this.authorized = false,
    this.authMethod = 'none',
  });

  final String? actorId;
  final String? actorName;
  final String role;

  /// EN1 cashier_contact_id cuando aplica.
  final int? cashierContactId;
  final String channel;

  /// Explicit auth for write verbs (Fase 2).
  final bool authorized;

  /// `none` | `pin` | `session` | `host`
  final String authMethod;
}

/// Public tool descriptor — never exposes tables.
class OpsToolDefinition {
  const OpsToolDefinition({
    required this.id,
    required this.context,
    required this.verb,
    required this.title,
    required this.description,
    required this.handler,
    this.risk = OpsRisk.low,
    this.requiresAuth = false,
    this.inputSchema = const {},
    this.outputSchema = const {},
    this.wired = false,
  });

  final String id;
  final OpsContext context;
  final OpsVerb verb;
  final String title;
  final String description;
  final OpsToolHandler handler;
  final OpsRisk risk;
  final bool requiresAuth;
  final Map<String, Object?> inputSchema;
  final Map<String, Object?> outputSchema;

  /// true when handler talks to real domain (not stub).
  final bool wired;

  Map<String, Object?> toCatalogJson() => {
        'id': id,
        'context': context.id,
        'verb': verb.id,
        'title': title,
        'description': description,
        'risk': risk.name,
        'requires_auth': requiresAuth || verb.isWrite,
        'wired': wired,
        'input_schema': inputSchema,
        'output_schema': outputSchema,
      };
}
