import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/domain/en1_bootstrap_models.dart';

/// Cliente HTTP Device Bootstrap — contrato Hito 2 v0.1.
class En1BootstrapApi {
  En1BootstrapApi({HttpClient? httpClient}) : _http = httpClient ?? HttpClient();

  final HttpClient _http;
  static const _timeout = Duration(seconds: 45);

  Future<List<En1RemoteProduct>> fetchProducts({
    required String apiBaseUrl,
    required String accessToken,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final uri = Uri.parse('$base/api/eposone/products');
    final payload = await _getJson(uri, bearerToken: accessToken);
    final list = _asList(payload, keys: const ['products', 'items', 'data']);
    return list
        .whereType<Map>()
        .map((e) => En1RemoteProduct.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.productRef.isNotEmpty)
        .toList();
  }

  Future<List<En1RemoteStockBalance>> fetchStockBalances({
    required String apiBaseUrl,
    required String accessToken,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final uri = Uri.parse('$base/api/eposone/stock-balances');
    final payload = await _getJson(uri, bearerToken: accessToken);
    final list = _asList(payload, keys: const ['balances', 'stock', 'items', 'data']);
    return list
        .whereType<Map>()
        .map((e) => En1RemoteStockBalance.fromJson(Map<String, dynamic>.from(e)))
        .where((b) => b.productRef.isNotEmpty)
        .toList();
  }

  /// Descarga imagen a [destPath]. Devuelve true si OK.
  Future<bool> downloadImage({
    required String apiBaseUrl,
    required String imageUrl,
    required String destPath,
  }) async {
    try {
      final uri = _resolveImageUri(apiBaseUrl, imageUrl);
      final req = await _http.getUrl(uri).timeout(_timeout);
      req.headers.set(HttpHeaders.acceptHeader, '*/*');
      final res = await req.close().timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('[EN1 Bootstrap] image HTTP ${res.statusCode} $uri');
        return false;
      }
      final bytes = await consolidateHttpClientResponseBytes(res);
      if (bytes.isEmpty) return false;
      final file = File(destPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return true;
    } catch (e) {
      debugPrint('[EN1 Bootstrap] image download failed: $e');
      return false;
    }
  }

  Uri _resolveImageUri(String apiBaseUrl, String imageUrl) {
    final raw = imageUrl.trim();
    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) return parsed;
    final base = _normalizeBase(apiBaseUrl);
    if (raw.startsWith('/')) return Uri.parse('$base$raw');
    return Uri.parse('$base/$raw');
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, {required String bearerToken}) async {
    try {
      final req = await _http.getUrl(uri).timeout(_timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
      final res = await req.close().timeout(_timeout);
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw _httpError(res.statusCode, text, uri);
      }
      if (text.isEmpty) {
        throw En1ProvisioningException(
          userMessage: 'Servidor EN1 devolvió catálogo vacío.',
          technicalDetail: 'Empty body ${uri.path}',
          kind: En1ProvisioningErrorKind.serverUnavailable,
          statusCode: res.statusCode,
        );
      }
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return {'data': decoded};
      }
      if (decoded is Map<String, dynamic>) return decoded;
      throw En1ProvisioningException(
        userMessage: 'Respuesta de catálogo EN1 inválida.',
        technicalDetail: 'Unexpected JSON ${uri.path}',
        kind: En1ProvisioningErrorKind.validation,
        statusCode: res.statusCode,
      );
    } on En1ProvisioningException {
      rethrow;
    } catch (e, st) {
      throw _mapTransport(e, st, uri);
    }
  }

  List<dynamic> _asList(Map<String, dynamic> payload, {required List<String> keys}) {
    for (final k in keys) {
      final v = payload[k];
      if (v is List) return v;
    }
    // Algunos servidores anidan data.products
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      for (final k in keys) {
        final v = data[k];
        if (v is List) return v;
      }
    }
    if (data is List) return data;
    return const [];
  }

  En1ProvisioningException _httpError(int status, String body, Uri uri) {
    String? code;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        code = decoded['error'] as String;
      } else if (decoded is Map && decoded['error'] is Map) {
        code = (decoded['error'] as Map)['code']?.toString();
      }
    } catch (_) {}

    final kind = switch (status) {
      401 || 403 => En1ProvisioningErrorKind.unauthorized,
      404 => En1ProvisioningErrorKind.notFound,
      >= 500 => En1ProvisioningErrorKind.serverError,
      _ => En1ProvisioningErrorKind.validation,
    };

    final msg = switch (kind) {
      En1ProvisioningErrorKind.unauthorized =>
        'No autorizado para descargar el catálogo. Reprovisiona el dispositivo.',
      En1ProvisioningErrorKind.notFound =>
        'Endpoint de catálogo no encontrado. Verifica la URL de EN1.',
      En1ProvisioningErrorKind.serverError =>
        'Error interno EN1 al descargar catálogo. Intenta más tarde.',
      _ => 'No se pudo descargar el catálogo desde EasyNodeOne (HTTP $status).',
    };

    final ex = En1ProvisioningException(
      userMessage: msg,
      technicalDetail: 'HTTP $status ${uri.path} code=$code body=$body',
      kind: kind,
      statusCode: status,
      serverErrorCode: code,
    );
    debugPrint('[EN1 Bootstrap] ${ex.technicalDetail}');
    return ex;
  }

  En1ProvisioningException _mapTransport(Object e, StackTrace st, Uri uri) {
    final text = e.toString();
    if (e is SocketException || text.contains('Failed host lookup')) {
      return En1ProvisioningException(
        userMessage: 'Sin conexión a Internet. Verifica la red e intenta de nuevo.',
        technicalDetail: 'Socket $uri → $e',
        kind: En1ProvisioningErrorKind.offline,
      );
    }
    if (e is TimeoutException || text.contains('TimeoutException')) {
      return En1ProvisioningException(
        userMessage: 'Tiempo de espera agotado descargando catálogo EN1.',
        technicalDetail: 'Timeout $uri → $e\n$st',
        kind: En1ProvisioningErrorKind.timeout,
      );
    }
    return En1ProvisioningException(
      userMessage: 'No se pudo conectar con EasyNodeOne para el catálogo.',
      technicalDetail: 'Transport $uri → $e\n$st',
      kind: En1ProvisioningErrorKind.unknown,
    );
  }

  String _normalizeBase(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }

  void close() => _http.close(force: true);
}
