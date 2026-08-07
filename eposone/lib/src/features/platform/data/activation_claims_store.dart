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

  static Future<void> save(ActivationClaims claims) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(claims.toJson()));
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
}

/// Extrae token de activación (ADR-035 transporte).
///
/// - `https://…/activate?token=`
/// - `eposone://activate?token=`
/// - token plano (sin `://` y sin parecer solo código corto de caja)
String? extractActivationToken(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final uri = Uri.tryParse(t);
  if (uri != null && uri.queryParameters['token'] != null) {
    final tok = uri.queryParameters['token']!.trim();
    if (tok.isEmpty) return null;
    final path = uri.path.toLowerCase();
    if (uri.host.toLowerCase() == 'activate' ||
        path.contains('activate') ||
        t.toLowerCase().contains('/activate')) {
      return tok;
    }
    // Deep link genérico con ?token=
    if (uri.scheme == 'eposone') return tok;
  }
  if (t.contains('://')) return null;
  // Token plano: más largo / sin patrón típico de código corto con guiones cortos.
  if (t.length >= 20) return t;
  return null;
}

bool looksLikeActivationTransport(String raw) {
  final lower = raw.trim().toLowerCase();
  return lower.contains('/activate') ||
      lower.startsWith('eposone://activate') ||
      extractActivationToken(raw) != null;
}
