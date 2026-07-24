import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Verificación local de PIN según contrato Hito 2.5.
///
/// Formatos PBKDF2 aceptados:
/// - Contrato: `pbkdf2_sha256$<iterations>$<salt_b64>$<hash_b64>`
/// - Django: `pbkdf2_sha256$<iterations>$<salt_text>$<hash_b64>`
/// - Werkzeug: `pbkdf2:sha256:<iterations>$<salt_text>$<hash_hex>`
/// Legacy local: `eposone_v1_*` vía Base64 (onboarding sin EN1).
class PinVerifier {
  PinVerifier._();

  static const minIterations = 100000;
  static const legacyPrefix = 'eposone_v1_';

  /// Hash legacy (cajeros creados antes del PBKDF2 local).
  static String hashLegacy(String pin) =>
      base64Url.encode(utf8.encode('$legacyPrefix$pin'));

  /// Hash local Standalone (mismo formato opaco que EN1).
  static String hashLocalPin(String pin, {int iterations = minIterations}) {
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final derived = _pbkdf2HmacSha256(
      utf8.encode(pin),
      salt,
      iterations,
      32,
    );
    return 'pbkdf2_sha256\$$iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  static bool isLegacyHash(String encoded) {
    try {
      final decoded = utf8.decode(base64Url.decode(encoded));
      return decoded.startsWith(legacyPrefix);
    } catch (_) {
      return false;
    }
  }

  static bool verifyLegacy(String pin, String pinHash) =>
      hashLegacy(pin) == pinHash;

  /// Verifica PIN contra verificador opaco EN1 o hash local legacy.
  static Future<bool> verify(String pin, String encoded) async {
    final t = encoded.trim();
    if (t.isEmpty || pin.isEmpty) return false;

    if (isLegacyHash(t)) {
      return verifyLegacy(pin, t);
    }
    if (!_isSupportedPbkdf2(t)) {
      throw UnsupportedPinVerifierException(t.split('\$').first);
    }

    // PBKDF2 es costoso; no bloquear animaciones / teclado del POS.
    return Isolate.run(() => _verifyPbkdf2Sync(pin, t));
  }

  static bool _isSupportedPbkdf2(String encoded) =>
      encoded.startsWith('pbkdf2_sha256\$') ||
      encoded.startsWith('pbkdf2-sha256\$') ||
      encoded.startsWith(r'$pbkdf2-sha256$') ||
      encoded.startsWith(r'$pbkdf2_sha256$') ||
      encoded.startsWith('pbkdf2:sha256:');

  static bool _verifyPbkdf2Sync(String pin, String encoded) {
    var normalized = encoded;
    if (normalized.startsWith(r'$pbkdf2-sha256$') ||
        normalized.startsWith(r'$pbkdf2_sha256$')) {
      normalized = normalized.substring(1);
    }

    final parts = normalized.split('\$');
    if (parts.length != 4 && parts.length != 3) {
      throw const UnsupportedPinVerifierException('pbkdf2(malformed)');
    }

    final isWerkzeug = normalized.startsWith('pbkdf2:sha256:');
    final iterations = isWerkzeug
        ? int.tryParse(parts[0].split(':').last) ?? 0
        : int.tryParse(parts[1]) ?? 0;
    if (iterations < minIterations) {
      throw UnsupportedPinVerifierException('pbkdf2(iters=$iterations)');
    }

    final saltText = isWerkzeug ? parts[1] : parts[2];
    final hashText = isWerkzeug ? parts[2] : parts[3];
    final expected = isWerkzeug ? _hex(hashText) : _b64(hashText);
    if (expected.isEmpty) return false;

    // EN1 contract uses salt_b64; Django/Werkzeug use textual salt.
    final saltCandidates = <Uint8List>[
      if (!isWerkzeug) _b64(saltText),
      Uint8List.fromList(utf8.encode(saltText)),
    ].where((e) => e.isNotEmpty).toList();

    for (final salt in saltCandidates) {
      final derived = _pbkdf2HmacSha256(
        utf8.encode(pin),
        salt,
        iterations,
        expected.length,
      );
      if (_constantTimeEquals(derived, expected)) return true;
    }
    return false;
  }

  static Uint8List _b64(String s) {
    try {
      var t = s.trim();
      // Normalizar URL-safe → standard
      t = t.replaceAll('-', '+').replaceAll('_', '/');
      while (t.length % 4 != 0) {
        t += '=';
      }
      return Uint8List.fromList(base64.decode(t));
    } catch (_) {
      try {
        return Uint8List.fromList(base64Url.decode(s.trim()));
      } catch (_) {
        return Uint8List(0);
      }
    }
  }

  static Uint8List _hex(String s) {
    final t = s.trim();
    if (t.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(t)) {
      return Uint8List(0);
    }
    return Uint8List.fromList([
      for (var i = 0; i < t.length; i += 2)
        int.parse(t.substring(i, i + 2), radix: 16),
    ]);
  }

  /// PBKDF2-HMAC-SHA256 (RFC 8018).
  static Uint8List _pbkdf2HmacSha256(
    List<int> password,
    List<int> salt,
    int iterations,
    int dkLen,
  ) {
    const hLen = 32;
    final l = (dkLen + hLen - 1) ~/ hLen;
    final out = BytesBuilder(copy: false);
    for (var block = 1; block <= l; block++) {
      final blockBytes = _int32be(block);
      var u = Hmac(sha256, password).convert([...salt, ...blockBytes]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = Hmac(sha256, password).convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.add(t);
    }
    final dk = out.toBytes();
    return Uint8List.fromList(dk.sublist(0, dkLen));
  }

  static List<int> _int32be(int n) => [
        (n >> 24) & 0xff,
        (n >> 16) & 0xff,
        (n >> 8) & 0xff,
        n & 0xff,
      ];

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

class UnsupportedPinVerifierException implements Exception {
  final String prefix;
  const UnsupportedPinVerifierException(this.prefix);

  @override
  String toString() => 'Verificador PIN no soportado: $prefix';
}

/// Standalone / onboarding: PBKDF2 (cajeros legacy siguen verificando).
String hashPin(String pin) => PinVerifier.hashLocalPin(pin);

/// Solo hashes legacy síncronos. Preferir [PinVerifier.verify].
bool verifyPin(String pin, String pinHash) =>
    PinVerifier.verifyLegacy(pin, pinHash);
