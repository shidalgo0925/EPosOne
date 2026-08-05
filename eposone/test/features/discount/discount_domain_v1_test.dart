import 'package:flutter_test/flutter_test.dart';
import 'package:eposone/src/features/discount/discount.dart';

void main() {
  const resolver = DefaultDiscountResolver();
  final at = DateTime.utc(2026, 8, 5, 12);

  DiscountResolveRequest baseRequest({
    required List<DiscountLineInput> lines,
    required List<DiscountProgram> catalog,
    DiscountEstablishmentClass establishment = DiscountEstablishmentClass.restaurant,
    String? selectedProgramCode,
    DiscountBeneficiaryInput beneficiary = const DiscountBeneficiaryInput(),
    DiscountAuthorizationInput authorization =
        const DiscountAuthorizationInput(),
    int? valueOverride,
  }) {
    return DiscountResolveRequest(
      lines: lines,
      catalog: catalog,
      establishmentType: establishment,
      at: at,
      selectedProgramCode: selectedProgramCode,
      beneficiary: beneficiary,
      authorization: authorization,
      valueOverride: valueOverride,
    );
  }

  group('MoneyCents', () {
    test('round-trip decimal strings', () {
      expect(MoneyCents.fromDecimalString('10.50'), 1050);
      expect(MoneyCents.toDecimalString(1050), '10.50');
      expect(MoneyCents.fromDecimalString('0.01'), 1);
    });

    test('allocateByWeight preserves total', () {
      final parts = MoneyCents.allocateByWeight(100, [33, 33, 34]);
      expect(parts.reduce((a, b) => a + b), 100);
    });
  });

  group('DefaultDiscountResolver — pensioner ITEMS', () {
    final program = SystemDiscountPrograms.pensionerRestaurantPa();
    final catalog = [program];

    final beneficiary = DiscountBeneficiaryInput(
      kind: BeneficiaryKind.occasional,
      occasionalName: 'Juan Pérez',
      documentCheckConfirmed: true,
      documentCheckType: DocumentCheckType.cedula,
      documentRefMasked: '***-***-1234',
    );

    test('applies 25% only to beneficiary lines', () {
      final lines = [
        const DiscountLineInput(
          lineId: 'a',
          unitPriceCents: 1000,
          quantity: 2,
          markedBeneficiary: true,
        ),
        const DiscountLineInput(
          lineId: 'b',
          unitPriceCents: 5000,
          quantity: 1,
          markedBeneficiary: false,
        ),
      ];
      final result = resolver.resolve(
        baseRequest(
          lines: lines,
          catalog: catalog,
          selectedProgramCode: program.code,
          beneficiary: beneficiary,
        ),
      );

      expect(result.status, DiscountResolveStatus.applied);
      final applied = result.applied!;
      expect(applied.eligibleBaseCents, 2000);
      expect(applied.discountAmountCents, 500); // 25% of 20.00
      expect(applied.programVersion, 1);
      expect(applied.allocations.length, 1);
      expect(applied.allocations.single.lineId, 'a');
      expect(applied.allocations.single.discountAmountCents, 500);
    });

    test('rejects without document check', () {
      final result = resolver.resolve(
        baseRequest(
          lines: const [
            DiscountLineInput(
              lineId: 'a',
              unitPriceCents: 1000,
              quantity: 1,
              markedBeneficiary: true,
            ),
          ],
          catalog: catalog,
          selectedProgramCode: program.code,
          beneficiary: const DiscountBeneficiaryInput(
            kind: BeneficiaryKind.occasional,
            occasionalName: 'Ana',
          ),
        ),
      );
      expect(result.status, DiscountResolveStatus.rejected);
      expect(result.rejectionCode, 'document_check_required');
    });

    test('rejects when no beneficiary lines', () {
      final result = resolver.resolve(
        baseRequest(
          lines: const [
            DiscountLineInput(
              lineId: 'a',
              unitPriceCents: 1000,
              quantity: 1,
            ),
          ],
          catalog: catalog,
          selectedProgramCode: program.code,
          beneficiary: beneficiary,
        ),
      );
      expect(result.status, DiscountResolveStatus.rejected);
      expect(result.rejectionCode, 'no_eligible_lines');
    });

    test('not eligible for fast_food establishment', () {
      final eligible = resolver.eligiblePrograms(
        baseRequest(
          lines: const [],
          catalog: catalog,
          establishment: DiscountEstablishmentClass.fastFoodFranchise,
        ),
      );
      expect(eligible, isEmpty);
    });
  });

  group('effective dates & version', () {
    test('program outside effective window is not eligible', () {
      final p = DiscountProgram(
        id: 'x',
        code: 'TEMP',
        name: 'Temp',
        type: DiscountProgramType.legal,
        source: DiscountSource.system,
        valueType: DiscountValueType.percent,
        value: 2500,
        scope: DiscountScope.order,
        status: DiscountStatus.active,
        version: 1,
        effectiveFrom: DateTime.utc(2027, 1, 1),
        effectiveTo: DateTime.utc(2028, 1, 1),
      );
      final eligible = resolver.eligiblePrograms(
        baseRequest(lines: const [], catalog: [p]),
      );
      expect(eligible, isEmpty);
    });

    test('AppliedDiscount freezes program_version', () {
      final v2 = SystemDiscountPrograms.pensionerRestaurantPa(version: 2);
      final result = resolver.resolve(
        baseRequest(
          lines: const [
            DiscountLineInput(
              lineId: 'a',
              unitPriceCents: 10000,
              quantity: 1,
              markedBeneficiary: true,
            ),
          ],
          catalog: [v2],
          selectedProgramCode: v2.code,
          beneficiary: const DiscountBeneficiaryInput(
            kind: BeneficiaryKind.occasional,
            occasionalName: 'X',
            documentCheckConfirmed: true,
            documentCheckType: DocumentCheckType.cedula,
          ),
        ),
      );
      expect(result.applied!.programVersion, 2);
      expect(result.applied!.value, 2500);
    });
  });

  group('ORDER scope + MANUAL_AUTHORIZED', () {
    test('requires authorization and valueOverride', () {
      final manual = SystemDiscountPrograms.manualAuthorized();
      final lines = [
        const DiscountLineInput(
          lineId: 'a',
          unitPriceCents: 10000,
          quantity: 1,
        ),
      ];

      final denied = resolver.resolve(
        baseRequest(
          lines: lines,
          catalog: [manual],
          selectedProgramCode: manual.code,
          valueOverride: 1000,
        ),
      );
      expect(denied.rejectionCode, 'authorization_required');

      final ok = resolver.resolve(
        baseRequest(
          lines: lines,
          catalog: [manual],
          selectedProgramCode: manual.code,
          valueOverride: 1000, // 10%
          authorization: const DiscountAuthorizationInput(
            authorized: true,
            authorizedByUserId: 'mgr-1',
            reason: 'Cortesía',
          ),
        ),
      );
      expect(ok.status, DiscountResolveStatus.applied);
      expect(ok.applied!.discountAmountCents, 1000);
      expect(ok.applied!.eligibleBaseCents, 10000);
    });

    test('allocations sum equals discount on multi-line ORDER', () {
      final p = DiscountProgram(
        id: 'c10',
        code: 'COMMERCIAL_10',
        name: '10%',
        type: DiscountProgramType.commercial,
        source: DiscountSource.local,
        valueType: DiscountValueType.percent,
        value: 1000,
        scope: DiscountScope.order,
        status: DiscountStatus.active,
        version: 1,
        effectiveFrom: DateTime.utc(2020),
      );
      final lines = [
        const DiscountLineInput(
          lineId: 'a',
          unitPriceCents: 333,
          quantity: 1,
        ),
        const DiscountLineInput(
          lineId: 'b',
          unitPriceCents: 333,
          quantity: 1,
        ),
        const DiscountLineInput(
          lineId: 'c',
          unitPriceCents: 334,
          quantity: 1,
        ),
      ];
      final result = resolver.resolve(
        baseRequest(
          lines: lines,
          catalog: [p],
          selectedProgramCode: p.code,
        ),
      );
      expect(result.status, DiscountResolveStatus.applied);
      final applied = result.applied!;
      final sum = applied.allocations
          .fold<int>(0, (a, x) => a + x.discountAmountCents);
      expect(sum, applied.discountAmountCents);
      expect(applied.discountAmountCents, 100); // 10% of 10.00
    });
  });

  group('domain does not expose tax', () {
    test('AppliedDiscount has no tax fields', () {
      // Compile-time / structural: only money fields are base + discount.
      final a = AppliedDiscount(
        programId: '1',
        programCode: 'X',
        programName: 'X',
        programVersion: 1,
        programType: 'legal',
        source: 'system',
        valueType: 'percent',
        value: 2500,
        scope: 'items',
        eligibleBaseCents: 100,
        discountAmountCents: 25,
        appliedAt: at,
        allocations: const [],
      );
      expect(a.eligibleBaseCents, 100);
      expect(a.discountAmountCents, 25);
    });
  });

  group('fast food seed', () {
    test('inactive by default', () {
      final ff = SystemDiscountPrograms.pensionerFastFoodPa();
      expect(ff.status, DiscountStatus.inactive);
      expect(ff.value, 1500);
      final eligible = resolver.eligiblePrograms(
        baseRequest(
          lines: const [],
          catalog: [ff],
          establishment: DiscountEstablishmentClass.fastFoodFranchise,
        ),
      );
      expect(eligible, isEmpty);
    });
  });
}
