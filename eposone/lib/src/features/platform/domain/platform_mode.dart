/// Modo de operación de la capa Plataforma (alrededor del POS Core).
///
/// Una sola APK. El modo solo cambia el origen de datos, no el flujo del cajero.
enum PlatformMode {
  /// Negocio creado y operado solo en el dispositivo.
  local,

  /// Conectado a EasyNodeOne (fuente de verdad en EN1).
  platform,

  /// Aún no eligió en el wizard de bienvenida.
  undecided,
}

extension PlatformModeX on PlatformMode {
  String get storageValue => name;

  static PlatformMode fromStorage(String? value) {
    return PlatformMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => PlatformMode.undecided,
    );
  }
}
