import 'dart:convert';

import 'package:eposone/src/features/discount/domain/applied_discount.dart';
import 'package:eposone/src/features/discount/domain/discount_enums.dart';
import 'package:eposone/src/features/discount/domain/discount_program.dart';
import 'package:eposone/src/features/fiscal/domain/establishment_type.dart';

/// Maps fiscal business config → Discount Domain establishment class.
DiscountEstablishmentClass mapFiscalToDiscountEstablishment(
  EstablishmentType fiscal,
) {
  switch (fiscal) {
    case EstablishmentType.restaurant:
    case EstablishmentType.fonda:
    case EstablishmentType.cafeteria:
    case EstablishmentType.bar:
      return DiscountEstablishmentClass.restaurant;
    case EstablishmentType.supermarket:
    case EstablishmentType.pharmacy:
    case EstablishmentType.hardware:
    case EstablishmentType.store:
      return DiscountEstablishmentClass.retail;
    case EstablishmentType.other:
      return DiscountEstablishmentClass.other;
  }
}

abstract final class AppliedDiscountCodec {
  static Map<String, dynamic> toJson(AppliedDiscount a) => {
        'programId': a.programId,
        'programCode': a.programCode,
        'programName': a.programName,
        'programVersion': a.programVersion,
        'programType': a.programType,
        'source': a.source,
        'valueType': a.valueType,
        'value': a.value,
        'scope': a.scope,
        'eligibleBaseCents': a.eligibleBaseCents,
        'discountAmountCents': a.discountAmountCents,
        'appliedAt': a.appliedAt.toIso8601String(),
        'allocations': [
          for (final x in a.allocations)
            {
              'lineId': x.lineId,
              'eligibleBaseCents': x.eligibleBaseCents,
              'discountAmountCents': x.discountAmountCents,
              'quantity': x.quantity,
            },
        ],
        'beneficiaryKind': a.beneficiaryKind,
        'customerId': a.customerId,
        'occasionalName': a.occasionalName,
        'documentCheckConfirmed': a.documentCheckConfirmed,
        'documentCheckType': a.documentCheckType,
        'documentRefMasked': a.documentRefMasked,
        'authorizedByUserId': a.authorizedByUserId,
        'authorizationReason': a.authorizationReason,
      };

  static String encode(AppliedDiscount a) => jsonEncode(toJson(a));

  static AppliedDiscount? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return AppliedDiscount(
      programId: m['programId'] as String,
      programCode: m['programCode'] as String,
      programName: m['programName'] as String,
      programVersion: m['programVersion'] as int,
      programType: m['programType'] as String,
      source: m['source'] as String,
      valueType: m['valueType'] as String,
      value: m['value'] as int,
      scope: m['scope'] as String,
      eligibleBaseCents: m['eligibleBaseCents'] as int,
      discountAmountCents: m['discountAmountCents'] as int,
      appliedAt: DateTime.parse(m['appliedAt'] as String),
      allocations: [
        for (final x in (m['allocations'] as List<dynamic>? ?? const []))
          AppliedDiscountAllocation(
            lineId: (x as Map)['lineId'] as String,
            eligibleBaseCents: x['eligibleBaseCents'] as int,
            discountAmountCents: x['discountAmountCents'] as int,
            quantity: x['quantity'] as int?,
          ),
      ],
      beneficiaryKind: m['beneficiaryKind'] as String?,
      customerId: m['customerId'] as String?,
      occasionalName: m['occasionalName'] as String?,
      documentCheckConfirmed: m['documentCheckConfirmed'] as bool? ?? false,
      documentCheckType: m['documentCheckType'] as String?,
      documentRefMasked: m['documentRefMasked'] as String?,
      authorizedByUserId: m['authorizedByUserId'] as String?,
      authorizationReason: m['authorizationReason'] as String?,
    );
  }
}

abstract final class DiscountProgramMapper {
  static DiscountProgram fromRecordFields({
    required String id,
    required String code,
    required String name,
    required String type,
    required String source,
    required String valueType,
    required int value,
    required String scope,
    required String status,
    required int version,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    required bool requiresAuthorization,
    required bool requiresCustomer,
    required bool requiresDocumentCheck,
    int? maxPercent,
    required String establishmentTypesCsv,
    String? notes,
  }) {
    return DiscountProgram(
      id: id,
      code: code,
      name: name,
      type: DiscountProgramType.values.byName(type),
      source: DiscountSource.values.byName(source),
      valueType: DiscountValueType.values.byName(valueType),
      value: value,
      scope: DiscountScope.values.byName(scope),
      status: DiscountStatus.values.byName(status),
      version: version,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      requiresAuthorization: requiresAuthorization,
      requiresCustomer: requiresCustomer,
      requiresDocumentCheck: requiresDocumentCheck,
      maxPercent: maxPercent,
      establishmentTypes: establishmentTypesCsv.isEmpty
          ? const []
          : establishmentTypesCsv
              .split(',')
              .where((s) => s.isNotEmpty)
              .map(DiscountEstablishmentClass.values.byName)
              .toList(),
      notes: notes,
    );
  }
}
