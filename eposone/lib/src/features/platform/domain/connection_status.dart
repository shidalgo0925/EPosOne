/// Estado de conexión con EasyNodeOne (capa Plataforma — Hito 1).
enum ConnectionStatus {
  /// Aún no eligió / no hay token ni IDs.
  notConfigured,

  /// Llamada en curso a EN1.
  registering,

  /// Token + jerarquía guardados localmente.
  connected,

  /// Último intento falló (se conserva el mensaje de error).
  error,
}

extension ConnectionStatusX on ConnectionStatus {
  String get label => switch (this) {
        ConnectionStatus.notConfigured => 'No configurado',
        ConnectionStatus.registering => 'Registrando',
        ConnectionStatus.connected => 'Conectado',
        ConnectionStatus.error => 'Error',
      };

  String get storageValue => name;

  static ConnectionStatus fromStorage(String? value) {
    return ConnectionStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ConnectionStatus.notConfigured,
    );
  }
}
