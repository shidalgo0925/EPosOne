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

  @override
  String toString() => userMessage;

  String get message => userMessage;
}

/// Cliente HTTP de provisioning EN1 — contrato EN1-02.
class En1ProvisioningApi {
  En1ProvisioningApi({HttpClient? httpClient}) : _http = httpClient ?? HttpClient();

  final HttpClient _http;
  static const _timeout = Duration(seconds: 25);
  static const provisioningCodeHeader = 'X-EN1-Provisioning-Code';

  Future<ProvisioningConfig> registerDevice({
    required String apiBaseUrl,
    required DeviceRegistrationRequest request,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final uri = Uri.parse('$base/api/v1/devices/register');
    final payload = await _postJson(
      uri,
      body: request.toJson(),
      provisioningCode: request.provisioningCode,
    );
    return _parseRegisterOrConfig(
      payload,
      apiBaseUrl: base,
      fallbackDeviceUuid: request.deviceUuid,
    );
  }

  Future<ProvisioningConfig> fetchConfig({
    required String apiBaseUrl,
    required String accessToken,
    required String deviceUuid,
    ProvisioningConfig? previous,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final uri = Uri.parse('$base/api/v1/devices/config');
    final payload = await _getJson(uri, bearerToken: accessToken);
    return _parseRegisterOrConfig(
      payload,
      apiBaseUrl: base,
      fallbackDeviceUuid: deviceUuid,
      previousToken: previous?.accessToken ?? accessToken,
      previous: previous,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    required String provisioningCode,
  }) async {
    try {
      final req = await _http.postUrl(uri).timeout(_timeout);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(provisioningCodeHeader, provisioningCode.trim());
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

  /// Acepta HTTP 200 y 201 (alta / reprovision EN1-02).
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

    final kindFromCode = _kindFromServerCode(serverCode);
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

  En1ProvisioningErrorKind? _kindFromServerCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final c = code.toLowerCase();
    if (c.contains('provisioning') && (c.contains('invalid') || c.contains('required') || c.contains('expired'))) {
      return En1ProvisioningErrorKind.invalidActivationCode;
    }
    if (c.contains('activation') || c.contains('code_invalid') || c.contains('invalid_code')) {
      return En1ProvisioningErrorKind.invalidActivationCode;
    }
    return switch (code) {
      'INVALID_ACTIVATION_CODE' => En1ProvisioningErrorKind.invalidActivationCode,
      'DEVICE_UNAUTHORIZED' => En1ProvisioningErrorKind.unauthorized,
      'DEVICE_ALREADY_REGISTERED' => En1ProvisioningErrorKind.conflict,
      'VALIDATION_ERROR' => En1ProvisioningErrorKind.validation,
      'NOT_FOUND' => En1ProvisioningErrorKind.notFound,
      'INTERNAL_ERROR' => En1ProvisioningErrorKind.serverError,
      'device_uuid_required' => En1ProvisioningErrorKind.validation,
      'unauthorized' || 'forbidden' => En1ProvisioningErrorKind.unauthorized,
      _ => null,
    };
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
        'Datos de registro inválidos. Verifica la URL y el código de provisioning.',
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

  /// EN1-02: `{ "error": "code_string" }` · también soporta envelope anidado legacy.
  ({String code, String message})? _parseErrorBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final err = decoded['error'];
      if (err is String) {
        final code = err.trim();
        if (code.isEmpty) return null;
        return (code: code, message: code);
      }
      if (err is Map<String, dynamic>) {
        final code = err['code']?.toString() ?? '';
        final message = err['message']?.toString() ?? '';
        if (code.isEmpty && message.isEmpty) return null;
        return (code: code, message: message);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parsea response de register (token+device+config) o GET config.
  ProvisioningConfig _parseRegisterOrConfig(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
    required String fallbackDeviceUuid,
    String? previousToken,
    ProvisioningConfig? previous,
  }) {
    final token = _str(json['access_token']) ??
        _str(json['token']) ??
        previousToken ??
        previous?.accessToken ??
        '';

    final deviceMap = _asMap(json['device']);
    final configMap = _asMap(json['config']) ??
        (json.containsKey('organization') || json.containsKey('branch') ? json : null);

    final orgMap = _asMap(configMap?['organization']) ?? _asMap(json['organization']);
    final branchMap = _asMap(configMap?['branch']) ?? _asMap(json['branch']);
    final posMap = _asMap(configMap?['pos']) ?? _asMap(json['pos']);
    final registerMap = _asMap(configMap?['register']) ?? _asMap(json['register']);
    final configDevice = _asMap(configMap?['device']);

    final deviceUuid = _str(deviceMap?['uuid']) ??
        _str(configDevice?['uuid']) ??
        _str(json['device_uuid']) ??
        fallbackDeviceUuid;

    final organizationId = _str(orgMap?['id']) ??
        _str(deviceMap?['organization_id']) ??
        _str(json['organization_id']) ??
        previous?.organizationId ??
        '';

    final branchRef = _str(branchMap?['ref']) ??
        _str(deviceMap?['branch_ref']) ??
        previous?.branchRef ??
        '';
    final posRef = _str(posMap?['ref']) ??
        _str(deviceMap?['pos_ref']) ??
        previous?.posRef ??
        '';
    final registerRef = _str(registerMap?['ref']) ??
        _str(deviceMap?['register_ref']) ??
        previous?.registerRef ??
        '';

    if (token.isEmpty ||
        deviceUuid.isEmpty ||
        organizationId.isEmpty ||
        branchRef.isEmpty ||
        posRef.isEmpty ||
        registerRef.isEmpty) {
      final ex = En1ProvisioningException(
        userMessage: 'El servidor EN1 devolvió una configuración incompleta.',
        technicalDetail: 'Missing required fields in EN1-02 response: $json',
        kind: En1ProvisioningErrorKind.validation,
      );
      _logTechnical(ex);
      throw ex;
    }

    final configVersion = (configMap?['config_version'] as num?)?.toInt() ??
        (json['config_version'] as num?)?.toInt() ??
        previous?.configVersion;

    return ProvisioningConfig(
      apiBaseUrl: apiBaseUrl,
      accessToken: token,
      deviceUuid: deviceUuid,
      deviceName: _str(deviceMap?['name']) ??
          _str(configDevice?['name']) ??
          previous?.deviceName,
      deviceStatus: _str(deviceMap?['status']) ??
          _str(configDevice?['status']) ??
          previous?.deviceStatus,
      organizationId: organizationId,
      organizationName: _str(orgMap?['name']) ?? previous?.organizationName,
      branchRef: branchRef,
      branchName: _str(branchMap?['name']) ?? previous?.branchName,
      posRef: posRef,
      posName: _str(posMap?['name']) ?? previous?.posName,
      registerRef: registerRef,
      registerName: _str(registerMap?['name']) ?? previous?.registerName,
      configVersion: configVersion,
      businessName: _str(configMap?['business_name']) ?? previous?.businessName,
      currency: _str(configMap?['currency']) ?? previous?.currency,
      timezone: _str(configMap?['timezone']) ?? previous?.timezone,
      provisionedAt: previous?.provisionedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : null;

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
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
