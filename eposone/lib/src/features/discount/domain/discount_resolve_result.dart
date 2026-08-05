import 'applied_discount.dart';
import 'discount_program.dart';

enum DiscountResolveStatus {
  none,
  applied,
  rejected,
}

/// Result of [DiscountResolver]. Contains no tax fields (D1).
class DiscountResolveResult {
  const DiscountResolveResult({
    required this.status,
    this.eligiblePrograms = const [],
    this.applied,
    this.rejectionCode,
    this.rejectionMessage,
  });

  final DiscountResolveStatus status;

  /// Programs that pass catalog filters (active, effective, establishment).
  final List<DiscountProgram> eligiblePrograms;

  final AppliedDiscount? applied;
  final String? rejectionCode;
  final String? rejectionMessage;

  factory DiscountResolveResult.none({
    List<DiscountProgram> eligiblePrograms = const [],
  }) {
    return DiscountResolveResult(
      status: DiscountResolveStatus.none,
      eligiblePrograms: eligiblePrograms,
    );
  }

  factory DiscountResolveResult.applied({
    required AppliedDiscount applied,
    required List<DiscountProgram> eligiblePrograms,
  }) {
    return DiscountResolveResult(
      status: DiscountResolveStatus.applied,
      applied: applied,
      eligiblePrograms: eligiblePrograms,
    );
  }

  factory DiscountResolveResult.rejected({
    required String code,
    required String message,
    List<DiscountProgram> eligiblePrograms = const [],
  }) {
    return DiscountResolveResult(
      status: DiscountResolveStatus.rejected,
      rejectionCode: code,
      rejectionMessage: message,
      eligiblePrograms: eligiblePrograms,
    );
  }
}
