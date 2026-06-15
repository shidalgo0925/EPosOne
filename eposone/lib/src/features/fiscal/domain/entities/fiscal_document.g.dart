// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fiscal_document.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFiscalDocumentCollection on Isar {
  IsarCollection<FiscalDocument> get fiscalDocuments => this.collection();
}

const FiscalDocumentSchema = CollectionSchema(
  name: r'FiscalDocument',
  id: 7555462413217186802,
  properties: {
    r'authorizationNumber': PropertySchema(
      id: 0,
      name: r'authorizationNumber',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'cufe': PropertySchema(
      id: 2,
      name: r'cufe',
      type: IsarType.string,
    ),
    r'customerDocument': PropertySchema(
      id: 3,
      name: r'customerDocument',
      type: IsarType.string,
    ),
    r'customerName': PropertySchema(
      id: 4,
      name: r'customerName',
      type: IsarType.string,
    ),
    r'deletedAt': PropertySchema(
      id: 5,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'documentType': PropertySchema(
      id: 6,
      name: r'documentType',
      type: IsarType.byte,
      enumMap: _FiscalDocumentdocumentTypeEnumValueMap,
    ),
    r'errorMessage': PropertySchema(
      id: 7,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'fiscalNumber': PropertySchema(
      id: 8,
      name: r'fiscalNumber',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 9,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isPendingSync': PropertySchema(
      id: 10,
      name: r'isPendingSync',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 11,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'issuedAt': PropertySchema(
      id: 12,
      name: r'issuedAt',
      type: IsarType.dateTime,
    ),
    r'localId': PropertySchema(
      id: 13,
      name: r'localId',
      type: IsarType.string,
    ),
    r'relatedDocumentId': PropertySchema(
      id: 14,
      name: r'relatedDocumentId',
      type: IsarType.string,
    ),
    r'saleId': PropertySchema(
      id: 15,
      name: r'saleId',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 16,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 17,
      name: r'status',
      type: IsarType.byte,
      enumMap: _FiscalDocumentstatusEnumValueMap,
    ),
    r'subtotal': PropertySchema(
      id: 18,
      name: r'subtotal',
      type: IsarType.double,
    ),
    r'syncStatus': PropertySchema(
      id: 19,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _FiscalDocumentsyncStatusEnumValueMap,
    ),
    r'taxAmount': PropertySchema(
      id: 20,
      name: r'taxAmount',
      type: IsarType.double,
    ),
    r'total': PropertySchema(
      id: 21,
      name: r'total',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 22,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _fiscalDocumentEstimateSize,
  serialize: _fiscalDocumentSerialize,
  deserialize: _fiscalDocumentDeserialize,
  deserializeProp: _fiscalDocumentDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _fiscalDocumentGetId,
  getLinks: _fiscalDocumentGetLinks,
  attach: _fiscalDocumentAttach,
  version: '3.1.0+1',
);

int _fiscalDocumentEstimateSize(
  FiscalDocument object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.authorizationNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cufe;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customerDocument;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customerName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.errorMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.fiscalNumber.length * 3;
  bytesCount += 3 + object.localId.length * 3;
  {
    final value = object.relatedDocumentId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.saleId.length * 3;
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _fiscalDocumentSerialize(
  FiscalDocument object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.authorizationNumber);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.cufe);
  writer.writeString(offsets[3], object.customerDocument);
  writer.writeString(offsets[4], object.customerName);
  writer.writeDateTime(offsets[5], object.deletedAt);
  writer.writeByte(offsets[6], object.documentType.index);
  writer.writeString(offsets[7], object.errorMessage);
  writer.writeString(offsets[8], object.fiscalNumber);
  writer.writeBool(offsets[9], object.isDeleted);
  writer.writeBool(offsets[10], object.isPendingSync);
  writer.writeBool(offsets[11], object.isSynced);
  writer.writeDateTime(offsets[12], object.issuedAt);
  writer.writeString(offsets[13], object.localId);
  writer.writeString(offsets[14], object.relatedDocumentId);
  writer.writeString(offsets[15], object.saleId);
  writer.writeString(offsets[16], object.serverId);
  writer.writeByte(offsets[17], object.status.index);
  writer.writeDouble(offsets[18], object.subtotal);
  writer.writeByte(offsets[19], object.syncStatus.index);
  writer.writeDouble(offsets[20], object.taxAmount);
  writer.writeDouble(offsets[21], object.total);
  writer.writeDateTime(offsets[22], object.updatedAt);
}

FiscalDocument _fiscalDocumentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FiscalDocument(
    authorizationNumber: reader.readStringOrNull(offsets[0]),
    createdAt: reader.readDateTime(offsets[1]),
    cufe: reader.readStringOrNull(offsets[2]),
    customerDocument: reader.readStringOrNull(offsets[3]),
    customerName: reader.readStringOrNull(offsets[4]),
    deletedAt: reader.readDateTimeOrNull(offsets[5]),
    documentType: _FiscalDocumentdocumentTypeValueEnumMap[
            reader.readByteOrNull(offsets[6])] ??
        FiscalDocumentType.invoice,
    errorMessage: reader.readStringOrNull(offsets[7]),
    fiscalNumber: reader.readString(offsets[8]),
    issuedAt: reader.readDateTime(offsets[12]),
    localId: reader.readString(offsets[13]),
    relatedDocumentId: reader.readStringOrNull(offsets[14]),
    saleId: reader.readString(offsets[15]),
    serverId: reader.readStringOrNull(offsets[16]),
    status:
        _FiscalDocumentstatusValueEnumMap[reader.readByteOrNull(offsets[17])] ??
            FiscalDocumentStatus.pending,
    subtotal: reader.readDouble(offsets[18]),
    syncStatus: _FiscalDocumentsyncStatusValueEnumMap[
            reader.readByteOrNull(offsets[19])] ??
        SyncStatus.pending,
    taxAmount: reader.readDouble(offsets[20]),
    total: reader.readDouble(offsets[21]),
    updatedAt: reader.readDateTime(offsets[22]),
  );
  return object;
}

P _fiscalDocumentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (_FiscalDocumentdocumentTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          FiscalDocumentType.invoice) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (_FiscalDocumentstatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          FiscalDocumentStatus.pending) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (_FiscalDocumentsyncStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncStatus.pending) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readDouble(offset)) as P;
    case 22:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _FiscalDocumentdocumentTypeEnumValueMap = {
  'invoice': 0,
  'creditNote': 1,
};
const _FiscalDocumentdocumentTypeValueEnumMap = {
  0: FiscalDocumentType.invoice,
  1: FiscalDocumentType.creditNote,
};
const _FiscalDocumentstatusEnumValueMap = {
  'pending': 0,
  'submitted': 1,
  'accepted': 2,
  'rejected': 3,
  'error': 4,
};
const _FiscalDocumentstatusValueEnumMap = {
  0: FiscalDocumentStatus.pending,
  1: FiscalDocumentStatus.submitted,
  2: FiscalDocumentStatus.accepted,
  3: FiscalDocumentStatus.rejected,
  4: FiscalDocumentStatus.error,
};
const _FiscalDocumentsyncStatusEnumValueMap = {
  'pending': 0,
  'synced': 1,
  'modified': 2,
  'error': 3,
};
const _FiscalDocumentsyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.synced,
  2: SyncStatus.modified,
  3: SyncStatus.error,
};

Id _fiscalDocumentGetId(FiscalDocument object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _fiscalDocumentGetLinks(FiscalDocument object) {
  return [];
}

void _fiscalDocumentAttach(
    IsarCollection<dynamic> col, Id id, FiscalDocument object) {}

extension FiscalDocumentQueryWhereSort
    on QueryBuilder<FiscalDocument, FiscalDocument, QWhere> {
  QueryBuilder<FiscalDocument, FiscalDocument, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FiscalDocumentQueryWhere
    on QueryBuilder<FiscalDocument, FiscalDocument, QWhereClause> {
  QueryBuilder<FiscalDocument, FiscalDocument, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FiscalDocumentQueryFilter
    on QueryBuilder<FiscalDocument, FiscalDocument, QFilterCondition> {
  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'authorizationNumber',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'authorizationNumber',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authorizationNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'authorizationNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'authorizationNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'authorizationNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'authorizationNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'authorizationNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'authorizationNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'authorizationNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authorizationNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      authorizationNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'authorizationNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cufe',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cufe',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cufe',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cufe',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cufe',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cufe',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cufe',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cufe',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cufe',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cufe',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cufe',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      cufeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cufe',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customerDocument',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customerDocument',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerDocument',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customerDocument',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customerDocument',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customerDocument',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customerDocument',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customerDocument',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customerDocument',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customerDocument',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerDocument',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerDocumentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customerDocument',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customerName',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customerName',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerName',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      customerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customerName',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      documentTypeEqualTo(FiscalDocumentType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentType',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      documentTypeGreaterThan(
    FiscalDocumentType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'documentType',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      documentTypeLessThan(
    FiscalDocumentType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'documentType',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      documentTypeBetween(
    FiscalDocumentType lower,
    FiscalDocumentType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'documentType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorMessage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'errorMessage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fiscalNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fiscalNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fiscalNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fiscalNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fiscalNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fiscalNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fiscalNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fiscalNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fiscalNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      fiscalNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fiscalNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      isPendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPendingSync',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      issuedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'issuedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      issuedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'issuedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      issuedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'issuedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      issuedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'issuedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      localIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'relatedDocumentId',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'relatedDocumentId',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relatedDocumentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relatedDocumentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relatedDocumentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relatedDocumentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'relatedDocumentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'relatedDocumentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'relatedDocumentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'relatedDocumentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relatedDocumentId',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      relatedDocumentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relatedDocumentId',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'saleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'saleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'saleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'saleId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'saleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'saleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'saleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'saleId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'saleId',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      saleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'saleId',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      statusEqualTo(FiscalDocumentStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      statusGreaterThan(
    FiscalDocumentStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      statusLessThan(
    FiscalDocumentStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      statusBetween(
    FiscalDocumentStatus lower,
    FiscalDocumentStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      subtotalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      subtotalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      subtotalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      subtotalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subtotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      taxAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      taxAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      taxAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      taxAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taxAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      totalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'total',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      totalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'total',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      totalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'total',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      totalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'total',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FiscalDocumentQueryObject
    on QueryBuilder<FiscalDocument, FiscalDocument, QFilterCondition> {}

extension FiscalDocumentQueryLinks
    on QueryBuilder<FiscalDocument, FiscalDocument, QFilterCondition> {}

extension FiscalDocumentQuerySortBy
    on QueryBuilder<FiscalDocument, FiscalDocument, QSortBy> {
  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByAuthorizationNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorizationNumber', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByAuthorizationNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorizationNumber', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByCufe() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cufe', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByCufeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cufe', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByCustomerDocument() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerDocument', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByCustomerDocumentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerDocument', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByDocumentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentType', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByDocumentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentType', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByFiscalNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiscalNumber', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByFiscalNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiscalNumber', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByIsPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByIssuedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issuedAt', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByIssuedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issuedAt', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByRelatedDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedDocumentId', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByRelatedDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedDocumentId', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortBySaleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleId', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortBySaleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleId', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension FiscalDocumentQuerySortThenBy
    on QueryBuilder<FiscalDocument, FiscalDocument, QSortThenBy> {
  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByAuthorizationNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorizationNumber', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByAuthorizationNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorizationNumber', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByCufe() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cufe', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByCufeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cufe', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByCustomerDocument() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerDocument', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByCustomerDocumentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerDocument', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByDocumentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentType', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByDocumentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentType', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByFiscalNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiscalNumber', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByFiscalNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiscalNumber', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByIsPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByIssuedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issuedAt', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByIssuedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issuedAt', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByRelatedDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedDocumentId', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByRelatedDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relatedDocumentId', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenBySaleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleId', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenBySaleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleId', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxAmount', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension FiscalDocumentQueryWhereDistinct
    on QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> {
  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByAuthorizationNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authorizationNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> distinctByCufe(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cufe', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByCustomerDocument({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerDocument',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByCustomerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByDocumentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentType');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByErrorMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByFiscalNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fiscalNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPendingSync');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> distinctByIssuedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'issuedAt');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> distinctByLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByRelatedDocumentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relatedDocumentId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> distinctBySaleId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'saleId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> distinctBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtotal');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxAmount');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct> distinctByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'total');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocument, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension FiscalDocumentQueryProperty
    on QueryBuilder<FiscalDocument, FiscalDocument, QQueryProperty> {
  QueryBuilder<FiscalDocument, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<FiscalDocument, String?, QQueryOperations>
      authorizationNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authorizationNumber');
    });
  }

  QueryBuilder<FiscalDocument, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<FiscalDocument, String?, QQueryOperations> cufeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cufe');
    });
  }

  QueryBuilder<FiscalDocument, String?, QQueryOperations>
      customerDocumentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerDocument');
    });
  }

  QueryBuilder<FiscalDocument, String?, QQueryOperations>
      customerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerName');
    });
  }

  QueryBuilder<FiscalDocument, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocumentType, QQueryOperations>
      documentTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentType');
    });
  }

  QueryBuilder<FiscalDocument, String?, QQueryOperations>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMessage');
    });
  }

  QueryBuilder<FiscalDocument, String, QQueryOperations>
      fiscalNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fiscalNumber');
    });
  }

  QueryBuilder<FiscalDocument, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<FiscalDocument, bool, QQueryOperations> isPendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPendingSync');
    });
  }

  QueryBuilder<FiscalDocument, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<FiscalDocument, DateTime, QQueryOperations> issuedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'issuedAt');
    });
  }

  QueryBuilder<FiscalDocument, String, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<FiscalDocument, String?, QQueryOperations>
      relatedDocumentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relatedDocumentId');
    });
  }

  QueryBuilder<FiscalDocument, String, QQueryOperations> saleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'saleId');
    });
  }

  QueryBuilder<FiscalDocument, String?, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<FiscalDocument, FiscalDocumentStatus, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<FiscalDocument, double, QQueryOperations> subtotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtotal');
    });
  }

  QueryBuilder<FiscalDocument, SyncStatus, QQueryOperations>
      syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<FiscalDocument, double, QQueryOperations> taxAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxAmount');
    });
  }

  QueryBuilder<FiscalDocument, double, QQueryOperations> totalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'total');
    });
  }

  QueryBuilder<FiscalDocument, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
