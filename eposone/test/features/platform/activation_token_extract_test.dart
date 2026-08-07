import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/features/platform/data/activation_claims_store.dart';

void main() {
  test('extractActivationToken from https activate url', () {
    expect(
      extractActivationToken(
        'https://eposone.easytech.services/activate?token=abcTOKEN1234567890',
      ),
      'abcTOKEN1234567890',
    );
  });

  test('extractActivationToken from eposone scheme', () {
    expect(
      extractActivationToken('eposone://activate?token=ZZZ999888777666555'),
      'ZZZ999888777666555',
    );
  });

  test('looksLikeActivationTransport', () {
    expect(
      looksLikeActivationTransport(
        'https://eposone.easytech.services/activate?token=x',
      ),
      isTrue,
    );
  });
}
