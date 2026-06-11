// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_register.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCashRegisterCollection on Isar {
  IsarCollection<CashRegister> get cashRegisters => this.collection();
}

const CashRegisterSchema = CollectionSchema(
  name: r'CashRegister',
  id: 8604440459258129516,
  properties: {
    r'closeDate': PropertySchema(
      id: 0,
      name: r'closeDate',
      type: IsarType.dateTime,
    ),
    r'closedBy': PropertySchema(
      id: 1,
      name: r'closedBy',
      type: IsarType.string,
    ),
    r'closingAmount': PropertySchema(
      id: 2,
      name: r'closingAmount',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 4,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'difference': PropertySchema(
      id: 5,
      name: r'difference',
      type: IsarType.double,
    ),
    r'expectedAmount': PropertySchema(
      id: 6,
      name: r'expectedAmount',
      type: IsarType.double,
    ),
    r'isDeleted': PropertySchema(
      id: 7,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isOpen': PropertySchema(
      id: 8,
      name: r'isOpen',
      type: IsarType.bool,
    ),
    r'isPendingSync': PropertySchema(
      id: 9,
      name: r'isPendingSync',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 10,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'localId': PropertySchema(
      id: 11,
      name: r'localId',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 12,
      name: r'notes',
      type: IsarType.string,
    ),
    r'openDate': PropertySchema(
      id: 13,
      name: r'openDate',
      type: IsarType.dateTime,
    ),
    r'openedBy': PropertySchema(
      id: 14,
      name: r'openedBy',
      type: IsarType.string,
    ),
    r'openingAmount': PropertySchema(
      id: 15,
      name: r'openingAmount',
      type: IsarType.double,
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
      enumMap: _CashRegisterstatusEnumValueMap,
    ),
    r'syncStatus': PropertySchema(
      id: 18,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _CashRegistersyncStatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 19,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _cashRegisterEstimateSize,
  serialize: _cashRegisterSerialize,
  deserialize: _cashRegisterDeserialize,
  deserializeProp: _cashRegisterDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _cashRegisterGetId,
  getLinks: _cashRegisterGetLinks,
  attach: _cashRegisterAttach,
  version: '3.1.0+1',
);

int _cashRegisterEstimateSize(
  CashRegister object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.closedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.localId.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.openedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _cashRegisterSerialize(
  CashRegister object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.closeDate);
  writer.writeString(offsets[1], object.closedBy);
  writer.writeDouble(offsets[2], object.closingAmount);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeDateTime(offsets[4], object.deletedAt);
  writer.writeDouble(offsets[5], object.difference);
  writer.writeDouble(offsets[6], object.expectedAmount);
  writer.writeBool(offsets[7], object.isDeleted);
  writer.writeBool(offsets[8], object.isOpen);
  writer.writeBool(offsets[9], object.isPendingSync);
  writer.writeBool(offsets[10], object.isSynced);
  writer.writeString(offsets[11], object.localId);
  writer.writeString(offsets[12], object.notes);
  writer.writeDateTime(offsets[13], object.openDate);
  writer.writeString(offsets[14], object.openedBy);
  writer.writeDouble(offsets[15], object.openingAmount);
  writer.writeString(offsets[16], object.serverId);
  writer.writeByte(offsets[17], object.status.index);
  writer.writeByte(offsets[18], object.syncStatus.index);
  writer.writeDateTime(offsets[19], object.updatedAt);
}

CashRegister _cashRegisterDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CashRegister(
    closeDate: reader.readDateTimeOrNull(offsets[0]),
    closedBy: reader.readStringOrNull(offsets[1]),
    closingAmount: reader.readDoubleOrNull(offsets[2]),
    createdAt: reader.readDateTime(offsets[3]),
    deletedAt: reader.readDateTimeOrNull(offsets[4]),
    difference: reader.readDoubleOrNull(offsets[5]),
    expectedAmount: reader.readDoubleOrNull(offsets[6]),
    localId: reader.readString(offsets[11]),
    notes: reader.readStringOrNull(offsets[12]),
    openDate: reader.readDateTime(offsets[13]),
    openedBy: reader.readStringOrNull(offsets[14]),
    openingAmount: reader.readDouble(offsets[15]),
    serverId: reader.readStringOrNull(offsets[16]),
    status:
        _CashRegisterstatusValueEnumMap[reader.readByteOrNull(offsets[17])] ??
            CashRegisterStatus.open,
    syncStatus: _CashRegistersyncStatusValueEnumMap[
            reader.readByteOrNull(offsets[18])] ??
        SyncStatus.pending,
    updatedAt: reader.readDateTime(offsets[19]),
  );
  return object;
}

P _cashRegisterDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (_CashRegisterstatusValueEnumMap[reader.readByteOrNull(offset)] ??
          CashRegisterStatus.open) as P;
    case 18:
      return (_CashRegistersyncStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncStatus.pending) as P;
    case 19:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CashRegisterstatusEnumValueMap = {
  'open': 0,
  'closed': 1,
};
const _CashRegisterstatusValueEnumMap = {
  0: CashRegisterStatus.open,
  1: CashRegisterStatus.closed,
};
const _CashRegistersyncStatusEnumValueMap = {
  'pending': 0,
  'synced': 1,
  'modified': 2,
  'error': 3,
};
const _CashRegistersyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.synced,
  2: SyncStatus.modified,
  3: SyncStatus.error,
};

Id _cashRegisterGetId(CashRegister object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _cashRegisterGetLinks(CashRegister object) {
  return [];
}

void _cashRegisterAttach(
    IsarCollection<dynamic> col, Id id, CashRegister object) {}

extension CashRegisterQueryWhereSort
    on QueryBuilder<CashRegister, CashRegister, QWhere> {
  QueryBuilder<CashRegister, CashRegister, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CashRegisterQueryWhere
    on QueryBuilder<CashRegister, CashRegister, QWhereClause> {
  QueryBuilder<CashRegister, CashRegister, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
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

  QueryBuilder<CashRegister, CashRegister, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterWhereClause> isarIdBetween(
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

extension CashRegisterQueryFilter
    on QueryBuilder<CashRegister, CashRegister, QFilterCondition> {
  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closeDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'closeDate',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closeDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'closeDate',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closeDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closeDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closeDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closeDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closeDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closeDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closeDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closeDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'closedBy',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'closedBy',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'closedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'closedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'closedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'closedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'closedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closingAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'closingAmount',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closingAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'closingAmount',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closingAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closingAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closingAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      closingAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closingAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      differenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'difference',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      differenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'difference',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      differenceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'difference',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      differenceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'difference',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      differenceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'difference',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      differenceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'difference',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      expectedAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expectedAmount',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      expectedAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expectedAmount',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      expectedAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expectedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      expectedAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expectedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      expectedAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expectedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      expectedAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expectedAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> isOpenEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOpen',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      isPendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPendingSync',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> isarIdBetween(
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      localIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      localIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      localIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      localIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> notesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> notesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'openDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'openDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'openDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'openedBy',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'openedBy',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'openedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'openedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'openedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'openedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'openedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'openedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'openedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'openedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openingAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openingAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'openingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openingAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'openingAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      openingAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'openingAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> statusEqualTo(
      CashRegisterStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      statusGreaterThan(
    CashRegisterStatus value, {
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      statusLessThan(
    CashRegisterStatus value, {
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition> statusBetween(
    CashRegisterStatus lower,
    CashRegisterStatus upper, {
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

  QueryBuilder<CashRegister, CashRegister, QAfterFilterCondition>
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

extension CashRegisterQueryObject
    on QueryBuilder<CashRegister, CashRegister, QFilterCondition> {}

extension CashRegisterQueryLinks
    on QueryBuilder<CashRegister, CashRegister, QFilterCondition> {}

extension CashRegisterQuerySortBy
    on QueryBuilder<CashRegister, CashRegister, QSortBy> {
  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByCloseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closeDate', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByCloseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closeDate', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByClosedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedBy', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByClosedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedBy', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByClosingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closingAmount', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      sortByClosingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closingAmount', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByDifference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difference', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      sortByDifferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difference', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      sortByExpectedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedAmount', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      sortByExpectedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedAmount', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByIsOpen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOpen', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByIsOpenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOpen', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      sortByIsPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByOpenDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openDate', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByOpenDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openDate', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByOpenedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedBy', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByOpenedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedBy', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByOpeningAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openingAmount', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      sortByOpeningAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openingAmount', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CashRegisterQuerySortThenBy
    on QueryBuilder<CashRegister, CashRegister, QSortThenBy> {
  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByCloseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closeDate', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByCloseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closeDate', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByClosedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedBy', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByClosedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedBy', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByClosingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closingAmount', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      thenByClosingAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closingAmount', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByDifference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difference', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      thenByDifferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'difference', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      thenByExpectedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedAmount', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      thenByExpectedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedAmount', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByIsOpen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOpen', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByIsOpenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOpen', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      thenByIsPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByOpenDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openDate', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByOpenDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openDate', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByOpenedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedBy', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByOpenedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedBy', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByOpeningAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openingAmount', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      thenByOpeningAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openingAmount', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CashRegisterQueryWhereDistinct
    on QueryBuilder<CashRegister, CashRegister, QDistinct> {
  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByCloseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closeDate');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByClosedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct>
      distinctByClosingAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closingAmount');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByDifference() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'difference');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct>
      distinctByExpectedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expectedAmount');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByIsOpen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOpen');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct>
      distinctByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPendingSync');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByOpenDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openDate');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByOpenedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct>
      distinctByOpeningAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openingAmount');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<CashRegister, CashRegister, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CashRegisterQueryProperty
    on QueryBuilder<CashRegister, CashRegister, QQueryProperty> {
  QueryBuilder<CashRegister, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<CashRegister, DateTime?, QQueryOperations> closeDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closeDate');
    });
  }

  QueryBuilder<CashRegister, String?, QQueryOperations> closedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closedBy');
    });
  }

  QueryBuilder<CashRegister, double?, QQueryOperations>
      closingAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closingAmount');
    });
  }

  QueryBuilder<CashRegister, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CashRegister, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<CashRegister, double?, QQueryOperations> differenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'difference');
    });
  }

  QueryBuilder<CashRegister, double?, QQueryOperations>
      expectedAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expectedAmount');
    });
  }

  QueryBuilder<CashRegister, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<CashRegister, bool, QQueryOperations> isOpenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOpen');
    });
  }

  QueryBuilder<CashRegister, bool, QQueryOperations> isPendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPendingSync');
    });
  }

  QueryBuilder<CashRegister, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<CashRegister, String, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<CashRegister, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<CashRegister, DateTime, QQueryOperations> openDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openDate');
    });
  }

  QueryBuilder<CashRegister, String?, QQueryOperations> openedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openedBy');
    });
  }

  QueryBuilder<CashRegister, double, QQueryOperations> openingAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openingAmount');
    });
  }

  QueryBuilder<CashRegister, String?, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<CashRegister, CashRegisterStatus, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CashRegister, SyncStatus, QQueryOperations>
      syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<CashRegister, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
