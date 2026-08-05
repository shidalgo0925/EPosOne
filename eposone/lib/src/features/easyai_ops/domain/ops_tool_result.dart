enum OpsToolStatus { ok, rejected, error }

/// Structured result — EasyAI never sees raw DB rows.
class OpsToolResult {
  const OpsToolResult({
    required this.status,
    required this.toolId,
    this.data,
    this.code,
    this.message,
  });

  final OpsToolStatus status;
  final String toolId;
  final Map<String, Object?>? data;
  final String? code;
  final String? message;

  factory OpsToolResult.ok(String toolId, Map<String, Object?> data) =>
      OpsToolResult(status: OpsToolStatus.ok, toolId: toolId, data: data);

  factory OpsToolResult.rejected({
    required String toolId,
    required String code,
    required String message,
  }) =>
      OpsToolResult(
        status: OpsToolStatus.rejected,
        toolId: toolId,
        code: code,
        message: message,
      );

  factory OpsToolResult.error({
    required String toolId,
    required String message,
  }) =>
      OpsToolResult(
        status: OpsToolStatus.error,
        toolId: toolId,
        code: 'error',
        message: message,
      );

  Map<String, Object?> toJson() => {
        'status': status.name,
        'tool_id': toolId,
        if (code != null) 'code': code,
        if (message != null) 'message': message,
        if (data != null) 'data': data,
      };
}
