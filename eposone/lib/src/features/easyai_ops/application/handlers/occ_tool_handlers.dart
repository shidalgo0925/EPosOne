import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// OCC / Dashboard tools — lectura operacional (ADR-016 + ADR-017).
class OccToolHandlers {
  OccToolHandlers({this.loadPulse});

  /// Injected from app (Isar/OCC). Tests inject a fake.
  final Future<Map<String, Object?>> Function()? loadPulse;

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
      'message': 'Pulse loader no inyectado (Fase 0)',
      'shift_open': null,
      'open_tickets': null,
      'pending_sync': null,
      'attention_count': 0,
    };
  }
}
