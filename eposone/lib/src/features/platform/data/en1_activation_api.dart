import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:eposone/src/features/platform/data/activation_claims_store.dart';
import 'package:eposone/src/features/platform/domain/en1_hosts.dart';

class En1ActivationException implements Exception {
  En1ActivationException({
    required this.userMessage,
    required this.errorCode,
    this.statusCode,
    this.technicalDetail,
  });

  final String userMessage;
  final String errorCode;
  final int? statusCode;
  final String? technicalDetail;

  @override
  String toString() => userMessage;
}

/// Cliente ADR-035 — Device: `POST /api/v1/activation/redeem`.
class En1ActivationApi {
  En1ActivationApi({HttpClient? http}) : _http = http ?? HttpClient();

  final HttpClient _http;
  static const _timeout = Duration(seconds: 25);

  Future<ActivationClaims> redeem({
    required String token,
    required String deviceUuid,
    String? apiBaseUrl,
    String productCode = 'eposone',
  }) async {
    final base = _normalizeBase(apiBaseUrl ?? En1Hosts.apiBase);
    final uri = Uri.parse('$base/api/v1/activation/redeem');
    try {
      final req = await _http.postUrl(uri).timeout(_timeout);
      req.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.add(utf8.encode(jsonEncode({
        'token': token,
        'device_uuid': deviceUuid,
        'product_code': productCode,
      })));
      final res = await req.close().timeout(_timeout);
      final raw = await res.transform(utf8.decoder).join();
      Map<String, dynamic>? map;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) map = decoded;
      } catch (_) {}

      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          map != null &&
          map['ok'] != false) {
        return ActivationClaims.fromRedeemJson(map);
      }
      throw _fromErrorMap(map, res.statusCode);
    } on En1ActivationException {
      rethrow;
    } on SocketException {
      throw En1ActivationException(
        userMessage:
            'Sin conexión a Internet. Verifique la red e intente de nuevo.',
        errorCode: 'offline',
      );
    } on TimeoutException {
      throw En1ActivationException(
        userMessage: 'El servidor tardó demasiado. Intente de nuevo.',
        errorCode: 'timeout',
      );
    } catch (e) {
      debugPrint('[EN1 Activation] $e');
      if (e is En1ActivationException) rethrow;
      throw En1ActivationException(
        userMessage: 'No se pudo activar. Intente de nuevo.',
        errorCode: 'unknown',
        technicalDetail: e.toString(),
      );
    }
  }

  En1ActivationException _fromErrorMap(Map<String, dynamic>? map, int status) {
    final code = map?['error']?.toString() ?? 'activation_token_invalid';
    final serverMsg = map?['message']?.toString();
    return En1ActivationException(
      userMessage: _userMessage(code, serverMsg),
      errorCode: code,
      statusCode: status,
      technicalDetail: 'HTTP $status code=$code',
    );
  }

  String _userMessage(String code, String? serverMsg) {
    return switch (code) {
      'activation_token_invalid' =>
        'No pudimos verificar tu activación. Solicita un nuevo enlace de activación.',
      'activation_token_expired' =>
        'Esta activación venció. Solicita un nuevo enlace de activación.',
      'activation_token_used' =>
        'Esta activación ya fue utilizada. Solicita un nuevo enlace de activación.',
      'activation_token_revoked' =>
        'Esta activación ya no es válida. Contacta a soporte.',
      'license_revoked' || 'license_expired' =>
        'Tu licencia no está vigente. Contacta a Easy Technology Services.',
      'ops_not_ready' =>
        'Esta activación es Connected y aún no está lista. Use la instalación Connected.',
      'product_mismatch' =>
        'Esta activación no corresponde a EPOSOne.',
      'modality_mismatch' =>
        'Esta activación no corresponde a este tipo de instalación.',
      'offline' =>
        'No pudimos verificar tu activación. Revisa tu conexión e intenta nuevamente.',
      'timeout' =>
        'No pudimos verificar tu activación. Revisa tu conexión e intenta nuevamente.',
      _ => (serverMsg != null &&
              serverMsg.trim().isNotEmpty &&
              !serverMsg.toLowerCase().contains('http') &&
              !serverMsg.toLowerCase().contains('jwt'))
          ? serverMsg.trim()
          : 'No pudimos verificar tu activación. Intenta nuevamente.',
    };
  }

  String _normalizeBase(String url) {
    var t = url.trim();
    if (t.endsWith('/')) t = t.substring(0, t.length - 1);
    return t.isEmpty ? En1Hosts.apiBase : t;
  }
}
