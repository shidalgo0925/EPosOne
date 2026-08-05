import '../domain/discount_enums.dart';
import '../domain/discount_program.dart';

/// SYSTEM seed programs (ADR-015). Not persisted yet in Fase A.
abstract final class SystemDiscountPrograms {
  static final DateTime _epoch = DateTime.utc(2020, 1, 1);

  static DiscountProgram pensionerRestaurantPa({int version = 1}) {
    return DiscountProgram(
      id: 'sys-legal-pensioner-restaurant-pa',
      code: 'LEGAL_PENSIONER_RESTAURANT_PA',
      name: 'Descuento jubilado / pensionado (restaurante PA)',
      type: DiscountProgramType.legal,
      source: DiscountSource.system,
      valueType: DiscountValueType.percent,
      value: 2500, // 25.00%
      scope: DiscountScope.items,
      status: DiscountStatus.active,
      version: version,
      effectiveFrom: _epoch,
      requiresAuthorization: false,
      requiresCustomer: true,
      requiresDocumentCheck: true,
      establishmentTypes: const [EstablishmentType.restaurant],
      notes: 'Ley Panamá — restaurante. Solo líneas beneficiario.',
    );
  }

  /// Prepared seed — not auto-active.
  static DiscountProgram pensionerFastFoodPa({int version = 1}) {
    return DiscountProgram(
      id: 'sys-legal-pensioner-fast-food-pa',
      code: 'LEGAL_PENSIONER_FAST_FOOD_PA',
      name: 'Descuento jubilado / pensionado (comida rápida PA)',
      type: DiscountProgramType.legal,
      source: DiscountSource.system,
      valueType: DiscountValueType.percent,
      value: 1500, // 15.00%
      scope: DiscountScope.items,
      status: DiscountStatus.inactive,
      version: version,
      effectiveFrom: _epoch,
      requiresAuthorization: false,
      requiresCustomer: true,
      requiresDocumentCheck: true,
      establishmentTypes: const [EstablishmentType.fastFoodFranchise],
      notes: 'Seed; activar según política del establecimiento.',
    );
  }

  static DiscountProgram manualAuthorized({int version = 1}) {
    return DiscountProgram(
      id: 'sys-manual-authorized',
      code: 'MANUAL_AUTHORIZED',
      name: 'Descuento manual autorizado',
      type: DiscountProgramType.commercial,
      source: DiscountSource.system,
      valueType: DiscountValueType.percent,
      value: 0, // value supplied via future override — V1 catalog uses fixed
      scope: DiscountScope.order,
      status: DiscountStatus.active,
      version: version,
      effectiveFrom: _epoch,
      requiresAuthorization: true,
      requiresCustomer: false,
      requiresDocumentCheck: false,
      maxPercent: 10000,
      notes:
          'Reemplazo de % libre. Fase B: valor dinámico autorizado en request.',
    );
  }

  /// Fixture — inactive commercial.
  static DiscountProgram employee10({int version = 1}) {
    return DiscountProgram(
      id: 'fix-employee-10',
      code: 'COMMERCIAL_EMPLOYEE_10',
      name: 'Descuento empleado 10%',
      type: DiscountProgramType.commercial,
      source: DiscountSource.local,
      valueType: DiscountValueType.percent,
      value: 1000,
      scope: DiscountScope.order,
      status: DiscountStatus.inactive,
      version: version,
      effectiveFrom: _epoch,
      requiresAuthorization: true,
    );
  }

  static List<DiscountProgram> defaultCatalog() => [
        pensionerRestaurantPa(),
        pensionerFastFoodPa(),
        manualAuthorized(),
        employee10(),
      ];
}
