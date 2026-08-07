import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/features/platform/data/activation_claims_store.dart';

void main() {
  group('ActivationClaims.fromRedeemJson', () {
    test('standalone claims from redeem response', () {
      final c = ActivationClaims.fromRedeemJson({
        'ok': true,
        'redeemed': true,
        'modality': 'standalone',
        'implementation_strategy': 'self_serve',
        'organization_id': 123,
        'license_id': 45,
        'product_code': 'eposone',
      });
      expect(c.isStandalone, isTrue);
      expect(c.isConnected, isFalse);
      expect(c.licenseId, 45);
      expect(c.organizationId, 123);
    });

    test('connected modality is not standalone', () {
      final c = ActivationClaims.fromRedeemJson({
        'modality': 'connected',
        'license_id': 1,
        'organization_id': 2,
      });
      expect(c.isStandalone, isFalse);
      expect(c.isConnected, isTrue);
    });
  });

  group('extractActivationToken (legado App Link)', () {
    test('from https activate url', () {
      expect(
        extractActivationToken(
          'https://eposone.easytech.services/activate?token=abcTOKEN1234567890',
        ),
        'abcTOKEN1234567890',
      );
    });

    test('from eposone scheme', () {
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

    test('does NOT treat 6-digit codes as App Link tokens', () {
      expect(extractActivationToken('482731'), isNull);
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
      expect(isExplicitActivationTransport('482731'), isFalse);
      expect(isExplicitActivationTransport('1yJEY6V8gD2WK32W'), isFalse);
    });
  });
}
