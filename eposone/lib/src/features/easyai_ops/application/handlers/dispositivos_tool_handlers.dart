import '../../domain/ops_context.dart';
import '../../domain/ops_tool_definition.dart';
import '../../domain/ops_verb.dart';

/// Dispositivos — snapshot 2.6 / salud (sin tablas).
class DispositivosToolHandlers {
  DispositivosToolHandlers({this.loadEste, this.loadSalud});

  final Future<Map<String, Object?>> Function()? loadEste;
  final Future<Map<String, Object?>> Function()? loadSalud;

  List<OpsToolDefinition> definitions() => [
        OpsToolDefinition(
          id: 'dispositivos.consultar.este',
          context: OpsContext.dispositivos,
          verb: OpsVerb.consultar,
          title: 'Este dispositivo',
          description: 'UUID, modo, versión APK, estado EN1 (vista 2.6)',
          risk: OpsRisk.low,
          wired: loadEste != null,
          handler: (input, session) async {
            if (loadEste != null) return loadEste!();
            return {
              'wired': false,
              'message': 'Device loader no inyectado',
            };
          },
        ),
        OpsToolDefinition(
          id: 'dispositivos.analizar.salud',
          context: OpsContext.dispositivos,
          verb: OpsVerb.analizar,
          title: 'Salud del dispositivo',
          description: 'Bootstrap / sync / provisioning / cola — señales de atención',
          risk: OpsRisk.low,
          wired: loadSalud != null,
          handler: (input, session) async {
            if (loadSalud != null) return loadSalud!();
            return {
              'wired': false,
              'message': 'Salud loader no inyectado',
              'healthy': null,
            };
          },
        ),
      ];
}
