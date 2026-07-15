enum SyncEntityKind {
  sale,
  customer,
  cashMovement,
  cashRegister,
  catalogPull,
  /// Pedido Hito 3B — HTTP diferido hasta contrato en Doc/
  order,
}

enum SyncDirection {
  push,
  pull,
}

enum SyncOperationStatus {
  pending,
  processing,
  completed,
  failed,
}

String syncEntityKindLabel(SyncEntityKind kind) => switch (kind) {
      SyncEntityKind.sale => 'Venta',
      SyncEntityKind.customer => 'Cliente',
      SyncEntityKind.cashMovement => 'Movimiento caja',
      SyncEntityKind.cashRegister => 'Turno caja',
      SyncEntityKind.catalogPull => 'Catálogo EN1',
      SyncEntityKind.order => 'Pedido EN1',
    };

String syncDirectionLabel(SyncDirection direction) => switch (direction) {
      SyncDirection.push => 'Subir',
      SyncDirection.pull => 'Bajar',
    };

String syncOperationStatusLabel(SyncOperationStatus status) => switch (status) {
      SyncOperationStatus.pending => 'Pendiente',
      SyncOperationStatus.processing => 'Procesando',
      SyncOperationStatus.completed => 'Completado',
      SyncOperationStatus.failed => 'Error',
    };
