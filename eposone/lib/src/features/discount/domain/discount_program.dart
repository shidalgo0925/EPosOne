import 'discount_enums.dart';

/// Catalog program. Immutable snapshot fields used at resolve time.
class DiscountProgram {
  const DiscountProgram({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.source,
    required this.valueType,
    required this.value,
    required this.scope,
    required this.status,
    required this.version,
    required this.effectiveFrom,
    this.effectiveTo,
    this.requiresAuthorization = false,
    this.requiresCustomer = false,
    this.requiresDocumentCheck = false,
    this.maxPercent,
    this.establishmentTypes = const [],
    this.notes,
  });

  final String id;
  final String code;
  final String name;
  final DiscountProgramType type;
  final DiscountSource source;
  final DiscountValueType valueType;

  /// Percent in basis points of a percent point? No — percent as integer
  /// hundredths of a percent? Spec: 25% → store as 25_00 (percent * 100)
  /// so we avoid double. For amount programs, [value] is cents.
  ///
  /// Convention:
  /// - [DiscountValueType.percent]: value = percent * 100 (25% → 2500)
  /// - [DiscountValueType.amount]: value = cents
  final int value;

  final DiscountScope scope;
  final DiscountStatus status;

  /// Monotonic program definition version (D2).
  final int version;

  /// Inclusive start of legal/commercial effectiveness (D3).
  final DateTime effectiveFrom;

  /// Exclusive end; null = open-ended.
  final DateTime? effectiveTo;

  final bool requiresAuthorization;
  final bool requiresCustomer;
  final bool requiresDocumentCheck;

  /// Cap for percent programs (same unit as [value]); null = no extra cap.
  final int? maxPercent;

  /// Empty = all establishment types.
  final List<EstablishmentType> establishmentTypes;

  final String? notes;

  bool get isActive => status == DiscountStatus.active;

  bool isEffectiveAt(DateTime at) {
    if (at.isBefore(effectiveFrom)) return false;
    if (effectiveTo != null && !at.isBefore(effectiveTo!)) return false;
    return true;
  }

  bool appliesTo(EstablishmentType establishment) {
    if (establishmentTypes.isEmpty) return true;
    return establishmentTypes.contains(establishment);
  }

  /// Percent as double for display only (e.g. 25.0).
  double get percentDisplay {
    if (valueType != DiscountValueType.percent) return 0;
    return value / 100.0;
  }
}
