/// Contextos publicados al Operations Connector (ADR-017).
enum OpsContext {
  caja,
  turnos,
  pedidos,
  clientes,
  inventario,
  productos,
  ventas,
  dispositivos,
  dashboard,
  occ,
  reportes,
  telemetria,
  licencias,
}

extension OpsContextX on OpsContext {
  String get id => name;

  String get label => switch (this) {
        OpsContext.caja => 'Caja',
        OpsContext.turnos => 'Turnos',
        OpsContext.pedidos => 'Pedidos',
        OpsContext.clientes => 'Clientes',
        OpsContext.inventario => 'Inventario',
        OpsContext.productos => 'Productos',
        OpsContext.ventas => 'Ventas',
        OpsContext.dispositivos => 'Dispositivos',
        OpsContext.dashboard => 'Dashboard',
        OpsContext.occ => 'OCC',
        OpsContext.reportes => 'Reportes',
        OpsContext.telemetria => 'Telemetría',
        OpsContext.licencias => 'Licencias',
      };
}
