import 'ops_tool_definition.dart';

/// Resultado de autorización operacional (PIN / sesión). Sin IA.
class OpsAuthResult {
  const OpsAuthResult._({
    required this.ok,
    this.session,
    this.code,
    this.message,
  });

  factory OpsAuthResult.success(OpsInvokeSession session) => OpsAuthResult._(
        ok: true,
        session: session,
      );

  factory OpsAuthResult.failure({
    required String code,
    required String message,
  }) =>
      OpsAuthResult._(ok: false, code: code, message: message);

  final bool ok;
  final OpsInvokeSession? session;
  final String? code;
  final String? message;

  Map<String, Object?> toJson() => {
        'ok': ok,
        if (code != null) 'code': code,
        if (message != null) 'message': message,
        if (session != null)
          'session': {
            'actor_id': session!.actorId,
            'actor_name': session!.actorName,
            'role': session!.role,
            'cashier_contact_id': session!.cashierContactId,
            'authorized': session!.authorized,
            'auth_method': session!.authMethod,
            'channel': session!.channel,
          },
      };
}
