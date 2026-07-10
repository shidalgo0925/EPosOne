import 'package:eposone/src/features/platform/domain/platform_mode.dart';

/// Sync fino de la capa Plataforma.
///
/// - Sin EN1 (modo local): no hace nada.
/// - Con EN1: descargará Empresa → Sucursal → POS (y catálogo) en fases siguientes.
///
/// No modifica pantallas ni lógica del POS Core.
class PlatformSyncStub {
  static Future<PlatformSyncResult> runIfNeeded(PlatformMode mode) async {
    if (mode != PlatformMode.platform) {
      return const PlatformSyncResult(
        ran: false,
        message: 'Modo local: sync de plataforma omitido',
      );
    }

    // Stub: el conector EN1 live se implementa sin tocar el Core.
    return const PlatformSyncResult(
      ran: false,
      message: 'Conector EN1 pendiente — sync fino no ejecutado',
    );
  }
}

class PlatformSyncResult {
  final bool ran;
  final String message;

  const PlatformSyncResult({
    required this.ran,
    required this.message,
  });
}
