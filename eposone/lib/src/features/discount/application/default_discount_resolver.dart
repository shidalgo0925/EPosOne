import '../domain/applied_discount.dart';
import '../domain/discount_enums.dart';
import '../domain/discount_program.dart';
import '../domain/discount_resolve_request.dart';
import '../domain/discount_resolve_result.dart';
import '../domain/discount_resolver.dart';
import '../domain/money_cents.dart';

/// Default Discount Domain V1 resolver (pure, no I/O, no taxes).
class DefaultDiscountResolver implements DiscountResolver {
  const DefaultDiscountResolver();

  @override
  List<DiscountProgram> eligiblePrograms(DiscountResolveRequest request) {
    return request.catalog.where((p) {
      if (!p.isActive) return false;
      if (!p.isEffectiveAt(request.at)) return false;
      if (!p.appliesTo(request.establishmentType)) return false;
      return true;
    }).toList(growable: false);
  }

  @override
  DiscountResolveResult resolve(DiscountResolveRequest request) {
    final eligible = eligiblePrograms(request);
    final code = request.selectedProgramCode;
    if (code == null || code.isEmpty) {
      return DiscountResolveResult.none(eligiblePrograms: eligible);
    }

    DiscountProgram? program;
    for (final p in eligible) {
      if (p.code == code) {
        program = p;
        break;
      }
    }
    if (program == null) {
      // Distinguish inactive/ineffective vs unknown.
      final any = request.catalog.where((p) => p.code == code).toList();
      if (any.isEmpty) {
        return DiscountResolveResult.rejected(
          code: 'program_not_found',
          message: 'Programa no encontrado: $code',
          eligiblePrograms: eligible,
        );
      }
      return DiscountResolveResult.rejected(
        code: 'program_not_eligible',
        message: 'Programa no elegible en este momento: $code',
        eligiblePrograms: eligible,
      );
    }

    final authGate = _checkAuthorization(program, request);
    if (authGate != null) return authGate.copyWithEligible(eligible);

    final customerGate = _checkCustomer(program, request);
    if (customerGate != null) return customerGate.copyWithEligible(eligible);

    final docGate = _checkDocument(program, request);
    if (docGate != null) return docGate.copyWithEligible(eligible);

    final lines = _eligibleLines(program, request.lines);
    if (lines.isEmpty) {
      return DiscountResolveResult.rejected(
        code: 'no_eligible_lines',
        message: 'No hay líneas elegibles para el descuento',
        eligiblePrograms: eligible,
      );
    }

    final eligibleBase = lines.fold<int>(0, (a, l) => a + l.lineBaseCents);
    if (eligibleBase <= 0) {
      return DiscountResolveResult.rejected(
        code: 'zero_eligible_base',
        message: 'Base elegible es cero',
        eligiblePrograms: eligible,
      );
    }

    final effectiveValue = _effectiveValue(program, request);
    if (effectiveValue == null) {
      return DiscountResolveResult.rejected(
        code: 'value_required',
        message: 'Se requiere valor autorizado para el programa',
        eligiblePrograms: eligible,
      );
    }

    final discountAmount =
        _computeDiscountAmount(program, eligibleBase, effectiveValue);
    if (discountAmount <= 0) {
      return DiscountResolveResult.rejected(
        code: 'zero_discount',
        message: 'Monto de descuento es cero',
        eligiblePrograms: eligible,
      );
    }
    if (discountAmount > eligibleBase) {
      return DiscountResolveResult.rejected(
        code: 'discount_exceeds_base',
        message: 'Descuento supera la base elegible',
        eligiblePrograms: eligible,
      );
    }

    final allocations = _allocate(lines, discountAmount);
    final sumAlloc =
        allocations.fold<int>(0, (a, x) => a + x.discountAmountCents);
    if (sumAlloc != discountAmount) {
      return DiscountResolveResult.rejected(
        code: 'allocation_invariant',
        message: 'Suma de allocations != discount_amount',
        eligiblePrograms: eligible,
      );
    }

    final b = request.beneficiary;
    final applied = AppliedDiscount(
      programId: program.id,
      programCode: program.code,
      programName: program.name,
      programVersion: program.version,
      programType: program.type.name,
      source: program.source.name,
      valueType: program.valueType.name,
      value: effectiveValue,
      scope: program.scope.name,
      eligibleBaseCents: eligibleBase,
      discountAmountCents: discountAmount,
      appliedAt: request.at,
      allocations: allocations,
      beneficiaryKind: b.kind.name,
      customerId: b.customerId,
      occasionalName: b.occasionalName,
      documentCheckConfirmed: b.documentCheckConfirmed,
      documentCheckType: b.documentCheckType == DocumentCheckType.none
          ? null
          : b.documentCheckType.name,
      documentRefMasked: b.documentRefMasked,
      authorizedByUserId: request.authorization.authorizedByUserId,
      authorizationReason: request.authorization.reason,
    );

    return DiscountResolveResult.applied(
      applied: applied,
      eligiblePrograms: eligible,
    );
  }

  DiscountResolveResult? _checkAuthorization(
    DiscountProgram program,
    DiscountResolveRequest request,
  ) {
    if (!program.requiresAuthorization) return null;
    if (request.authorization.authorized) return null;
    return DiscountResolveResult.rejected(
      code: 'authorization_required',
      message: 'Se requiere autorización para aplicar el programa',
    );
  }

  DiscountResolveResult? _checkCustomer(
    DiscountProgram program,
    DiscountResolveRequest request,
  ) {
    if (!program.requiresCustomer) return null;
    final b = request.beneficiary;
    if (b.kind == BeneficiaryKind.registeredCustomer &&
        (b.customerId != null && b.customerId!.isNotEmpty)) {
      return null;
    }
    if (b.kind == BeneficiaryKind.occasional &&
        (b.occasionalName != null && b.occasionalName!.trim().isNotEmpty)) {
      return null;
    }
    return DiscountResolveResult.rejected(
      code: 'beneficiary_required',
      message: 'Se requiere beneficiario (cliente o ocasional)',
    );
  }

  DiscountResolveResult? _checkDocument(
    DiscountProgram program,
    DiscountResolveRequest request,
  ) {
    if (!program.requiresDocumentCheck) return null;
    if (request.beneficiary.documentCheckConfirmed) return null;
    return DiscountResolveResult.rejected(
      code: 'document_check_required',
      message: 'Se requiere confirmación de documento',
    );
  }

  List<DiscountLineInput> _eligibleLines(
    DiscountProgram program,
    List<DiscountLineInput> lines,
  ) {
    return lines.where((l) {
      if (!l.eligibleForProgram) return false;
      if (program.scope == DiscountScope.items && !l.markedBeneficiary) {
        return false;
      }
      return l.lineBaseCents > 0;
    }).toList(growable: false);
  }

  /// Catalog value, or [DiscountResolveRequest.valueOverride] for manual.
  int? _effectiveValue(
    DiscountProgram program,
    DiscountResolveRequest request,
  ) {
    if (program.code == 'MANUAL_AUTHORIZED') {
      return request.valueOverride;
    }
    return program.value;
  }

  int _computeDiscountAmount(
    DiscountProgram program,
    int eligibleBase,
    int value,
  ) {
    switch (program.valueType) {
      case DiscountValueType.percent:
        var pct = value; // hundredths of a percent (25% = 2500)
        final cap = program.maxPercent;
        if (cap != null && pct > cap) pct = cap;
        if (pct < 0) pct = 0;
        // amount = base * (pct/10000) with round half up to cents
        final raw = eligibleBase * pct;
        return (raw + 5000) ~/ 10000;
      case DiscountValueType.amount:
        final amt = value < 0 ? 0 : value;
        return amt > eligibleBase ? eligibleBase : amt;
    }
  }

  List<AppliedDiscountAllocation> _allocate(
    List<DiscountLineInput> lines,
    int discountAmount,
  ) {
    final weights = lines.map((l) => l.lineBaseCents).toList(growable: false);
    final parts = MoneyCents.allocateByWeight(discountAmount, weights);
    final out = <AppliedDiscountAllocation>[];
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      out.add(
        AppliedDiscountAllocation(
          lineId: l.lineId,
          eligibleBaseCents: l.lineBaseCents,
          discountAmountCents: parts[i],
          quantity: l.quantity,
        ),
      );
    }
    return List.unmodifiable(out);
  }
}

extension on DiscountResolveResult {
  DiscountResolveResult copyWithEligible(List<DiscountProgram> eligible) {
    return DiscountResolveResult(
      status: status,
      eligiblePrograms: eligible,
      applied: applied,
      rejectionCode: rejectionCode,
      rejectionMessage: rejectionMessage,
    );
  }
}
