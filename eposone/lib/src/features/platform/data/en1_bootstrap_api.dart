import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/domain/en1_bootstrap_models.dart';

/// Cliente HTTP Device Bootstrap — contrato oficial Hito 2.
///
/// Único endpoint de catálogo para Device Token:
/// `GET /api/v1/devices/bootstrap`
class En1BootstrapApi {
  En1BootstrapApi({HttpClient? httpClient}) : _http = httpClient ?? HttpClient();

  final HttpClient _http;
  static const _timeout = Duration(seconds: 45);

  /// Contrato oficial: Device Token + bootstrap (no BackOffice `/api/eposone/*`).
  Future<En1BootstrapPayload> fetchBootstrap({
    required String apiBaseUrl,
    required String accessToken,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final uri = Uri.parse('$base/api/v1/devices/bootstrap');
    final payload = await _getJson(uri, bearerToken: accessToken);
    return _parseBootstrap(payload);
  }

  En1BootstrapPayload _parseBootstrap(Map<String, dynamic> root) {
    // Envelope opcional { data: { ... } }
    final Map<String, dynamic> body;
    final data = root['data'];
    if (data is Map<String, dynamic>) {
      body = data;
    } else {
      body = root;
    }

    Map<String, dynamic>? config;
    final cfg = body['config'] ?? body['device_config'] ?? root['config'];
    if (cfg is Map<String, dynamic>) {
      config = cfg;
    }

    final productMaps = _extractMaps(body, const [
      'products',
      'catalog',
      'items',
    ]);
    // catalog puede ser { products: [...] }
    final catalog = body['catalog'];
    if (catalog is Map<String, dynamic>) {
      productMaps.addAll(_extractMaps(catalog, const ['products', 'items']));
    }

    final products = productMaps
        .map(En1RemoteProduct.fromJson)
        .where((p) => p.productRef.isNotEmpty)
        .toList();

    final stockMaps = _extractMaps(body, const [
      'stock_balances',
      'stock',
      'balances',
      'inventory',
    ]);
    final inventory = body['inventory'];
    if (inventory is Map<String, dynamic>) {
      stockMaps.addAll(_extractMaps(inventory, const [
        'stock_balances',
        'balances',
        'items',
      ]));
    }

    final stockBalances = stockMaps
        .map(En1RemoteStockBalance.fromJson)
        .where((b) => b.productRef.isNotEmpty)
        .toList();

    return En1BootstrapPayload(
      config: config,
      products: products,
      stockBalances: stockBalances,
      raw: root,
    );
  }

  List<Map<String, dynamic>> _extractMaps(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    final out = <Map<String, dynamic>>[];
    for (final k in keys) {
      final v = source[k];
      if (v is List) {
        for (final e in v) {
          if (e is Map<String, dynamic>) {
            out.add(e);
          } else if (e is Map) {
            out.add(Map<String, dynamic>.from(e));
          }
        }
      }
    }
    return out;
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
          userMessage: 'Servidor EN1 devolvió bootstrap vacío.',
          technicalDetail: 'Empty body ${uri.path}',
          kind: En1ProvisioningErrorKind.serverUnavailable,
          statusCode: res.statusCode,
        );
      }
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return {'products': decoded};
      }
      if (decoded is Map<String, dynamic>) return decoded;
      throw En1ProvisioningException(
        userMessage: 'Respuesta de bootstrap EN1 inválida.',
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
        'No autorizado. Reprovisiona el dispositivo (Device Token inválido).',
      En1ProvisioningErrorKind.notFound =>
        'Endpoint bootstrap no encontrado. Verifica la URL de EN1.',
      En1ProvisioningErrorKind.serverError =>
        'Error interno EN1 al descargar bootstrap. Intenta más tarde.',
      _ => 'No se pudo descargar el bootstrap desde EasyNodeOne (HTTP $status).',
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
        userMessage: 'Tiempo de espera agotado descargando bootstrap EN1.',
        technicalDetail: 'Timeout $uri → $e\n$st',
        kind: En1ProvisioningErrorKind.timeout,
      );
    }
    return En1ProvisioningException(
      userMessage: 'No se pudo conectar con EasyNodeOne para el bootstrap.',
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
