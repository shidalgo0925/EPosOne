import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:eposone/src/features/platform/domain/provisioning_config.dart';

/// Clasificación de error de provisioning (UX + depuración).
enum En1ProvisioningErrorKind {
  offline,
  timeout,
  serverUnavailable,
  invalidActivationCode,
  unauthorized,
  conflict,
  validation,
  notFound,
  serverError,
  unknown,
}

/// Excepción de provisioning con mensaje para el usuario y detalle técnico.
class En1ProvisioningException implements Exception {
  final String userMessage;
  final String technicalDetail;
  final En1ProvisioningErrorKind kind;
  final int? statusCode;
  final String? serverErrorCode;

  En1ProvisioningException({
    required this.userMessage,
    required this.technicalDetail,
    this.kind = En1ProvisioningErrorKind.unknown,
    this.statusCode,
    this.serverErrorCode,
  });

  /// Compatibilidad: `toString` / catch genérico muestran el mensaje UX.
  @override
  String toString() => userMessage;

  String get message => userMessage;
}

/// Cliente HTTP de provisioning EN1 — contrato v0.1.
class En1ProvisioningApi {
  En1ProvisioningApi({HttpClient? httpClient}) : _http = httpClient ?? HttpClient();

  final HttpClient _http;
  static const _timeout = Duration(seconds: 25);

  Future<ProvisioningConfig> registerDevice({
    required String apiBaseUrl,
    required DeviceRegistrationRequest request,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final uri = Uri.parse('$base/api/v1/devices/register');
    final payload = await _postJson(uri, body: request.toJson());
    return _parseConfig(payload, apiBaseUrl: base, deviceUuid: request.uuid);
  }

  Future<ProvisioningConfig> fetchConfig({
    required String apiBaseUrl,
    required String accessToken,
    required String deviceUuid,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final uri = Uri.parse('$base/api/v1/devices/config');
    final payload = await _getJson(uri, bearerToken: accessToken);
    return _parseConfig(payload, apiBaseUrl: base, deviceUuid: deviceUuid);
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final req = await _http.postUrl(uri).timeout(_timeout);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close().timeout(_timeout);
      return _decodeResponse(res, uri);
    } on En1ProvisioningException {
      rethrow;
    } catch (e, st) {
      throw _mapTransportError(e, st, uri);
    }
  }

  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    required String bearerToken,
  }) async {
    try {
      final req = await _http.getUrl(uri).timeout(_timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
      final res = await req.close().timeout(_timeout);
      return _decodeResponse(res, uri);
    } on En1ProvisioningException {
      rethrow;
    } catch (e, st) {
      throw _mapTransportError(e, st, uri);
    }
  }

  Future<Map<String, dynamic>> _decodeResponse(HttpClientResponse res, Uri uri) async {
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _mapHttpError(res.statusCode, text, uri);
    }
    if (text.isEmpty) {
      final ex = En1ProvisioningException(
        userMessage: 'Servidor EN1 no disponible. Respuesta vacía.',
        technicalDetail: 'Empty body ${uri.path} status=${res.statusCode}',
        kind: En1ProvisioningErrorKind.serverUnavailable,
        statusCode: res.statusCode,
      );
      _logTechnical(ex);
      throw ex;
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      final ex = En1ProvisioningException(
        userMessage: 'Servidor EN1 no disponible. Respuesta inválida.',
        technicalDetail: 'Non-object JSON ${uri.path}: $text',
        kind: En1ProvisioningErrorKind.serverUnavailable,
        statusCode: res.statusCode,
      );
      _logTechnical(ex);
      throw ex;
    }
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    return decoded;
  }

  En1ProvisioningException _mapHttpError(int status, String body, Uri uri) {
    final parsed = _parseErrorBody(body);
    final serverCode = parsed?.code;
    final serverMsg = parsed?.message;

    final kind = switch (status) {
      400 => En1ProvisioningErrorKind.validation,
      401 || 403 => En1ProvisioningErrorKind.unauthorized,
      404 => En1ProvisioningErrorKind.notFound,
      409 => En1ProvisioningErrorKind.conflict,
      422 => En1ProvisioningErrorKind.invalidActivationCode,
      >= 500 => En1ProvisioningErrorKind.serverError,
      _ => En1ProvisioningErrorKind.unknown,
    };

    // Preferencia por código de negocio del servidor si viene.
    final kindFromCode = switch (serverCode) {
      'INVALID_ACTIVATION_CODE' => En1ProvisioningErrorKind.invalidActivationCode,
      'DEVICE_UNAUTHORIZED' => En1ProvisioningErrorKind.unauthorized,
      'DEVICE_ALREADY_REGISTERED' => En1ProvisioningErrorKind.conflict,
      'VALIDATION_ERROR' => En1ProvisioningErrorKind.validation,
      'NOT_FOUND' => En1ProvisioningErrorKind.notFound,
      'INTERNAL_ERROR' => En1ProvisioningErrorKind.serverError,
      _ => null,
    };

    final resolvedKind = kindFromCode ?? kind;
    final userMessage = _userMessageFor(resolvedKind, status, serverMsg);
    final ex = En1ProvisioningException(
      userMessage: userMessage,
      technicalDetail: 'HTTP $status ${uri.path} code=$serverCode body=${_short(body)}',
      kind: resolvedKind,
      statusCode: status,
      serverErrorCode: serverCode,
    );
    _logTechnical(ex);
    return ex;
  }

  String _userMessageFor(En1ProvisioningErrorKind kind, int status, String? serverMsg) {
    return switch (kind) {
      En1ProvisioningErrorKind.invalidActivationCode =>
        'Código de conexión inválido. Verifica el código emitido en EasyNodeOne.',
      En1ProvisioningErrorKind.unauthorized =>
        'Dispositivo no autorizado. Solicita un nuevo código o contacta al administrador.',
      En1ProvisioningErrorKind.conflict =>
        'Este dispositivo ya está registrado. Revisa el estado en el BackOffice EN1.',
      En1ProvisioningErrorKind.validation =>
        'Datos de registro inválidos. Verifica la URL y el código de activación.',
      En1ProvisioningErrorKind.notFound =>
        'Servidor EN1 no disponible o URL incorrecta (recurso no encontrado).',
      En1ProvisioningErrorKind.serverError =>
        'Error interno del servidor EN1. Intenta más tarde.',
      En1ProvisioningErrorKind.serverUnavailable =>
        'Servidor EN1 no disponible. Verifica la URL y que el servicio esté activo.',
      En1ProvisioningErrorKind.offline =>
        'Sin conexión a Internet. Verifica la red e intenta de nuevo.',
      En1ProvisioningErrorKind.timeout =>
        'Tiempo de espera agotado. El servidor EN1 no respondió a tiempo.',
      En1ProvisioningErrorKind.unknown =>
        serverMsg?.trim().isNotEmpty == true
            ? serverMsg!.trim()
            : 'No se pudo conectar con EasyNodeOne (HTTP $status).',
    };
  }

  En1ProvisioningException _mapTransportError(Object e, StackTrace st, Uri uri) {
    final text = e.toString();
    late final En1ProvisioningException ex;

    if (e is SocketException ||
        text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable')) {
      ex = En1ProvisioningException(
        userMessage: 'Sin conexión a Internet. Verifica la red e intenta de nuevo.',
        technicalDetail: 'Socket/DNS $uri → $e',
        kind: En1ProvisioningErrorKind.offline,
      );
    } else if (e is HttpException && text.toLowerCase().contains('connection')) {
      ex = En1ProvisioningException(
        userMessage: 'Servidor EN1 no disponible. Verifica la URL y que el servicio esté activo.',
        technicalDetail: 'HttpException $uri → $e',
        kind: En1ProvisioningErrorKind.serverUnavailable,
      );
    } else if (e is TimeoutException ||
        text.contains('TimeoutException') ||
        text.contains('timed out')) {
      ex = En1ProvisioningException(
        userMessage: 'Tiempo de espera agotado. El servidor EN1 no respondió a tiempo.',
        technicalDetail: 'Timeout $uri → $e\n$st',
        kind: En1ProvisioningErrorKind.timeout,
      );
    } else if (text.contains('Connection refused') || text.contains('Connection reset')) {
      ex = En1ProvisioningException(
        userMessage: 'Servidor EN1 no disponible. Verifica la URL y que el servicio esté activo.',
        technicalDetail: 'Connection $uri → $e',
        kind: En1ProvisioningErrorKind.serverUnavailable,
      );
    } else {
      ex = En1ProvisioningException(
        userMessage: 'No se pudo conectar con EasyNodeOne. Intenta de nuevo.',
        technicalDetail: 'Unknown transport $uri → $e\n$st',
        kind: En1ProvisioningErrorKind.unknown,
      );
    }
    _logTechnical(ex);
    return ex;
  }

  ({String code, String message})? _parseErrorBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final err = decoded['error'];
      if (err is! Map<String, dynamic>) return null;
      final code = err['code']?.toString() ?? '';
      final message = err['message']?.toString() ?? '';
      if (code.isEmpty && message.isEmpty) return null;
      return (code: code, message: message);
    } catch (_) {
      return null;
    }
  }

  ProvisioningConfig _parseConfig(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
    required String deviceUuid,
  }) {
    String req(String a, [String? b]) {
      final v = (json[a] ?? (b != null ? json[b] : null))?.toString().trim() ?? '';
      return v;
    }

    final token = req('access_token', 'token');
    final deviceId = req('device_id', 'dispositivo_id');
    final empresaId = req('empresa_id', 'company_id');
    final sucursalId = req('sucursal_id', 'branch_id');
    final posId = req('pos_id', 'punto_venta_id');
    final cajaId = req('caja_id', 'cash_register_id');

    if (token.isEmpty ||
        deviceId.isEmpty ||
        empresaId.isEmpty ||
        sucursalId.isEmpty ||
        posId.isEmpty ||
        cajaId.isEmpty) {
      final ex = En1ProvisioningException(
        userMessage: 'El servidor EN1 devolvió una configuración incompleta.',
        technicalDetail: 'Missing required IDs/token in response: $json',
        kind: En1ProvisioningErrorKind.validation,
      );
      _logTechnical(ex);
      throw ex;
    }

    return ProvisioningConfig(
      apiBaseUrl: apiBaseUrl,
      accessToken: token,
      deviceUuid: deviceUuid,
      deviceId: deviceId,
      empresaId: empresaId,
      sucursalId: sucursalId,
      posId: posId,
      cajaId: cajaId,
      empresaName: _opt(json, 'empresa_name', 'company_name'),
      sucursalName: _opt(json, 'sucursal_name', 'branch_name'),
      posName: _opt(json, 'pos_name', 'punto_venta_name'),
      cajaName: _opt(json, 'caja_name', 'cash_register_name'),
      provisionedAt: DateTime.now(),
    );
  }

  String? _opt(Map<String, dynamic> json, String a, String b) {
    final v = (json[a] ?? json[b])?.toString().trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  String _normalizeBase(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    if (u.isEmpty) {
      throw En1ProvisioningException(
        userMessage: 'URL de EasyNodeOne vacía.',
        technicalDetail: 'Empty apiBaseUrl',
        kind: En1ProvisioningErrorKind.validation,
      );
    }
    final uri = Uri.tryParse(u);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw En1ProvisioningException(
        userMessage: 'URL de EasyNodeOne inválida.',
        technicalDetail: 'Invalid apiBaseUrl=$url',
        kind: En1ProvisioningErrorKind.validation,
      );
    }
    return u;
  }

  String _short(String text) {
    final t = text.trim();
    if (t.length <= 240) return t.isEmpty ? 'sin detalle' : t;
    return '${t.substring(0, 240)}…';
  }

  void _logTechnical(En1ProvisioningException ex) {
    debugPrint(
      '[EN1 Provisioning] kind=${ex.kind.name} status=${ex.statusCode} '
      'serverCode=${ex.serverErrorCode} detail=${ex.technicalDetail}',
    );
  }

  void close() => _http.close(force: true);
}
