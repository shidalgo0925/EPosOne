/// Proveedor PAC / habilitador de facturación electrónica (Panamá DGI).
enum PacProviderType {
  none,
  stub,
}

String pacProviderTypeLabel(PacProviderType type) => switch (type) {
      PacProviderType.none => 'Desactivado',
      PacProviderType.stub => 'Stub (desarrollo)',
    };
