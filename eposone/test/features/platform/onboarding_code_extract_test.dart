import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/features/platform/domain/onboarding_session.dart';

void main() {
  test('extractProvisioningCodeFromScan plain code', () {
    expect(extractProvisioningCodeFromScan('L2cG-RZg-MK4Kkyd'), 'L2cG-RZg-MK4Kkyd');
  });

  test('extractProvisioningCodeFromScan deep link', () {
    expect(
      extractProvisioningCodeFromScan('eposone://provision?code=ABC-123'),
      'ABC-123',
    );
  });

  test('extractProvisioningCodeFromScan https install', () {
    expect(
      extractProvisioningCodeFromScan(
        'https://eposone.easytech.services/eposone/install?code=XYZ-9',
      ),
      'XYZ-9',
    );
  });

  test('extractProvisioningCodeFromScan rejects unrelated url', () {
    expect(
      extractProvisioningCodeFromScan('https://example.com/foo'),
      isNull,
    );
  });
}
