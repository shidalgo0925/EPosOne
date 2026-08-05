import 'discount_enums.dart';
import 'discount_program.dart';

/// One order line for discount resolution (pre-tax base in cents).
class DiscountLineInput {
  const DiscountLineInput({
    required this.lineId,
    required this.unitPriceCents,
    required this.quantity,
    this.eligibleForProgram = true,
    this.markedBeneficiary = false,
  });

  final String lineId;
  final int unitPriceCents;
  final int quantity;

  /// Soft filter (category exclusions etc. — V1 mostly true).
  final bool eligibleForProgram;

  /// For ITEMS scope (e.g. pensioner lines only).
  final bool markedBeneficiary;

  int get lineBaseCents => unitPriceCents * quantity;
}

class DiscountBeneficiaryInput {
  const DiscountBeneficiaryInput({
    this.kind = BeneficiaryKind.none,
    this.customerId,
    this.occasionalName,
    this.documentCheckConfirmed = false,
    this.documentCheckType = DocumentCheckType.none,
    this.documentRefMasked,
  });

  final BeneficiaryKind kind;
  final String? customerId;
  final String? occasionalName;
  final bool documentCheckConfirmed;
  final DocumentCheckType documentCheckType;
  final String? documentRefMasked;
}

class DiscountAuthorizationInput {
  const DiscountAuthorizationInput({
    this.authorized = false,
    this.authorizedByUserId,
    this.reason,
  });

  final bool authorized;
  final String? authorizedByUserId;
  final String? reason;
}

/// Input to [DiscountResolver]. UI must not compute discounts itself.
class DiscountResolveRequest {
  const DiscountResolveRequest({
    required this.lines,
    required this.catalog,
    required this.establishmentType,
    required this.at,
    this.selectedProgramCode,
    this.beneficiary = const DiscountBeneficiaryInput(),
    this.authorization = const DiscountAuthorizationInput(),
    /// For `MANUAL_AUTHORIZED`: percent hundredths (10% → 1000) or amount cents
    /// according to program [DiscountValueType]. Ignored otherwise.
    this.valueOverride,
  });

  final List<DiscountLineInput> lines;
  final List<DiscountProgram> catalog;
  final DiscountEstablishmentClass establishmentType;
  final DateTime at;

  /// Explicit program chosen by cashier from eligible list (not free %).
  final String? selectedProgramCode;

  final DiscountBeneficiaryInput beneficiary;
  final DiscountAuthorizationInput authorization;

  final int? valueOverride;
}
