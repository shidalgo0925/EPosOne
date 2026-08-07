import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Claims post-`redeem` (ADR-035) persistidos en el dispositivo.
class ActivationClaims {
  const ActivationClaims({
    required this.licenseId,
    required this.organizationId,
    required this.productCode,
    required this.modality,
    required this.implementationStrategy,
    this.registerRef,
    this.licenseExpiresAt,
    this.contractId,
    this.subscriptionId,
    this.tokenId,
    this.redeemedAt,
  });

  final int licenseId;
  final int organizationId;
  final String productCode;
  final String modality;
  final String implementationStrategy;
  final String? registerRef;
  final String? licenseExpiresAt;
  final int? contractId;
  final int? subscriptionId;
  final int? tokenId;
  final DateTime? redeemedAt;

  bool get isStandalone =>
      modality.toLowerCase() == 'standalone' ||
      modality.toLowerCase() == 'local';

  bool get isConnected => modality.toLowerCase() == 'connected';

  factory ActivationClaims.fromRedeemJson(Map<String, dynamic> json) {
    return ActivationClaims(
      licenseId: (json['license_id'] as num?)?.toInt() ?? 0,
      organizationId: (json['organization_id'] as num?)?.toInt() ?? 0,
      productCode: json['product_code']?.toString() ?? 'eposone',
      modality: json['modality']?.toString() ?? 'standalone',
      implementationStrategy:
          json['implementation_strategy']?.toString() ?? 'self_serve',
      registerRef: json['register_ref']?.toString(),
      licenseExpiresAt: json['license_expires_at']?.toString(),
      contractId: (json['contract_id'] as num?)?.toInt(),
      subscriptionId: (json['subscription_id'] as num?)?.toInt(),
      tokenId: (json['token_id'] as num?)?.toInt(),
      redeemedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'license_id': licenseId,
        'organization_id': organizationId,
        'product_code': productCode,
        'modality': modality,
        'implementation_strategy': implementationStrategy,
        'register_ref': registerRef,
        'license_expires_at': licenseExpiresAt,
        'contract_id': contractId,
        'subscription_id': subscriptionId,
        'token_id': tokenId,
        'redeemed_at': redeemedAt?.toIso8601String(),
      };

  factory ActivationClaims.fromJson(Map<String, dynamic> json) =>
      ActivationClaims(
        licenseId: (json['license_id'] as num?)?.toInt() ?? 0,
        organizationId: (json['organization_id'] as num?)?.toInt() ?? 0,
        productCode: json['product_code']?.toString() ?? 'eposone',
        modality: json['modality']?.toString() ?? 'standalone',
        implementationStrategy:
            json['implementation_strategy']?.toString() ?? 'self_serve',
        registerRef: json['register_ref']?.toString(),
        licenseExpiresAt: json['license_expires_at']?.toString(),
        contractId: (json['contract_id'] as num?)?.toInt(),
        subscriptionId: (json['subscription_id'] as num?)?.toInt(),
        tokenId: (json['token_id'] as num?)?.toInt(),
        redeemedAt: json['redeemed_at'] != null
            ? DateTime.tryParse(json['redeemed_at'].toString())
            : null,
      );
}

class ActivationClaimsStore {
  static const _key = 'en1_activation_claims_v1';
  static const _pendingTokenKey = 'en1_activation_pending_token_v1';
  static const _pendingEmailKey = 'en1_activation_pending_email_v1';
  static const _pendingCodeKey = 'en1_activation_pending_code_v1';

  static Future<void> save(ActivationClaims claims) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(claims.toJson()));
    await prefs.remove(_pendingTokenKey);
    await prefs.remove(_pendingEmailKey);
    await prefs.remove(_pendingCodeKey);
  }

  static Future<ActivationClaims?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      return ActivationClaims.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<bool> hasValidStandalone() async {
    final c = await load();
    return c != null && c.isStandalone && c.licenseId > 0;
  }

  /// Credenciales de formulario (email + código) antes de redeem exitoso.
  static Future<void> savePendingEmailCode({
    required String email,
    required String activationCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, email.trim().toLowerCase());
    await prefs.setString(
      _pendingCodeKey,
      activationCode.trim().replaceAll(RegExp(r'\s+'), ''),
    );
  }

  static Future<({String email, String code})?> loadPendingEmailCode() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_pendingEmailKey)?.trim() ?? '';
    final code = prefs.getString(_pendingCodeKey)?.trim() ?? '';
    if (email.isEmpty || code.isEmpty) return null;
    return (email: email, code: code);
  }

  /// Token recibido (App Link / QR) aún no canjeado — legado / puente.
  static Future<void> savePendingToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingTokenKey, token.trim());
  }

  static Future<String?> loadPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_pendingTokenKey)?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  static Future<void> clearPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingTokenKey);
  }
}

/// Extrae token **solo** desde transporte ADR-035 explícito (legado App Link).
///
/// El camino canónico Standalone v1.4 es **email + activation_code** (6 dígitos).
String? extractActivationToken(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;

  final uri = Uri.tryParse(t);
  if (uri == null || !uri.hasScheme) return null;

  final token = uri.queryParameters['token']?.trim();
  if (token == null || token.isEmpty) return null;

  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

  if (scheme == 'eposone' && host == 'activate') return token;

  if ((scheme == 'https' || scheme == 'http') &&
      (path == '/activate' ||
          path.endsWith('/activate') ||
          path.contains('/activate'))) {
    return token;
  }

  return null;
}

bool isExplicitActivationTransport(String raw) =>
    extractActivationToken(raw) != null;
