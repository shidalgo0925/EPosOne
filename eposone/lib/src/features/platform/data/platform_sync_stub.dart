import 'package:eposone/src/features/platform/domain/platform_mode.dart';

/// Sync fino de la capa Plataforma.
///
/// Hito 2 Device Bootstrap vive en [En1BootstrapRepository].
/// Este stub solo indica estado; no ejecuta pull automáticamente.
class PlatformSyncStub {
  static Future<PlatformSyncResult> runIfNeeded(PlatformMode mode) async {
    if (mode != PlatformMode.platform) {
      return const PlatformSyncResult(
        ran: false,
        message: 'Modo local: sync de plataforma omitido',
      );
    }

    return const PlatformSyncResult(
      ran: false,
      message:
          'Device Bootstrap Hito 2: ejecutar desde Este dispositivo → Descargar catálogo EN1',
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
