import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eposone/src/features/platform/domain/onboarding_session.dart';

/// Errores del asistente onboarding (User Bearer).
class En1OnboardingException implements Exception {
  En1OnboardingException({
    required this.userMessage,
    required this.technicalDetail,
    this.statusCode,
    this.errorCode,
  });

  final String userMessage;
  final String technicalDetail;
  final int? statusCode;
  final String? errorCode;

  @override
  String toString() => userMessage;
}

/// Cliente HTTP onboarding — GATE1_HTTP_FROZEN_FOR_LOCAL.md
///
/// Solo User Bearer. No usa Device Bearer ni toca Register/Bootstrap.
class En1OnboardingApi {
  En1OnboardingApi({HttpClient? httpClient}) : _http = httpClient ?? HttpClient();

  final HttpClient _http;
  static const _timeout = Duration(seconds: 25);

  Future<OnboardingLoginResult> login({
    required String apiBaseUrl,
    required String email,
    required String password,
    int? organizationId,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final uri = Uri.parse('$base/api/v1/onboarding/login');
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
    };
    if (organizationId != null) {
      body['organization_id'] = organizationId;
    }
    final payload = await _postJson(uri, body: body);
    final result = OnboardingLoginResult.fromJson(payload);
    if (result.accessToken.isEmpty) {
      throw En1OnboardingException(
        userMessage: 'Respuesta de login incompleta.',
        technicalDetail: 'missing access_token',
      );
    }
    return result;
  }

  Future<OnboardingSession> fetchSession({
    required String apiBaseUrl,
    required String userBearer,
    int? organizationId,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final qp = <String, String>{};
    if (organizationId != null) {
      qp['organization_id'] = '$organizationId';
    }
    final uri = Uri.parse('$base/api/v1/onboarding/session')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final payload = await _getJson(uri, bearerToken: userBearer);
    return OnboardingSession.fromJson(payload);
  }

  Future<OnboardingIssuedCode> issueCode({
    required String apiBaseUrl,
    required String userBearer,
    required int organizationId,
    required String registerRef,
  }) async {
    final base = _normalizeBase(apiBaseUrl);
    final uri = Uri.parse('$base/api/v1/onboarding/issue-code');
    final payload = await _postJson(
      uri,
      body: {
        'organization_id': organizationId,
        'register_ref': registerRef,
      },
      bearerToken: userBearer,
      expectCreated: true,
    );
    final issued = OnboardingIssuedCode.fromJson(payload);
    if (issued.code.isEmpty) {
      throw En1OnboardingException(
        userMessage: 'EN1 no devolvió código de aprovisionamiento.',
        technicalDetail: 'empty code',
      );
    }
    return issued;
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    String? bearerToken,
    bool expectCreated = false,
  }) async {
    try {
      final req = await _http.postUrl(uri).timeout(_timeout);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (bearerToken != null && bearerToken.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
      }
      req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close().timeout(_timeout);
      return _decode(res, uri, expectCreated: expectCreated);
    } on En1OnboardingException {
      rethrow;
    } catch (e) {
      throw En1OnboardingException(
        userMessage: 'No hay conexión con EN1. Revisa la URL e internet.',
        technicalDetail: '$e',
      );
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
      return _decode(res, uri);
    } on En1OnboardingException {
      rethrow;
    } catch (e) {
      throw En1OnboardingException(
        userMessage: 'No hay conexión con EN1. Revisa la URL e internet.',
        technicalDetail: '$e',
      );
    }
  }

  Future<Map<String, dynamic>> _decode(
    HttpClientResponse res,
    Uri uri, {
    bool expectCreated = false,
  }) async {
    final raw = await res.transform(utf8.decoder).join();
    Map<String, dynamic> json = {};
    if (raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      }
    }
    final code = res.statusCode;
    if (code == 200 || (expectCreated && code == 201)) {
      return json;
    }
    final err = json['error']?.toString();
    throw En1OnboardingException(
      userMessage: _userMessage(code, err),
      technicalDetail: 'HTTP $code $uri · $raw',
      statusCode: code,
      errorCode: err,
    );
  }

  String _userMessage(int status, String? error) {
    switch (error) {
      case 'invalid_credentials':
        return 'Correo o contraseña incorrectos.';
      case 'no_organization':
        return 'Tu usuario no tiene organización en EN1.';
      case 'org_forbidden':
        return 'No tienes acceso a esa organización.';
      case 'invalid_organization_id':
        return 'Organización inválida.';
      case 'auth_required':
      case 'invalid_token':
      case 'token_expired':
        return 'Sesión expirada. Vuelve a iniciar sesión.';
      default:
        break;
    }
    if (status == 401) return 'No autorizado. Revisa tus credenciales.';
    if (status == 403) return 'Acceso denegado.';
    if (status == 404) return 'Servicio de onboarding no encontrado en esta URL.';
    if (status >= 500) return 'EN1 no disponible. Intenta más tarde.';
    return 'No se pudo completar la operación ($status).';
  }

  String _normalizeBase(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    return u;
  }
}
