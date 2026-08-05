import 'discount_resolve_request.dart';
import 'discount_resolve_result.dart';
import 'discount_program.dart';

/// Sole entry point for discount decisions (ADR-015 D4).
///
/// Responsibilities:
/// - list eligible programs
/// - validate restrictions
/// - resolve conflicts (V1: one program per sale)
/// - return a single result (eligible base, discount amount, allocations)
///
/// Does **not** compute taxes.
abstract class DiscountResolver {
  /// Eligible catalog slice for UI pickers.
  List<DiscountProgram> eligiblePrograms(DiscountResolveRequest request);

  /// Full resolve: pick / apply selected program or return none/rejected.
  DiscountResolveResult resolve(DiscountResolveRequest request);
}
