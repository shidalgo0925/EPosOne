import 'dart:convert';
import 'dart:io';

import 'package:eposone/src/features/platform/domain/provisioning_config.dart';

/// Cliente HTTP de provisioning EN1 — contrato v0.1.
///
/// Endpoints esperados (EN1 Hito EN1-01):
/// - POST `{base}/api/v1/devices/register`
/// - GET  `{base}/api/v1/devices/config` (Authorization: Bearer)
///
/// No implementa sync de catálogo/ventas (Hito 2+).
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
    final req = await _http.postUrl(uri).timeout(_timeout);
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close().timeout(_timeout);
    return _decodeResponse(res, uri);
  }

  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    required String bearerToken,
  }) async {
    final req = await _http.getUrl(uri).timeout(_timeout);
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
    final res = await req.close().timeout(_timeout);
    return _decodeResponse(res, uri);
  }

  Future<Map<String, dynamic>> _decodeResponse(HttpClientResponse res, Uri uri) async {
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw En1ProvisioningException(
        'EN1 ${res.statusCode} en ${uri.path}: ${_shortError(text)}',
        statusCode: res.statusCode,
      );
    }
    if (text.isEmpty) {
      throw En1ProvisioningException('Respuesta vacía de EN1 (${uri.path})');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw En1ProvisioningException('JSON inválido de EN1 (${uri.path})');
    }
    // Soporta envelope { "data": { ... } } o cuerpo plano.
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    return decoded;
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
      throw En1ProvisioningException(
        'Respuesta de EN1 incompleta. Faltan token o IDs de jerarquía '
        '(empresa/sucursal/pos/caja/dispositivo).',
      );
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
      throw En1ProvisioningException('URL de EN1 vacía');
    }
    final uri = Uri.tryParse(u);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw En1ProvisioningException('URL de EN1 inválida: $url');
    }
    return u;
  }

  String _shortError(String text) {
    final t = text.trim();
    if (t.length <= 180) return t.isEmpty ? 'sin detalle' : t;
    return '${t.substring(0, 180)}…';
  }

  void close() => _http.close(force: true);
}

class En1ProvisioningException implements Exception {
  final String message;
  final int? statusCode;

  En1ProvisioningException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
