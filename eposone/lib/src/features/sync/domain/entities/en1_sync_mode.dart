/// Modo de conexión con EN1 Cloud.
enum En1SyncMode {
  none,
  stub,
  live,
}

String en1SyncModeLabel(En1SyncMode mode) => switch (mode) {
      En1SyncMode.none => 'Desactivado',
      En1SyncMode.stub => 'Stub (desarrollo)',
      En1SyncMode.live => 'EN1 API (producción)',
    };
