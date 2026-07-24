import 'package:eposone/src/features/fiscal/domain/business_fiscal_contract.dart';

/// Origen de políticas comerciales (Dual Mode).
///
/// Standalone → local. Integrado → snapshot sync EN1.
/// Un solo modelo de dominio; cambia la fuente.
enum CommercialDataOrigin { local, en1 }

abstract class CommercialPolicySource {
  CommercialDataOrigin get origin;

  /// Placeholder hasta freeze V6: tasa única legacy (fallback).
  double get taxRatePercent;

  bool get taxIncluded;

  String? get taxName;

  /// Contrato fiscal del comercio (ITBMS por categoría).
  BusinessFiscalContract get fiscalContract;
}

/// Resuelve de dónde leer políticas según modo de operación.
abstract class CommercialPolicyResolver {
  CommercialPolicySource resolve();
}
