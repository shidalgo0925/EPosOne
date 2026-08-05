import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/features/easyai_ops/easyai_ops.dart';

void main() {
  late OperationsConnector connector;

  setUp(() {
    connector = OperationsConnector(
      occ: OccToolHandlers(
        loadPulse: () async => {
          'shift_open': true,
          'open_tickets': 3,
          'pending_sync': 1,
          'failed_sync': 1,
          'attention_count': 2,
          'link_label': 'EN1 offline',
          'license_label': 'TRIAL · Gracia',
          'bootstrap_error': 'timeout',
          'sync_error': 'order: fail',
          'provisioning_error': null,
        },
        loadAlertas: () async => {
          'count': 2,
          'alerts': [
            {'code': 'sync_pending', 'detail': '1'},
            {'code': 'en1_offline', 'detail': 'EN1 offline'},
          ],
          'attention_count': 2,
        },
      ),
      turnos: TurnosToolHandlers(
        loadCurrentShift: () async => {
          'open': true,
          'register_id': 'reg-1',
        },
      ),
      caja: CajaToolHandlers(
        loadEstado: () async => {
          'open': true,
          'register_id': 'reg-1',
          'opening_amount': 100.0,
          'expected_cash': 250.5,
          'sale_count': 4,
        },
        loadExpectedCash: () async => {
          'open': true,
          'register_id': 'reg-1',
          'expected_cash': 250.5,
        },
      ),
      dispositivos: DispositivosToolHandlers(
        loadEste: () async => {
          'uuid': 'dev-uuid',
          'app_version': '1.0.0+1',
          'mode': 'platform',
        },
        loadSalud: () async => {
          'healthy': false,
          'issue_count': 1,
          'issues': ['en1_offline'],
        },
      ),
      telemetria: TelemetriaToolHandlers(
        loadCola: () async => {
          'pending': 2,
          'failed': 1,
          'by_kind': {'Pedido': 2},
        },
        loadErrores: () async => {
          'count': 1,
          'errors': [
            {'source': 'sync', 'message': 'fail'},
          ],
        },
      ),
      licencias: LicenciasToolHandlers(
        loadSnapshot: () async => {
          'present': true,
          'license_type': 'TRIAL',
          'effective_status': 'GRACE',
        },
        loadVencimiento: () async => {
          'risk': 'medium',
          'at_risk': true,
          'effective_status': 'GRACE',
        },
      ),
      pedidos: PedidosToolHandlers(
        loadAbiertos: () async => {
          'count': 2,
          'tickets': [
            {'id': 't1', 'label': 'Mesa 1'},
          ],
        },
      ),
      ventas: VentasToolHandlers(
        loadResumenHoy: () async => {
          'sale_count': 5,
          'gross_total': 120.0,
          'net_total': 110.0,
        },
      ),
    );
  });

  test('listContexts publishes all ADR contexts', () {
    final ids = connector.listContexts().map((c) => c['id']).toSet();
    expect(ids, containsAll([
      'caja',
      'turnos',
      'pedidos',
      'occ',
      'telemetria',
      'licencias',
      'dispositivos',
      'ventas',
      'reportes',
    ]));
  });

  test('listTools never exposes table-like ids', () {
    final tools = connector.listTools();
    expect(tools, isNotEmpty);
    for (final t in tools) {
      final id = t['id']! as String;
      expect(OpsToolRegistry.looksLikeRawDataAccess(id), isFalse);
    }
  });

  test('fase1 wired tools report wired=true in catalog', () {
    final wiredIds = connector
        .listTools()
        .where((t) => t['wired'] == true)
        .map((t) => t['id']! as String)
        .toSet();
    expect(wiredIds, containsAll([
      'occ.consultar.pulso',
      'occ.analizar.alertas',
      'caja.consultar.estado',
      'caja.analizar.descuadre',
      'dispositivos.consultar.este',
      'dispositivos.analizar.salud',
      'telemetria.consultar.cola',
      'telemetria.analizar.errores',
      'licencias.consultar',
      'licencias.analizar.vencimiento',
      'pedidos.consultar.abiertos',
      'ventas.analizar.resumen_hoy',
      'reportes.consultar.disponibles',
      'turnos.consultar.actual',
    ]));
  });

  test('occ.consultar.pulso returns structured pulse', () async {
    final r = await connector.invoke('occ.consultar.pulso', {});
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['open_tickets'], 3);
    expect(r.data!['context'], 'occ');
    expect(r.data!['verb'], 'consultar');
  });

  test('occ.analizar.alertas wired', () async {
    final r = await connector.invoke('occ.analizar.alertas', {});
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['count'], 2);
  });

  test('turnos.consultar.actual wired', () async {
    final r = await connector.invoke('turnos.consultar.actual', {});
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['open'], true);
  });

  test('caja.analizar.descuadre with counted_amount', () async {
    final r = await connector.invoke(
      'caja.analizar.descuadre',
      {'counted_amount': 240.0},
    );
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['has_descuadre'], true);
    expect(r.data!['difference'], closeTo(-10.5, 0.001));
  });

  test('licencias / telemetria / dispositivos / pedidos / ventas', () async {
    for (final id in [
      'licencias.consultar',
      'licencias.analizar.vencimiento',
      'telemetria.consultar.cola',
      'telemetria.analizar.errores',
      'dispositivos.consultar.este',
      'dispositivos.analizar.salud',
      'pedidos.consultar.abiertos',
      'ventas.analizar.resumen_hoy',
      'reportes.consultar.disponibles',
      'caja.consultar.estado',
    ]) {
      final r = await connector.invoke(id, {});
      expect(r.status, OpsToolStatus.ok, reason: id);
    }
  });

  test('rejects raw table access attempts', () async {
    final r = await connector.invoke('db.query_raw', {'sql': 'select *'});
    expect(r.status, OpsToolStatus.rejected);
    expect(r.code, 'raw_access_forbidden');
  });

  test('rejects unknown tool', () async {
    final r = await connector.invoke('foo.bar', {});
    expect(r.status, OpsToolStatus.rejected);
    expect(r.code, 'tool_not_found');
  });

  test('write verb without auth is rejected', () async {
    final r = await connector.invoke('caja.cerrar', {});
    expect(r.status, OpsToolStatus.rejected);
    expect(r.code, 'authorization_required');
  });

  test('planned stub returns wired=false payload when authorized', () async {
    final r = await connector.invoke(
      'caja.cerrar',
      {},
      session: const OpsInvokeSession(authorized: true),
    );
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['wired'], false);
  });
}
