import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/core/ui/user_facing_error.dart';

void main() {
  test('hides stack / socket / http', () {
    expect(
      userFacingError(Exception('SocketException: Failed host lookup')),
      'Ocurrió un problema. Intenta de nuevo.',
    );
    expect(
      userFacingError('HTTP 401 Unauthorized'),
      'Ocurrió un problema. Intenta de nuevo.',
    );
  });

  test('keeps plain spanish', () {
    expect(
      userFacingError('Sin conexión a Internet. Verifica la red.'),
      'Sin conexión a Internet. Verifica la red.',
    );
  });
}
