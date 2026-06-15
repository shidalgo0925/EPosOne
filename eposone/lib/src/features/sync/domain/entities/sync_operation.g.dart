// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncOperationCollection on Isar {
  IsarCollection<SyncOperation> get syncOperations => this.collection();
}

const SyncOperationSchema = CollectionSchema(
  name: r'SyncOperation',
  id: 564399705184180324,
  properties: {
    r'attemptCount': PropertySchema(
      id: 0,
      name: r'attemptCount',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 2,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'direction': PropertySchema(
      id: 3,
      name: r'direction',
      type: IsarType.byte,
      enumMap: _SyncOperationdirectionEnumValueMap,
    ),
    r'entityKind': PropertySchema(
      id: 4,
      name: r'entityKind',
      type: IsarType.byte,
      enumMap: _SyncOperationentityKindEnumValueMap,
    ),
    r'entityLocalId': PropertySchema(
      id: 5,
      name: r'entityLocalId',
      type: IsarType.string,
    ),
    r'errorMessage': PropertySchema(
      id: 6,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 7,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isPendingSync': PropertySchema(
      id: 8,
      name: r'isPendingSync',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 9,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'localId': PropertySchema(
      id: 10,
      name: r'localId',
      type: IsarType.string,
    ),
    r'operationStatus': PropertySchema(
      id: 11,
      name: r'operationStatus',
      type: IsarType.byte,
      enumMap: _SyncOperationoperationStatusEnumValueMap,
    ),
    r'processedAt': PropertySchema(
      id: 12,
      name: r'processedAt',
      type: IsarType.dateTime,
    ),
    r'serverId': PropertySchema(
      id: 13,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 14,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _SyncOperationsyncStatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 15,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _syncOperationEstimateSize,
  serialize: _syncOperationSerialize,
  deserialize: _syncOperationDeserialize,
  deserializeProp: _syncOperationDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _syncOperationGetId,
  getLinks: _syncOperationGetLinks,
  attach: _syncOperationAttach,
  version: '3.1.0+1',
);

int _syncOperationEstimateSize(
  SyncOperation object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.entityLocalId;
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
  bytesCount += 3 + object.localId.length * 3;
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _syncOperationSerialize(
  SyncOperation object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.attemptCount);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.deletedAt);
  writer.writeByte(offsets[3], object.direction.index);
  writer.writeByte(offsets[4], object.entityKind.index);
  writer.writeString(offsets[5], object.entityLocalId);
  writer.writeString(offsets[6], object.errorMessage);
  writer.writeBool(offsets[7], object.isDeleted);
  writer.writeBool(offsets[8], object.isPendingSync);
  writer.writeBool(offsets[9], object.isSynced);
  writer.writeString(offsets[10], object.localId);
  writer.writeByte(offsets[11], object.operationStatus.index);
  writer.writeDateTime(offsets[12], object.processedAt);
  writer.writeString(offsets[13], object.serverId);
  writer.writeByte(offsets[14], object.syncStatus.index);
  writer.writeDateTime(offsets[15], object.updatedAt);
}

SyncOperation _syncOperationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncOperation(
    attemptCount: reader.readLongOrNull(offsets[0]) ?? 0,
    createdAt: reader.readDateTime(offsets[1]),
    deletedAt: reader.readDateTimeOrNull(offsets[2]),
    direction: _SyncOperationdirectionValueEnumMap[
            reader.readByteOrNull(offsets[3])] ??
        SyncDirection.push,
    entityKind: _SyncOperationentityKindValueEnumMap[
            reader.readByteOrNull(offsets[4])] ??
        SyncEntityKind.sale,
    entityLocalId: reader.readStringOrNull(offsets[5]),
    errorMessage: reader.readStringOrNull(offsets[6]),
    localId: reader.readString(offsets[10]),
    operationStatus: _SyncOperationoperationStatusValueEnumMap[
            reader.readByteOrNull(offsets[11])] ??
        SyncOperationStatus.pending,
    processedAt: reader.readDateTimeOrNull(offsets[12]),
    serverId: reader.readStringOrNull(offsets[13]),
    syncStatus: _SyncOperationsyncStatusValueEnumMap[
            reader.readByteOrNull(offsets[14])] ??
        SyncStatus.pending,
    updatedAt: reader.readDateTime(offsets[15]),
  );
  return object;
}

P _syncOperationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (_SyncOperationdirectionValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncDirection.push) as P;
    case 4:
      return (_SyncOperationentityKindValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncEntityKind.sale) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (_SyncOperationoperationStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncOperationStatus.pending) as P;
    case 12:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (_SyncOperationsyncStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncStatus.pending) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SyncOperationdirectionEnumValueMap = {
  'push': 0,
  'pull': 1,
};
const _SyncOperationdirectionValueEnumMap = {
  0: SyncDirection.push,
  1: SyncDirection.pull,
};
const _SyncOperationentityKindEnumValueMap = {
  'sale': 0,
  'customer': 1,
  'cashMovement': 2,
  'cashRegister': 3,
  'catalogPull': 4,
};
const _SyncOperationentityKindValueEnumMap = {
  0: SyncEntityKind.sale,
  1: SyncEntityKind.customer,
  2: SyncEntityKind.cashMovement,
  3: SyncEntityKind.cashRegister,
  4: SyncEntityKind.catalogPull,
};
const _SyncOperationoperationStatusEnumValueMap = {
  'pending': 0,
  'processing': 1,
  'completed': 2,
  'failed': 3,
};
const _SyncOperationoperationStatusValueEnumMap = {
  0: SyncOperationStatus.pending,
  1: SyncOperationStatus.processing,
  2: SyncOperationStatus.completed,
  3: SyncOperationStatus.failed,
};
const _SyncOperationsyncStatusEnumValueMap = {
  'pending': 0,
  'synced': 1,
  'modified': 2,
  'error': 3,
};
const _SyncOperationsyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.synced,
  2: SyncStatus.modified,
  3: SyncStatus.error,
};

Id _syncOperationGetId(SyncOperation object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _syncOperationGetLinks(SyncOperation object) {
  return [];
}

void _syncOperationAttach(
    IsarCollection<dynamic> col, Id id, SyncOperation object) {}

extension SyncOperationQueryWhereSort
    on QueryBuilder<SyncOperation, SyncOperation, QWhere> {
  QueryBuilder<SyncOperation, SyncOperation, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncOperationQueryWhere
    on QueryBuilder<SyncOperation, SyncOperation, QWhereClause> {
  QueryBuilder<SyncOperation, SyncOperation, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterWhereClause>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterWhereClause> isarIdBetween(
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

extension SyncOperationQueryFilter
    on QueryBuilder<SyncOperation, SyncOperation, QFilterCondition> {
  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      attemptCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attemptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      attemptCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attemptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      attemptCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attemptCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      attemptCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attemptCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      directionEqualTo(SyncDirection value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'direction',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      directionGreaterThan(
    SyncDirection value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'direction',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      directionLessThan(
    SyncDirection value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'direction',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      directionBetween(
    SyncDirection lower,
    SyncDirection upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'direction',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityKindEqualTo(SyncEntityKind value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityKind',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityKindGreaterThan(
    SyncEntityKind value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entityKind',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityKindLessThan(
    SyncEntityKind value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entityKind',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityKindBetween(
    SyncEntityKind lower,
    SyncEntityKind upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entityKind',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'entityLocalId',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'entityLocalId',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entityLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entityLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entityLocalId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entityLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entityLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entityLocalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entityLocalId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityLocalId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      entityLocalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entityLocalId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      errorMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      errorMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'errorMessage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      isPendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPendingSync',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      localIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      localIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      localIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      localIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      operationStatusEqualTo(SyncOperationStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'operationStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      operationStatusGreaterThan(
    SyncOperationStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'operationStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      operationStatusLessThan(
    SyncOperationStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'operationStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      operationStatusBetween(
    SyncOperationStatus lower,
    SyncOperationStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'operationStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      processedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'processedAt',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      processedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'processedAt',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      processedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      processedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      processedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'processedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      processedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'processedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

  QueryBuilder<SyncOperation, SyncOperation, QAfterFilterCondition>
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

extension SyncOperationQueryObject
    on QueryBuilder<SyncOperation, SyncOperation, QFilterCondition> {}

extension SyncOperationQueryLinks
    on QueryBuilder<SyncOperation, SyncOperation, QFilterCondition> {}

extension SyncOperationQuerySortBy
    on QueryBuilder<SyncOperation, SyncOperation, QSortBy> {
  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByAttemptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByEntityLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityLocalId', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByEntityLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityLocalId', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByIsPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByOperationStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationStatus', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByOperationStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationStatus', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByProcessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SyncOperationQuerySortThenBy
    on QueryBuilder<SyncOperation, SyncOperation, QSortThenBy> {
  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByAttemptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByEntityLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityLocalId', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByEntityLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityLocalId', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByIsPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByOperationStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationStatus', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByOperationStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationStatus', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByProcessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'processedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SyncOperationQueryWhereDistinct
    on QueryBuilder<SyncOperation, SyncOperation, QDistinct> {
  QueryBuilder<SyncOperation, SyncOperation, QDistinct>
      distinctByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attemptCount');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'direction');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityKind');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByEntityLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityLocalId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByErrorMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct>
      distinctByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPendingSync');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct>
      distinctByOperationStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'operationStatus');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct>
      distinctByProcessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'processedAt');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<SyncOperation, SyncOperation, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SyncOperationQueryProperty
    on QueryBuilder<SyncOperation, SyncOperation, QQueryProperty> {
  QueryBuilder<SyncOperation, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<SyncOperation, int, QQueryOperations> attemptCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attemptCount');
    });
  }

  QueryBuilder<SyncOperation, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SyncOperation, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<SyncOperation, SyncDirection, QQueryOperations>
      directionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'direction');
    });
  }

  QueryBuilder<SyncOperation, SyncEntityKind, QQueryOperations>
      entityKindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityKind');
    });
  }

  QueryBuilder<SyncOperation, String?, QQueryOperations>
      entityLocalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityLocalId');
    });
  }

  QueryBuilder<SyncOperation, String?, QQueryOperations>
      errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMessage');
    });
  }

  QueryBuilder<SyncOperation, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<SyncOperation, bool, QQueryOperations> isPendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPendingSync');
    });
  }

  QueryBuilder<SyncOperation, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<SyncOperation, String, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<SyncOperation, SyncOperationStatus, QQueryOperations>
      operationStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'operationStatus');
    });
  }

  QueryBuilder<SyncOperation, DateTime?, QQueryOperations>
      processedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'processedAt');
    });
  }

  QueryBuilder<SyncOperation, String?, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<SyncOperation, SyncStatus, QQueryOperations>
      syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<SyncOperation, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
