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

/// Cliente ADR-035 v1.4 — Device: `POST /api/v1/activation/redeem`
/// (email + activation_code).
class En1ActivationApi {
  En1ActivationApi({HttpClient? http}) : _http = http ?? HttpClient();

  final HttpClient _http;
  static const _timeout = Duration(seconds: 25);

  /// Redeem canónico Standalone (PROD 075dec7+).
  Future<ActivationClaims> redeemWithEmailCode({
    required String email,
    required String activationCode,
    required String deviceUuid,
    String? apiBaseUrl,
    String productCode = 'eposone',
  }) async {
    final code = activationCode.trim().replaceAll(RegExp(r'\s+'), '');
    final body = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'activation_code': code,
      'device_uuid': deviceUuid,
      'product_code': productCode,
    };
    return _postRedeem(body, apiBaseUrl: apiBaseUrl);
  }

  Future<ActivationClaims> _postRedeem(
    Map<String, dynamic> body, {
    String? apiBaseUrl,
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
      req.add(utf8.encode(jsonEncode(body)));
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
            'No pudimos verificar tu activación. Revisa tu conexión e intenta nuevamente.',
        errorCode: 'offline',
      );
    } on TimeoutException {
      throw En1ActivationException(
        userMessage:
            'No pudimos verificar tu activación. Revisa tu conexión e intenta nuevamente.',
        errorCode: 'timeout',
      );
    } catch (e) {
      debugPrint('[EN1 Activation] $e');
      if (e is En1ActivationException) rethrow;
      throw En1ActivationException(
        userMessage: 'No pudimos verificar tu activación. Intenta nuevamente.',
        errorCode: 'unknown',
        technicalDetail: e.toString(),
      );
    }
  }

  En1ActivationException _fromErrorMap(Map<String, dynamic>? map, int status) {
    final code = map?['error']?.toString() ?? 'activation_code_invalid';
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
      'activation_credential_missing' =>
        'Ingresa tu correo y el código de activación de 6 dígitos.',
      'activation_credential_ambiguous' =>
        'Revisa el correo y el código e intenta nuevamente.',
      'activation_code_invalid' || 'activation_token_invalid' =>
        'El código de activación no es válido. Revisa el correo e intenta nuevamente.',
      'activation_code_expired' || 'activation_token_expired' =>
        'Esta activación venció. Solicita un nuevo código desde tu cuenta.',
      'activation_code_used' || 'activation_token_used' =>
        'Esta activación ya fue utilizada. Solicita un nuevo código si reinstalaste.',
      'activation_code_revoked' || 'activation_token_revoked' =>
        'Esta activación ya no es válida. Contacta a soporte.',
      'email_mismatch' =>
        'El correo no coincide con el de la activación. Usa el mismo correo del registro.',
      'license_revoked' || 'license_expired' =>
        'Tu licencia no está vigente. Contacta a Easy Technology Services.',
      'ops_not_ready' =>
        'Esta activación es Connected. Usa la instalación Connected (código de caja).',
      'product_mismatch' => 'Esta activación no corresponde a EPOSOne.',
      'modality_mismatch' =>
        'Esta activación no corresponde a este tipo de instalación.',
      'offline' || 'timeout' =>
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
