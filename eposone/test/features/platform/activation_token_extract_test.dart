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

  test('does NOT classify plain long strings as activation', () {
    expect(
      extractActivationToken('abcdefghijklmnopqrstuvwxyz012345'),
      isNull,
    );
  });

  test('does NOT treat provisioning-looking strings as activation', () {
    expect(extractActivationToken('L2cG-RZg-MK4Kkyd'), isNull);
    expect(extractActivationToken('1yJEY6V8gD2WK32W'), isNull);
  });

  test('isExplicitActivationTransport', () {
    expect(
      isExplicitActivationTransport(
        'https://eposone.easytech.services/activate?token=x',
      ),
      isTrue,
    );
    expect(isExplicitActivationTransport('1yJEY6V8gD2WK32W'), isFalse);
  });
}
