import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eposone/src/core/utils/pin_hash.dart';
import 'package:eposone/src/features/platform/domain/en1_bootstrap_models.dart';

/// Catálogo local de cajeros EN1 (Hito 2.5).
///
/// Metadata en SharedPreferences; `pin_verifier` solo en Secure Storage.
class En1CashierLocal {
  final int cashierContactId;
  final String cashierName;
  final String? cashierCode;
  final bool isActive;
  final int pinVersion;
  final DateTime updatedAt;
  final String? pinVerifier;

  const En1CashierLocal({
    required this.cashierContactId,
    required this.cashierName,
    this.cashierCode,
    required this.isActive,
    required this.pinVersion,
    required this.updatedAt,
    this.pinVerifier,
  });

  String get localId => 'en1_cashier_$cashierContactId';

  Map<String, dynamic> toJsonMeta() => {
        'cashier_contact_id': cashierContactId,
        'cashier_name': cashierName,
        'cashier_code': cashierCode,
        'is_active': isActive,
        'pin_version': pinVersion,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory En1CashierLocal.fromJsonMeta(Map<String, dynamic> json,
      {String? pinVerifier}) {
    final idRaw = json['cashier_contact_id'];
    final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;
    final updated = DateTime.tryParse('${json['updated_at']}')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return En1CashierLocal(
      cashierContactId: id,
      cashierName: () {
        final raw = '${json['cashier_name'] ?? ''}'.trim();
        final looksBad = raw.isEmpty ||
            RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(raw) ||
            raw.startsWith('en1_cashier_');
        return looksBad ? 'Cajero $id' : raw;
      }(),
      cashierCode: json['cashier_code']?.toString(),
      isActive: json['is_active'] != false,
      pinVersion: json['pin_version'] is int
          ? json['pin_version'] as int
          : int.tryParse('${json['pin_version']}') ?? 0,
      updatedAt: updated,
      pinVerifier: pinVerifier,
    );
  }
}

class En1CashierCatalogStore {
  En1CashierCatalogStore._();

  static const _prefsListKey = 'en1_cashiers_catalog_v1';
  static const _prefsVersionKey = 'en1_bootstrap_cashiers_version_v1';
  static const _securePrefix = 'en1_pin_verifier_';

  static const _secure = FlutterSecureStorage();

  static Future<int?> getCashiersVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsVersionKey);
  }

  static Future<void> _writeVerifier(int contactId, String? verifier) async {
    final key = '$_securePrefix$contactId';
    final v = verifier?.trim();
    try {
      if (v != null && v.isNotEmpty) {
        await _secure.write(key: key, value: v);
      } else {
        await _secure.delete(key: key);
      }
    } catch (e) {
      debugPrint('[EN1 Cashiers] SecureStorage write falló (usando prefs): $e');
    }
  }

  static Future<String?> _readVerifier(int contactId) async {
    try {
      final v = await _secure.read(key: '$_securePrefix$contactId');
      if (v != null && v.trim().isNotEmpty) return v.trim();
    } catch (e) {
      debugPrint('[EN1 Cashiers] SecureStorage read falló: $e');
    }
    return null;
  }

  static Future<void> saveFromBootstrap({
    required int? cashiersVersion,
    required List<En1RemoteCashier> cashiers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final known = prefs.getInt(_prefsVersionKey);

    // Sin cambios: misma version y lista vacía.
    if (cashiersVersion != null &&
        known != null &&
        known == cashiersVersion &&
        cashiers.isEmpty) {
      return;
    }

    // Lista vacía: no avanzar version ni tocar snapshot (evita catálogo stale).
    if (cashiers.isEmpty) return;

    final byId = <int, En1CashierLocal>{};
    for (final c in cashiers) {
      final verifier = c.pinVerifier?.trim();
      byId[c.cashierContactId] = En1CashierLocal(
        cashierContactId: c.cashierContactId,
        cashierName: c.cashierName,
        cashierCode: c.cashierCode,
        isActive: c.isActive,
        pinVersion: c.pinVersion,
        updatedAt: c.updatedAt,
        pinVerifier: verifier,
      );
      await _writeVerifier(c.cashierContactId, verifier);
    }

    final previous = await listMetaOnly();
    for (final old in previous) {
      if (!byId.containsKey(old.cashierContactId)) {
        byId[old.cashierContactId] = En1CashierLocal(
          cashierContactId: old.cashierContactId,
          cashierName: old.cashierName,
          cashierCode: old.cashierCode,
          isActive: false,
          pinVersion: old.pinVersion,
          updatedAt: DateTime.now().toUtc(),
        );
      }
    }
    final list = byId.values.map((e) => e.toJsonMeta()).toList();
    await prefs.setString(_prefsListKey, jsonEncode(list));
    if (cashiersVersion != null) {
      await prefs.setInt(_prefsVersionKey, cashiersVersion);
    }
  }

  static Future<List<En1CashierLocal>> listMetaOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsListKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final hadLegacyVerifier = decoded.any(
        (e) => e is Map && e.containsKey('pin_verifier'),
      );
      final result = [
        for (final e in decoded)
          if (e is Map<String, dynamic>)
            En1CashierLocal.fromJsonMeta(e)
          else if (e is Map)
            En1CashierLocal.fromJsonMeta(Map<String, dynamic>.from(e)),
      ];
      // Migración del APK previo: eliminar verifier que se guardó en prefs.
      if (hadLegacyVerifier) {
        await prefs.setString(
          _prefsListKey,
          jsonEncode(result.map((e) => e.toJsonMeta()).toList()),
        );
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  static Future<List<En1CashierLocal>> listActiveWithVerifiers() async {
    final all = await listMetaOnly();
    final out = <En1CashierLocal>[];
    for (final c in all.where((e) => e.isActive)) {
      final v = await _readVerifier(c.cashierContactId);
      out.add(En1CashierLocal(
        cashierContactId: c.cashierContactId,
        cashierName: c.cashierName,
        cashierCode: c.cashierCode,
        isActive: c.isActive,
        pinVersion: c.pinVersion,
        updatedAt: c.updatedAt,
        pinVerifier: v,
      ));
    }
    out.sort((a, b) => a.cashierName.compareTo(b.cashierName));
    return out;
  }

  static Future<En1CashierLocal?> getWithVerifier(int contactId) async {
    final all = await listMetaOnly();
    En1CashierLocal? c;
    for (final e in all) {
      if (e.cashierContactId == contactId) {
        c = e;
        break;
      }
    }
    if (c == null) return null;
    final v = await _readVerifier(contactId);
    return En1CashierLocal(
      cashierContactId: c.cashierContactId,
      cashierName: c.cashierName,
      cashierCode: c.cashierCode,
      isActive: c.isActive,
      pinVersion: c.pinVersion,
      updatedAt: c.updatedAt,
      pinVerifier: v,
    );
  }

  static Future<bool> verifyPin({
    required int cashierContactId,
    required String pin,
  }) async {
    final c = await getWithVerifier(cashierContactId);
    if (c == null || !c.isActive) return false;
    final verifier = c.pinVerifier;
    if (verifier == null || verifier.isEmpty) {
      throw const CashierPinNotSetException();
    }
    return PinVerifier.verify(pin, verifier);
  }

  static Future<bool> isContactActive(int cashierContactId) async {
    final all = await listMetaOnly();
    for (final c in all) {
      if (c.cashierContactId == cashierContactId) return c.isActive;
    }
    return false;
  }

  static Future<int?> pinVersionOf(int cashierContactId) async {
    final all = await listMetaOnly();
    for (final c in all) {
      if (c.cashierContactId == cashierContactId) return c.pinVersion;
    }
    return null;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final all = await listMetaOnly();
    for (final c in all) {
      try {
        await _secure.delete(key: '$_securePrefix${c.cashierContactId}');
      } catch (_) {}
    }
    await prefs.remove(_prefsListKey);
    await prefs.remove(_prefsVersionKey);
  }
}

class CashierPinNotSetException implements Exception {
  const CashierPinNotSetException();
  @override
  String toString() =>
      'Este cajero aún no tiene PIN. Asígnalo en EN1 → Cajeros → Editar.';
}
