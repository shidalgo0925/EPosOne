import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

typedef OpsWriteFn = Future<Map<String, Object?>> Function(
  Map<String, Object?> input,
  OpsInvokeSession session,
);

/// Caja — consultar / analizar / abrir / cerrar (ADR-017).
class CajaToolHandlers {
  CajaToolHandlers({
    this.loadEstado,
    this.loadExpectedCash,
    this.openCaja,
    this.closeCaja,
  });

  final Future<Map<String, Object?>> Function()? loadEstado;
  final Future<Map<String, Object?>> Function()? loadExpectedCash;
  final OpsWriteFn? openCaja;
  final OpsWriteFn? closeCaja;

  List<OpsToolDefinition> definitions() => [
        OpsToolDefinition(
          id: 'caja.consultar.estado',
          context: OpsContext.caja,
          verb: OpsVerb.consultar,
          title: 'Estado de caja',
          description: 'Caja abierta: montos de sesión y cajero actual',
          risk: OpsRisk.low,
          wired: loadEstado != null,
          outputSchema: const {
            'open': 'bool',
            'register_id': 'string?',
            'opening_amount': 'number?',
            'expected_cash': 'number?',
          },
          handler: (input, session) async {
            if (loadEstado != null) return loadEstado!();
            return {
              'wired': false,
              'open': false,
              'message': 'Caja loader no inyectado',
            };
          },
        ),
        OpsToolDefinition(
          id: 'caja.analizar.descuadre',
          context: OpsContext.caja,
          verb: OpsVerb.analizar,
          title: 'Señal de descuadre',
          description:
              'Compara efectivo teórico vs contado (input counted_amount). Sin contado → solo teórico.',
          risk: OpsRisk.medium,
          wired: loadExpectedCash != null,
          inputSchema: const {'counted_amount': 'number?'},
          handler: (input, session) async {
            if (loadExpectedCash == null) {
              return {
                'wired': false,
                'message': 'Expected-cash loader no inyectado',
              };
            }
            final base = await loadExpectedCash!();
            final expected = (base['expected_cash'] as num?)?.toDouble();
            final countedRaw = input['counted_amount'];
            final counted = countedRaw is num ? countedRaw.toDouble() : null;
            if (expected == null) {
              return {
                ...base,
                'has_descuadre': false,
                'needs_counted': true,
                'message': 'Sin caja abierta o sin teórico',
              };
            }
            if (counted == null) {
              return {
                ...base,
                'expected_cash': expected,
                'needs_counted': true,
                'has_descuadre': null,
                'message': 'Proporcione counted_amount para calcular descuadre',
              };
            }
            final diff = counted - expected;
            return {
              ...base,
              'expected_cash': expected,
              'counted_amount': counted,
              'difference': diff,
              'needs_counted': false,
              'has_descuadre': diff.abs() > 0.009,
            };
          },
        ),
        OpsToolDefinition(
          id: 'caja.abrir',
          context: OpsContext.caja,
          verb: OpsVerb.abrir,
          title: 'Abrir caja',
          description: 'Abre turno de caja (requiere auth)',
          risk: OpsRisk.high,
          requiresAuth: true,
          wired: openCaja != null,
          inputSchema: const {'opening_amount': 'number'},
          handler: (input, session) async {
            if (openCaja == null) {
              return {
                'wired': false,
                'tool_id': 'caja.abrir',
                'message': 'Abrir caja no cableado',
              };
            }
            return openCaja!(input, session);
          },
        ),
        OpsToolDefinition(
          id: 'caja.cerrar',
          context: OpsContext.caja,
          verb: OpsVerb.cerrar,
          title: 'Cerrar caja / arqueo',
          description: 'Cierra caja con monto contado (requiere auth)',
          risk: OpsRisk.high,
          requiresAuth: true,
          wired: closeCaja != null,
          inputSchema: const {
            'counted_amount': 'number',
            'notes': 'string?',
          },
          handler: (input, session) async {
            if (closeCaja == null) {
              return {
                'wired': false,
                'tool_id': 'caja.cerrar',
                'message': 'Cerrar caja no cableado',
              };
            }
            return closeCaja!(input, session);
          },
        ),
      ];
}
