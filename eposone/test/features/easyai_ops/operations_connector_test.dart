import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/caja_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/dispositivos_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/licencias_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/occ_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/pedidos_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/reportes_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/telemetria_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/turnos_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/ventas_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/ops_tool_registry.dart';
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
        loadHistorial: (input) async => {
          'count': 1,
          'items': [
            {'register_id': 'reg-1', 'open': false},
          ],
        },
        openTurno: (input, session) async => {
          'wired': true,
          'open': true,
          'register_id': 'reg-new',
          'opening_amount': input['opening_amount'],
          'actor_id': session.actorId,
        },
        closeTurno: (input, session) async => {
          'wired': true,
          'closed': true,
          'counted_amount': input['counted_amount'],
          'actor_id': session.actorId,
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
        openCaja: (input, session) async => {
          'wired': true,
          'open': true,
          'register_id': 'reg-new',
          'opening_amount': input['opening_amount'],
          'actor_id': session.actorId,
        },
        closeCaja: (input, session) async => {
          'wired': true,
          'closed': true,
          'counted_amount': input['counted_amount'],
          'expected_cash': 250.5,
          'difference': (input['counted_amount'] as num) - 250.5,
          'actor_id': session.actorId,
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
        loadPorId: (input) async => {
          'found': true,
          'ticket': {'id': input['ticket_id'], 'status': 'open'},
        },
        cancelar: (input, session) async => {
          'wired': true,
          'cancelled': true,
          'ticket_id': input['ticket_id'],
          'actor_id': session.actorId,
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

  const authSession = OpsInvokeSession(
    actorId: 'cashier-1',
    actorName: 'Ana',
    role: 'admin',
    authorized: true,
    authMethod: 'pin',
  );

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

  test('describeTool returns catalog entry for wired tool', () {
    final d = connector.describeTool('occ.consultar.pulso');
    expect(d, isNotNull);
    expect(d!['id'], 'occ.consultar.pulso');
    expect(d['wired'], isTrue);
    expect(connector.describeTool('db.raw'), isNull);
  });

  test('fase2 write tools report wired=true in catalog', () {
    final wiredIds = connector
        .listTools()
        .where((t) => t['wired'] == true)
        .map((t) => t['id']! as String)
        .toSet();
    expect(wiredIds, containsAll([
      'caja.abrir',
      'caja.cerrar',
      'turnos.abrir',
      'turnos.cerrar',
      'turnos.consultar.historial',
      'pedidos.cancelar',
      'pedidos.consultar.por_id',
    ]));
  });

  test('occ.consultar.pulso returns structured pulse', () async {
    final r = await connector.invoke('occ.consultar.pulso', {});
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['open_tickets'], 3);
  });

  test('caja.abrir requires auth', () async {
    final r = await connector.invoke('caja.abrir', {'opening_amount': 50});
    expect(r.status, OpsToolStatus.rejected);
    expect(r.code, 'authorization_required');
  });

  test('caja.abrir requires actor when authorized', () async {
    final r = await connector.invoke(
      'caja.abrir',
      {'opening_amount': 50},
      session: const OpsInvokeSession(authorized: true),
    );
    expect(r.status, OpsToolStatus.rejected);
    expect(r.code, 'actor_required');
  });

  test('caja.abrir succeeds with authorized session', () async {
    final r = await connector.invoke(
      'caja.abrir',
      {'opening_amount': 100.0},
      session: authSession,
    );
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['wired'], true);
    expect(r.data!['opening_amount'], 100.0);
    expect(r.data!['actor_id'], 'cashier-1');
  });

  test('caja.cerrar and turnos aliases with auth', () async {
    final close = await connector.invoke(
      'caja.cerrar',
      {'counted_amount': 240.0},
      session: authSession,
    );
    expect(close.status, OpsToolStatus.ok);
    expect(close.data!['closed'], true);

    final turno = await connector.invoke(
      'turnos.abrir',
      {'opening_amount': 20.0},
      session: authSession,
    );
    expect(turno.status, OpsToolStatus.ok);
    expect(turno.data!['open'], true);
  });

  test('pedidos.cancelar with auth', () async {
    final r = await connector.invoke(
      'pedidos.cancelar',
      {'ticket_id': 't1', 'reason': 'cliente se fue'},
      session: authSession,
    );
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['cancelled'], true);
    expect(r.data!['ticket_id'], 't1');
  });

  test('rejects raw table access attempts', () async {
    final r = await connector.invoke('db.query_raw', {'sql': 'select *'});
    expect(r.status, OpsToolStatus.rejected);
    expect(r.code, 'raw_access_forbidden');
  });

  test('planned stub returns wired=false when authorized with actor', () async {
    final r = await connector.invoke(
      'pedidos.crear',
      {},
      session: authSession,
    );
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['wired'], false);
  });

  test('OpsAuth fromPosSession requires login', () {
    final auth = OpsAuth();
    final fail = auth.fromPosSession(null);
    expect(fail.ok, isFalse);
    expect(fail.code, 'session_required');
  });
}
