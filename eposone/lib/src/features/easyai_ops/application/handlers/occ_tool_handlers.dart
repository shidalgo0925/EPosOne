import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// OCC / Dashboard tools — lectura operacional (ADR-016 + ADR-017).
class OccToolHandlers {
  OccToolHandlers({this.loadPulse, this.loadAlertas});

  /// Injected from app (OCC). Tests inject a fake.
  final Future<Map<String, Object?>> Function()? loadPulse;
  final Future<Map<String, Object?>> Function()? loadAlertas;

  List<OpsToolDefinition> definitions() => [
        OpsToolDefinition(
          id: 'occ.consultar.pulso',
          context: OpsContext.occ,
          verb: OpsVerb.consultar,
          title: 'Pulso OCC',
          description:
              'Señales operacionales actuales (turno, tickets, sync, licencia). No es un informe.',
          risk: OpsRisk.low,
          wired: loadPulse != null,
          outputSchema: const {
            'shift_open': 'bool',
            'open_tickets': 'int',
            'pending_sync': 'int',
            'attention_count': 'int',
          },
          handler: (input, session) => _pulso(),
        ),
        OpsToolDefinition(
          id: 'dashboard.consultar.pulso',
          context: OpsContext.dashboard,
          verb: OpsVerb.consultar,
          title: 'Pulso dashboard',
          description: 'Alias de occ.consultar.pulso',
          risk: OpsRisk.low,
          wired: loadPulse != null,
          handler: (input, session) => _pulso(),
        ),
        OpsToolDefinition(
          id: 'dashboard.analizar.atencion',
          context: OpsContext.dashboard,
          verb: OpsVerb.analizar,
          title: 'Atención',
          description: 'Conteo de señales que requieren atención',
          risk: OpsRisk.low,
          wired: loadPulse != null,
          handler: (input, session) async {
            final p = await _pulso();
            return {
              'attention_count': p['attention_count'] ?? 0,
              'has_attention': ((p['attention_count'] as int?) ?? 0) > 0,
            };
          },
        ),
        OpsToolDefinition(
          id: 'occ.analizar.alertas',
          context: OpsContext.occ,
          verb: OpsVerb.analizar,
          title: 'Alertas OCC',
          description: 'Lista de señales Fase A (sync, bootstrap, licencia, enlace)',
          risk: OpsRisk.low,
          wired: loadAlertas != null || loadPulse != null,
          handler: (input, session) async {
            if (loadAlertas != null) return loadAlertas!();
            final p = await _pulso();
            final alerts = <Map<String, Object?>>[];
            void add(String code, String? detail) {
              if (detail == null || detail.isEmpty) return;
              alerts.add({'code': code, 'detail': detail});
            }

            final pending = (p['pending_sync'] as int?) ?? 0;
            final failed = (p['failed_sync'] as int?) ?? 0;
            if (pending > 0) {
              alerts.add({'code': 'sync_pending', 'detail': '$pending pendientes'});
            }
            if (failed > 0) {
              alerts.add({'code': 'sync_failed', 'detail': '$failed fallidos'});
            }
            add('bootstrap', p['bootstrap_error'] as String?);
            add('provisioning', p['provisioning_error'] as String?);
            add('sync', p['sync_error'] as String?);
            final link = p['link_label'] as String?;
            if (link != null && link.toLowerCase().contains('offline')) {
              alerts.add({'code': 'en1_offline', 'detail': link});
            }
            final lic = p['license_label'] as String?;
            if (lic != null &&
                (lic.toLowerCase().contains('gracia') ||
                    lic.toLowerCase().contains('expir') ||
                    lic.toLowerCase().contains('suspend'))) {
              alerts.add({'code': 'license', 'detail': lic});
            }
            return {
              'count': alerts.length,
              'alerts': alerts,
              'attention_count': p['attention_count'] ?? alerts.length,
            };
          },
        ),
        OpsToolDefinition(
          id: 'occ.consultar.contexto',
          context: OpsContext.occ,
          verb: OpsVerb.consultar,
          title: 'Navegación OCC',
          description: 'Árbol Hoy/Operación/Cajas/Pagos/Alertas/Auditoría',
          risk: OpsRisk.low,
          wired: true,
          handler: (input, session) async => {
                'nav': [
                  'hoy',
                  'operacion',
                  'cajas',
                  'pagos',
                  'alertas',
                  'auditoria',
                ],
                'principle': 'OCC != reportes',
              },
        ),
      ];

  Future<Map<String, Object?>> _pulso() async {
    if (loadPulse != null) return loadPulse!();
    return {
      'wired': false,
      'message': 'Pulse loader no inyectado',
      'shift_open': null,
      'open_tickets': null,
      'pending_sync': null,
      'failed_sync': null,
      'attention_count': 0,
    };
  }
}
