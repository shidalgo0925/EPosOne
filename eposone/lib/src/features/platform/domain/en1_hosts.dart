/// Hosts oficiales EPosOne / EN1 (Gate 2 — defaults de producto).
///
/// Comercial (/start) y API Device viven en el **mismo host PRD** del producto
/// EPosOne. No usar appdev salvo pruebas explícitas.
abstract final class En1Hosts {
  /// Host producto EPosOne (PRD).
  static const productBase = 'https://eposone.easytech.services';

  /// Embudo comercial — crear negocio.
  static const commercialStart = '$productBase/start';

  /// Base URL API Device / onboarding (login, register, bootstrap).
  static const apiBase = productBase;
}
