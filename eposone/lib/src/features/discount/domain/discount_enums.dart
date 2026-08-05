/// Discount Domain V1 — enums (ADR-015). No tax knowledge.
library;

enum DiscountProgramType { legal, commercial, promotion }

enum DiscountSource { system, en1, local }

enum DiscountValueType { percent, amount }

enum DiscountScope { order, items }

enum DiscountStatus { active, inactive }

/// Establishment classification — configured outside the sale UI.
enum EstablishmentType {
  restaurant,
  fastFoodFranchise,
  retail,
  services,
  other,
}

enum BeneficiaryKind {
  none,
  registeredCustomer,
  occasional,
}

enum DocumentCheckType {
  none,
  cedula,
  passport,
  other,
}
