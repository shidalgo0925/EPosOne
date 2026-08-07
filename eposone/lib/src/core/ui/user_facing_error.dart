/// Mensajes seguros para UI. Nunca exponer Exception/StackTrace/HTTP crudo.
String userFacingError(Object error, {String fallback = 'Ocurrió un problema. Intenta de nuevo.'}) {
  if (error is String) {
    final t = error.trim();
    if (t.isEmpty) return fallback;
    if (_looksTechnical(t)) return fallback;
    return t;
  }
  try {
    // En1ProvisioningException / Onboarding / Bootstrap con userMessage o message.
    final dynamic d = error;
    final um = d.userMessage;
    if (um is String && um.trim().isNotEmpty && !_looksTechnical(um)) {
      return um.trim();
    }
  } catch (_) {}
  try {
    final dynamic d = error;
    final m = d.message;
    if (m is String && m.trim().isNotEmpty && !_looksTechnical(m)) {
      return m.trim();
    }
  } catch (_) {}

  final raw = error.toString();
  if (_looksTechnical(raw)) return fallback;
  // Quitar prefijo "Exception: " si quedó algo legible.
  final cleaned = raw
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^En1\w+Exception:\s*'), '')
      .trim();
  if (cleaned.isEmpty || _looksTechnical(cleaned)) return fallback;
  return cleaned;
}

bool _looksTechnical(String t) {
  final lower = t.toLowerCase();
  return lower.contains('stacktrace') ||
      lower.contains('socketexception') ||
      lower.contains('httpexception') ||
      lower.contains('handshakeexception') ||
      lower.contains('formatexception') ||
      RegExp(r'\bHTTP\s*\d{3}\b', caseSensitive: false).hasMatch(t) ||
      lower.contains('#0 ') ||
      lower.contains('dart:') ||
      lower.contains('package:');
}
