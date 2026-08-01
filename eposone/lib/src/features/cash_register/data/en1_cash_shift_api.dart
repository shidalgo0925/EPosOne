import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:eposone/src/features/platform/data/en1_device_credentials.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Cliente HTTP Cash Shift — contrato v1.0 congelado.
///
/// Fuente: `Doc/EN1_EPOSONE_CASH_SHIFT_HTTP_CONTRACT.md`
class En1CashShiftApi {
  En1CashShiftApi({HttpClient? httpClient}) : _http = httpClient ?? HttpClient();

  final HttpClient _http;
  static const _timeout = Duration(seconds: 45);

  Future<({String base, String token})> _creds({
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await En1DeviceCredentials.resolve(
      apiBaseUrl: apiBaseUrl,
      accessToken: accessToken,
      config: config,
    );
    if (c.base.isEmpty || c.token.isEmpty) {
      throw En1CashShiftException(
        code: 'unauthorized',
        message: 'Sin Device Token / URL. Provisiona el dispositivo (Hito 1).',
        statusCode: 401,
      );
    }
    return c;
  }

  /// `GET /api/v1/cash/shifts/current` → mapa `shift` o null.
  Future<Map<String, dynamic>?> getCurrent({
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    final root = await _sendJson(
      method: 'GET',
      uri: Uri.parse('${c.base}/api/v1/cash/shifts/current'),
      token: c.token,
      ok: const {200},
    );
    final shift = root['shift'];
    if (shift == null) return null;
    if (shift is Map<String, dynamic>) return shift;
    if (shift is Map) return Map<String, dynamic>.from(shift);
    return null;
  }

  /// `POST /api/v1/cash/shifts` — 201 nuevo · 200 idempotente.
  Future<Map<String, dynamic>> openShift(
    Map<String, dynamic> body, {
    String? idempotencyKey,
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    final root = await _sendJson(
      method: 'POST',
      uri: Uri.parse('${c.base}/api/v1/cash/shifts'),
      token: c.token,
      body: body,
      idempotencyKey: idempotencyKey ?? body['client_shift_id']?.toString(),
      ok: const {201, 200},
    );
    return _requireShift(root);
  }

  /// `GET /api/v1/cash/shifts/{id}`
  Future<Map<String, dynamic>> getShift(
    int shiftId, {
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    final root = await _sendJson(
      method: 'GET',
      uri: Uri.parse('${c.base}/api/v1/cash/shifts/$shiftId'),
      token: c.token,
      ok: const {200},
    );
    return _requireShift(root);
  }

  /// `POST /api/v1/cash/shifts/{id}/close` — arqueo + close one-shot.
  Future<Map<String, dynamic>> closeShift(
    int shiftId,
    Map<String, dynamic> body, {
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    final root = await _sendJson(
      method: 'POST',
      uri: Uri.parse('${c.base}/api/v1/cash/shifts/$shiftId/close'),
      token: c.token,
      body: body,
      ok: const {200},
    );
    return _requireShift(root);
  }

  Map<String, dynamic> _requireShift(Map<String, dynamic> root) {
    final shift = root['shift'];
    if (shift is Map<String, dynamic>) return shift;
    if (shift is Map) return Map<String, dynamic>.from(shift);
    throw En1CashShiftException(
      code: 'validation',
      message: 'Respuesta Cash Shift EN1 sin objeto shift.',
      technicalDetail: root.toString(),
    );
  }

  Future<Map<String, dynamic>> _sendJson({
    required String method,
    required Uri uri,
    required String token,
    Map<String, dynamic>? body,
    String? idempotencyKey,
    required Set<int> ok,
  }) async {
    try {
      final HttpClientRequest req;
      switch (method) {
        case 'GET':
          req = await _http.getUrl(uri).timeout(_timeout);
        case 'POST':
          req = await _http.postUrl(uri).timeout(_timeout);
        default:
          throw StateError('Método HTTP no soportado: $method');
      }
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        req.headers.set('Idempotency-Key', idempotencyKey);
      }
      if (body != null) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
        req.add(utf8.encode(jsonEncode(body)));
      }
      final res = await req.close().timeout(_timeout);
      final text = await res.transform(utf8.decoder).join();

      if (!ok.contains(res.statusCode)) {
        throw _httpError(res.statusCode, text, uri);
      }
      if (text.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw En1CashShiftException(
        code: 'validation',
        message: 'Respuesta Cash Shift EN1 inválida.',
        statusCode: res.statusCode,
        technicalDetail: uri.path,
      );
    } on En1CashShiftException {
      rethrow;
    } on En1ProvisioningException catch (e) {
      throw En1CashShiftException(
        code: 'transport',
        message: e.userMessage,
        statusCode: e.statusCode,
        technicalDetail: e.technicalDetail,
      );
    } catch (e, st) {
      debugPrint('[EN1 CashShift] $method $uri → $e\n$st');
      throw En1CashShiftException(
        code: 'transport',
        message: 'No se pudo contactar EN1 Cash Shift. Reintentará en cola offline.',
        technicalDetail: e.toString(),
        statusCode: null,
      );
    }
  }

  En1CashShiftException _httpError(int status, String text, Uri uri) {
    String code = 'http_$status';
    String message = 'Error EN1 Cash Shift ($status)';
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded['error'] != null) {
        code = decoded['error'].toString();
        message = code;
      }
    } catch (_) {}
    return En1CashShiftException(
      code: code,
      message: message,
      statusCode: status,
      technicalDetail: '${uri.path} $text',
    );
  }
}

class En1CashShiftException implements Exception {
  En1CashShiftException({
    required this.code,
    required this.message,
    this.statusCode,
    this.technicalDetail,
  });

  final String code;
  final String message;
  final int? statusCode;
  final String? technicalDetail;

  @override
  String toString() => statusCode != null ? '$message (HTTP $statusCode)' : message;
}
