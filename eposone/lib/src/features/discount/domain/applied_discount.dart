/// Immutable allocation of discount onto a line (and optional qty slice).
class AppliedDiscountAllocation {
  const AppliedDiscountAllocation({
    required this.lineId,
    required this.eligibleBaseCents,
    required this.discountAmountCents,
    this.quantity,
  });

  final String lineId;
  final int eligibleBaseCents;
  final int discountAmountCents;

  /// When set, only this many units of the line were discounted.
  final int? quantity;
}

/// Immutable discount snapshot attached to a sale (never recalculated).
class AppliedDiscount {
  const AppliedDiscount({
    required this.programId,
    required this.programCode,
    required this.programName,
    required this.programVersion,
    required this.programType,
    required this.source,
    required this.valueType,
    required this.value,
    required this.scope,
    required this.eligibleBaseCents,
    required this.discountAmountCents,
    required this.appliedAt,
    required this.allocations,
    this.beneficiaryKind,
    this.customerId,
    this.occasionalName,
    this.documentCheckConfirmed = false,
    this.documentCheckType,
    this.documentRefMasked,
    this.authorizedByUserId,
    this.authorizationReason,
  });

  final String programId;
  final String programCode;
  final String programName;
  final int programVersion;
  final String programType;
  final String source;
  final String valueType;
  final int value;
  final String scope;
  final int eligibleBaseCents;
  final int discountAmountCents;
  final DateTime appliedAt;
  final List<AppliedDiscountAllocation> allocations;

  final String? beneficiaryKind;
  final String? customerId;
  final String? occasionalName;
  final bool documentCheckConfirmed;
  final String? documentCheckType;
  final String? documentRefMasked;
  final String? authorizedByUserId;
  final String? authorizationReason;
}
