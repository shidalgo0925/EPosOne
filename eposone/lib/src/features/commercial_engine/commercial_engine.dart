/// Capa de arquitectura Sprint V6 — preparación para contratos comerciales.
///
/// **No** contiene reglas V6 definitivas. Toda lógica comercial futura
/// debe entrar por estas interfaces (Instrucción Oficial Prog2).
library;

export 'domain/commercial_policy_source.dart';
export 'domain/engines.dart';
export 'domain/totals_models.dart';
export 'application/commercial_engine_facade.dart';
export 'infrastructure/legacy_totals_engine.dart';
export 'infrastructure/legacy_payment_engine.dart';
export 'infrastructure/legacy_merchandising_engine.dart';
export 'infrastructure/commercial_engine_factory.dart';
export 'infrastructure/local_policy_source.dart';
export 'presentation/commercial_engine_providers.dart';
