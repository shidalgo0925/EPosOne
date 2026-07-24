import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/core/utils/pin_hash.dart';

void main() {
  test('legacy pin hash roundtrip', () {
    final h = PinVerifier.hashLegacy('1234');
    expect(verifyPin('1234', h), isTrue);
    expect(verifyPin('9999', h), isFalse);
  });

  test('local pbkdf2 pin hash roundtrip', () async {
    final h = hashPin('1234');
    expect(h.startsWith('pbkdf2_sha256\$'), isTrue);
    expect(await PinVerifier.verify('1234', h), isTrue);
    expect(await PinVerifier.verify('9999', h), isFalse);
  });

  test('pbkdf2_sha256 verifier accepts correct pin', () async {
    const pin = '2580';
    const iterations = 100000;
    final salt = utf8.encode('test-salt-16b!');
    final derived = _pbkdf2(utf8.encode(pin), salt, iterations, 32);
    final encoded =
        'pbkdf2_sha256\$$iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';

    expect(await PinVerifier.verify(pin, encoded), isTrue);
    expect(await PinVerifier.verify('0000', encoded), isFalse);
  });

  test('Django textual salt verifier accepts correct pin', () async {
    const pin = '2580';
    const iterations = 100000;
    const salt = 'django-salt';
    final derived = _pbkdf2(
      utf8.encode(pin),
      utf8.encode(salt),
      iterations,
      32,
    );
    final encoded =
        'pbkdf2_sha256\$$iterations\$$salt\$${base64.encode(derived)}';

    expect(await PinVerifier.verify(pin, encoded), isTrue);
  });

  test('Werkzeug verifier accepts correct pin', () async {
    const pin = '2580';
    const iterations = 100000;
    const salt = 'werkzeug-salt';
    final derived = _pbkdf2(
      utf8.encode(pin),
      utf8.encode(salt),
      iterations,
      32,
    );
    final hashHex =
        derived.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final encoded = 'pbkdf2:sha256:$iterations\$$salt\$$hashHex';

    expect(await PinVerifier.verify(pin, encoded), isTrue);
  });

  test('unknown verifier prefix throws', () async {
    await expectLater(
      PinVerifier.verify('1234', 'argon2id\$x\$y\$z'),
      throwsA(isA<UnsupportedPinVerifierException>()),
    );
  });
}

Uint8List _pbkdf2(
    List<int> password, List<int> salt, int iterations, int dkLen) {
  const hLen = 32;
  final l = (dkLen + hLen - 1) ~/ hLen;
  final out = BytesBuilder(copy: false);
  for (var block = 1; block <= l; block++) {
    final blockBytes = [
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ];
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
  return Uint8List.fromList(out.toBytes().sublist(0, dkLen));
}
