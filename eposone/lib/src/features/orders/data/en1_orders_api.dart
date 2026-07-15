import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:eposone/src/features/orders/data/order_sync_diag.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Cliente HTTP Order Domain — contrato Hito 3B congelado.
///
/// Fuente: `Doc/EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`
class En1OrdersApi {
  En1OrdersApi({HttpClient? httpClient}) : _http = httpClient ?? HttpClient();

  final HttpClient _http;
  static const _timeout = Duration(seconds: 45);

  Future<({String base, String token})> _creds({
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final provisioned = await ProvisioningStore.loadConfig();
    final base = (apiBaseUrl ??
            config?.en1ApiUrl ??
            provisioned?.apiBaseUrl ??
            '')
        .trim();
    final token = (accessToken ??
            config?.en1ApiToken ??
            provisioned?.accessToken ??
            '')
        .trim();
    if (base.isEmpty || token.isEmpty) {
      throw En1OrdersException(
        code: 'unauthorized',
        message: 'Sin Device Token / URL. Provisiona el dispositivo (Hito 1).',
        statusCode: 401,
      );
    }
    return (base: _normalizeBase(base), token: token);
  }

  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> body, {
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    return _sendJson(
      method: 'POST',
      uri: Uri.parse('${c.base}/api/v1/orders'),
      token: c.token,
      body: body,
      ok: const {201, 200},
    );
  }

  Future<Map<String, dynamic>> listOrders({
    String? status,
    String? tableRef,
    int limit = 50,
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    final q = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (tableRef != null && tableRef.isNotEmpty) 'table_ref': tableRef,
      'limit': '${limit.clamp(1, 200)}',
    };
    return _sendJson(
      method: 'GET',
      uri: Uri.parse('${c.base}/api/v1/orders').replace(queryParameters: q),
      token: c.token,
      ok: const {200},
    );
  }

  Future<Map<String, dynamic>> getOrder(
    String id, {
    bool includeEvents = true,
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    final q = includeEvents ? {'include': 'events'} : <String, String>{};
    return _sendJson(
      method: 'GET',
      uri: Uri.parse('${c.base}/api/v1/orders/$id').replace(queryParameters: q.isEmpty ? null : q),
      token: c.token,
      ok: const {200},
    );
  }

  Future<Map<String, dynamic>> patchOrder(
    String id,
    Map<String, dynamic> body, {
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    return _sendJson(
      method: 'PATCH',
      uri: Uri.parse('${c.base}/api/v1/orders/$id'),
      token: c.token,
      body: body,
      ok: const {200},
    );
  }

  Future<Map<String, dynamic>> postEvent(
    String id,
    Map<String, dynamic> body, {
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    return _sendJson(
      method: 'POST',
      uri: Uri.parse('${c.base}/api/v1/orders/$id/events'),
      token: c.token,
      body: body,
      ok: const {200},
    );
  }

  Future<Map<String, dynamic>> postPayment(
    String id,
    Map<String, dynamic> body, {
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    return _sendJson(
      method: 'POST',
      uri: Uri.parse('${c.base}/api/v1/orders/$id/payments'),
      token: c.token,
      body: body,
      ok: const {201, 200},
    );
  }

  Future<Map<String, dynamic>> splitOrder(
    String id,
    Map<String, dynamic> body, {
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final c = await _creds(apiBaseUrl: apiBaseUrl, accessToken: accessToken, config: config);
    return _sendJson(
      method: 'POST',
      uri: Uri.parse('${c.base}/api/v1/orders/$id/split'),
      token: c.token,
      body: body,
      ok: const {201, 200},
    );
  }

  Future<Map<String, dynamic>> _sendJson({
    required String method,
    required Uri uri,
    required String token,
    Map<String, dynamic>? body,
    required Set<int> ok,
  }) async {
    OrderSyncDiag.section('HTTP $method');
    OrderSyncDiag.log('URL: $uri');
    OrderSyncDiag.log('Headers:');
    OrderSyncDiag.log('  Accept: application/json');
    OrderSyncDiag.log('  Authorization: ${OrderSyncDiag.maskBearer(token)}');
    if (body != null) {
      OrderSyncDiag.log('  Content-Type: application/json; charset=utf-8');
      OrderSyncDiag.jsonBlock('JSON enviado', body);
    } else {
      OrderSyncDiag.log('JSON enviado: <sin body>');
    }

    try {
      final HttpClientRequest req;
      switch (method) {
        case 'GET':
          req = await _http.getUrl(uri).timeout(_timeout);
        case 'POST':
          req = await _http.postUrl(uri).timeout(_timeout);
        case 'PATCH':
          req = await _http.patchUrl(uri).timeout(_timeout);
        default:
          throw StateError('Método HTTP no soportado: $method');
      }
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (body != null) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
        req.add(utf8.encode(jsonEncode(body)));
      }
      final res = await req.close().timeout(_timeout);
      final text = await res.transform(utf8.decoder).join();
      OrderSyncDiag.log('Response Code: ${res.statusCode}');
      OrderSyncDiag.log(
        'Response Body: ${text.isEmpty ? "<vacío>" : (text.length > 4000 ? '${text.substring(0, 4000)}…' : text)}',
      );

      if (!ok.contains(res.statusCode)) {
        throw _httpError(res.statusCode, text, uri);
      }
      if (text.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw En1OrdersException(
        code: 'validation',
        message: 'Respuesta Orders EN1 inválida.',
        statusCode: res.statusCode,
        technicalDetail: uri.path,
      );
    } on En1OrdersException catch (e) {
      OrderSyncDiag.log('ERROR EN1: code=${e.code} status=${e.statusCode} msg=${e.message}');
      if (e.technicalDetail != null) {
        OrderSyncDiag.log('Detalle: ${e.technicalDetail}');
      }
      rethrow;
    } on En1ProvisioningException catch (e) {
      OrderSyncDiag.log('ERROR transport/provisioning: ${e.userMessage}');
      throw En1OrdersException(
        code: 'transport',
        message: e.userMessage,
        statusCode: e.statusCode,
        technicalDetail: e.technicalDetail,
      );
    } catch (e, st) {
      OrderSyncDiag.log('ERROR red/excepción: $e');
      debugPrint('[EN1 Orders] $method $uri → $e\n$st');
      throw En1OrdersException(
        code: 'transport',
        message: 'No se pudo contactar EN1 Orders. Reintentará en cola offline.',
        technicalDetail: e.toString(),
        statusCode: null,
      );
    }
  }

  En1OrdersException _httpError(int status, String text, Uri uri) {
    String code = 'http_$status';
    String message = 'Error EN1 Orders ($status)';
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded['error'] != null) {
        code = decoded['error'].toString();
        message = code;
      }
    } catch (_) {}
    return En1OrdersException(
      code: code,
      message: message,
      statusCode: status,
      technicalDetail: '${uri.path} $text',
    );
  }

  String _normalizeBase(String url) {
    var b = url.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    return b;
  }
}

class En1OrdersException implements Exception {
  En1OrdersException({
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
