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
          'attention_count': 2,
          'link_label': 'EN1 conectado',
        },
      ),
      turnos: TurnosToolHandlers(
        loadCurrentShift: () async => {
          'open': true,
          'register_id': 'reg-1',
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

  test('occ.consultar.pulso returns structured pulse', () async {
    final r = await connector.invoke('occ.consultar.pulso', {});
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['open_tickets'], 3);
    expect(r.data!['context'], 'occ');
    expect(r.data!['verb'], 'consultar');
  });

  test('turnos.consultar.actual wired', () async {
    final r = await connector.invoke('turnos.consultar.actual', {});
    expect(r.status, OpsToolStatus.ok);
    expect(r.data!['open'], true);
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
