/// Estados del ciclo de vida de instalación (ADR-014).
///
/// En modo integrado (plataforma EN1), el POS solo opera en [readyToOperate].
enum InstallationLifecycleState {
  notProvisioned,
  deviceRegistered,
  bootstrapPending,
  bootstrapCompleted,
  readyToOperate,
}

extension InstallationLifecycleStateX on InstallationLifecycleState {
  String get storageValue => name;

  String get label => switch (this) {
        InstallationLifecycleState.notProvisioned => 'Sin aprovisionar',
        InstallationLifecycleState.deviceRegistered => 'Dispositivo registrado',
        InstallationLifecycleState.bootstrapPending => 'Bootstrap pendiente',
        InstallationLifecycleState.bootstrapCompleted => 'Bootstrap completado',
        InstallationLifecycleState.readyToOperate => 'Listo para operar',
      };

  static InstallationLifecycleState fromStorage(String? value) {
    return InstallationLifecycleState.values.firstWhere(
      (s) => s.name == value,
      orElse: () => InstallationLifecycleState.notProvisioned,
    );
  }
}
