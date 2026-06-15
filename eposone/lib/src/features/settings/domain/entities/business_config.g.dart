// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_config.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBusinessConfigCollection on Isar {
  IsarCollection<BusinessConfig> get businessConfigs => this.collection();
}

const BusinessConfigSchema = CollectionSchema(
  name: r'BusinessConfig',
  id: -6105623215919750370,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'allowDecimalQty': PropertySchema(
      id: 1,
      name: r'allowDecimalQty',
      type: IsarType.bool,
    ),
    r'businessName': PropertySchema(
      id: 2,
      name: r'businessName',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currency': PropertySchema(
      id: 4,
      name: r'currency',
      type: IsarType.string,
    ),
    r'currencySymbol': PropertySchema(
      id: 5,
      name: r'currencySymbol',
      type: IsarType.string,
    ),
    r'defaultOrderType': PropertySchema(
      id: 6,
      name: r'defaultOrderType',
      type: IsarType.byte,
      enumMap: _BusinessConfigdefaultOrderTypeEnumValueMap,
    ),
    r'deletedAt': PropertySchema(
      id: 7,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'email': PropertySchema(
      id: 8,
      name: r'email',
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
    r'isSetupComplete': PropertySchema(
      id: 11,
      name: r'isSetupComplete',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 12,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'localId': PropertySchema(
      id: 13,
      name: r'localId',
      type: IsarType.string,
    ),
    r'logoPath': PropertySchema(
      id: 14,
      name: r'logoPath',
      type: IsarType.string,
    ),
    r'nextReceiptNumber': PropertySchema(
      id: 15,
      name: r'nextReceiptNumber',
      type: IsarType.string,
    ),
    r'openTicketsEnabled': PropertySchema(
      id: 16,
      name: r'openTicketsEnabled',
      type: IsarType.bool,
    ),
    r'phone': PropertySchema(
      id: 17,
      name: r'phone',
      type: IsarType.string,
    ),
    r'receiptFooter': PropertySchema(
      id: 18,
      name: r'receiptFooter',
      type: IsarType.string,
    ),
    r'receiptHeader': PropertySchema(
      id: 19,
      name: r'receiptHeader',
      type: IsarType.string,
    ),
    r'receiptNextNumber': PropertySchema(
      id: 20,
      name: r'receiptNextNumber',
      type: IsarType.long,
    ),
    r'receiptPrefix': PropertySchema(
      id: 21,
      name: r'receiptPrefix',
      type: IsarType.string,
    ),
    r'ruc': PropertySchema(
      id: 22,
      name: r'ruc',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 23,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 24,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _BusinessConfigsyncStatusEnumValueMap,
    ),
    r'taxIncluded': PropertySchema(
      id: 25,
      name: r'taxIncluded',
      type: IsarType.bool,
    ),
    r'taxName': PropertySchema(
      id: 26,
      name: r'taxName',
      type: IsarType.string,
    ),
    r'taxRate': PropertySchema(
      id: 27,
      name: r'taxRate',
      type: IsarType.double,
    ),
    r'trackInventory': PropertySchema(
      id: 28,
      name: r'trackInventory',
      type: IsarType.bool,
    ),
    r'updatedAt': PropertySchema(
      id: 29,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'usePredefinedTickets': PropertySchema(
      id: 30,
      name: r'usePredefinedTickets',
      type: IsarType.bool,
    )
  },
  estimateSize: _businessConfigEstimateSize,
  serialize: _businessConfigSerialize,
  deserialize: _businessConfigDeserialize,
  deserializeProp: _businessConfigDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _businessConfigGetId,
  getLinks: _businessConfigGetLinks,
  attach: _businessConfigAttach,
  version: '3.1.0+1',
);

int _businessConfigEstimateSize(
  BusinessConfig object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.address;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.businessName.length * 3;
  bytesCount += 3 + object.currency.length * 3;
  {
    final value = object.currencySymbol;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.email;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.localId.length * 3;
  {
    final value = object.logoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.nextReceiptNumber.length * 3;
  {
    final value = object.phone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.receiptFooter.length * 3;
  bytesCount += 3 + object.receiptHeader.length * 3;
  {
    final value = object.receiptPrefix;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.ruc;
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
  {
    final value = object.taxName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _businessConfigSerialize(
  BusinessConfig object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeBool(offsets[1], object.allowDecimalQty);
  writer.writeString(offsets[2], object.businessName);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.currency);
  writer.writeString(offsets[5], object.currencySymbol);
  writer.writeByte(offsets[6], object.defaultOrderType.index);
  writer.writeDateTime(offsets[7], object.deletedAt);
  writer.writeString(offsets[8], object.email);
  writer.writeBool(offsets[9], object.isDeleted);
  writer.writeBool(offsets[10], object.isPendingSync);
  writer.writeBool(offsets[11], object.isSetupComplete);
  writer.writeBool(offsets[12], object.isSynced);
  writer.writeString(offsets[13], object.localId);
  writer.writeString(offsets[14], object.logoPath);
  writer.writeString(offsets[15], object.nextReceiptNumber);
  writer.writeBool(offsets[16], object.openTicketsEnabled);
  writer.writeString(offsets[17], object.phone);
  writer.writeString(offsets[18], object.receiptFooter);
  writer.writeString(offsets[19], object.receiptHeader);
  writer.writeLong(offsets[20], object.receiptNextNumber);
  writer.writeString(offsets[21], object.receiptPrefix);
  writer.writeString(offsets[22], object.ruc);
  writer.writeString(offsets[23], object.serverId);
  writer.writeByte(offsets[24], object.syncStatus.index);
  writer.writeBool(offsets[25], object.taxIncluded);
  writer.writeString(offsets[26], object.taxName);
  writer.writeDouble(offsets[27], object.taxRate);
  writer.writeBool(offsets[28], object.trackInventory);
  writer.writeDateTime(offsets[29], object.updatedAt);
  writer.writeBool(offsets[30], object.usePredefinedTickets);
}

BusinessConfig _businessConfigDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BusinessConfig(
    address: reader.readStringOrNull(offsets[0]),
    allowDecimalQty: reader.readBoolOrNull(offsets[1]) ?? false,
    businessName: reader.readString(offsets[2]),
    createdAt: reader.readDateTime(offsets[3]),
    currency: reader.readStringOrNull(offsets[4]) ?? 'USD',
    currencySymbol: reader.readStringOrNull(offsets[5]),
    defaultOrderType: _BusinessConfigdefaultOrderTypeValueEnumMap[
            reader.readByteOrNull(offsets[6])] ??
        OrderType.generic,
    deletedAt: reader.readDateTimeOrNull(offsets[7]),
    email: reader.readStringOrNull(offsets[8]),
    isSetupComplete: reader.readBoolOrNull(offsets[11]) ?? false,
    localId: reader.readString(offsets[13]),
    logoPath: reader.readStringOrNull(offsets[14]),
    openTicketsEnabled: reader.readBoolOrNull(offsets[16]) ?? true,
    phone: reader.readStringOrNull(offsets[17]),
    receiptFooter: reader.readStringOrNull(offsets[18]) ?? 'Vuelva pronto',
    receiptHeader:
        reader.readStringOrNull(offsets[19]) ?? 'Gracias por su compra',
    receiptNextNumber: reader.readLongOrNull(offsets[20]) ?? 1,
    receiptPrefix: reader.readStringOrNull(offsets[21]),
    ruc: reader.readStringOrNull(offsets[22]),
    serverId: reader.readStringOrNull(offsets[23]),
    syncStatus: _BusinessConfigsyncStatusValueEnumMap[
            reader.readByteOrNull(offsets[24])] ??
        SyncStatus.pending,
    taxIncluded: reader.readBoolOrNull(offsets[25]) ?? false,
    taxName: reader.readStringOrNull(offsets[26]),
    taxRate: reader.readDoubleOrNull(offsets[27]) ?? 0,
    trackInventory: reader.readBoolOrNull(offsets[28]) ?? true,
    updatedAt: reader.readDateTime(offsets[29]),
    usePredefinedTickets: reader.readBoolOrNull(offsets[30]) ?? false,
  );
  return object;
}

P _businessConfigDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset) ?? 'USD') as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (_BusinessConfigdefaultOrderTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          OrderType.generic) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset) ?? 'Vuelva pronto') as P;
    case 19:
      return (reader.readStringOrNull(offset) ?? 'Gracias por su compra') as P;
    case 20:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (_BusinessConfigsyncStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncStatus.pending) as P;
    case 25:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 26:
      return (reader.readStringOrNull(offset)) as P;
    case 27:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 28:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 29:
      return (reader.readDateTime(offset)) as P;
    case 30:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _BusinessConfigdefaultOrderTypeEnumValueMap = {
  'generic': 0,
  'dineIn': 1,
  'takeaway': 2,
  'delivery': 3,
};
const _BusinessConfigdefaultOrderTypeValueEnumMap = {
  0: OrderType.generic,
  1: OrderType.dineIn,
  2: OrderType.takeaway,
  3: OrderType.delivery,
};
const _BusinessConfigsyncStatusEnumValueMap = {
  'pending': 0,
  'synced': 1,
  'modified': 2,
  'error': 3,
};
const _BusinessConfigsyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.synced,
  2: SyncStatus.modified,
  3: SyncStatus.error,
};

Id _businessConfigGetId(BusinessConfig object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _businessConfigGetLinks(BusinessConfig object) {
  return [];
}

void _businessConfigAttach(
    IsarCollection<dynamic> col, Id id, BusinessConfig object) {}

extension BusinessConfigQueryWhereSort
    on QueryBuilder<BusinessConfig, BusinessConfig, QWhere> {
  QueryBuilder<BusinessConfig, BusinessConfig, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BusinessConfigQueryWhere
    on QueryBuilder<BusinessConfig, BusinessConfig, QWhereClause> {
  QueryBuilder<BusinessConfig, BusinessConfig, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterWhereClause>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterWhereClause> isarIdBetween(
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

extension BusinessConfigQueryFilter
    on QueryBuilder<BusinessConfig, BusinessConfig, QFilterCondition> {
  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'address',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      allowDecimalQtyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'allowDecimalQty',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'businessName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'businessName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'businessName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'businessName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'businessName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'businessName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'businessName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'businessName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'businessName',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      businessNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'businessName',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currencySymbol',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currencySymbol',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currencySymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currencySymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currencySymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currencySymbol',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currencySymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currencySymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currencySymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currencySymbol',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currencySymbol',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      currencySymbolIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currencySymbol',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      defaultOrderTypeEqualTo(OrderType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultOrderType',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      defaultOrderTypeGreaterThan(
    OrderType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultOrderType',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      defaultOrderTypeLessThan(
    OrderType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultOrderType',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      defaultOrderTypeBetween(
    OrderType lower,
    OrderType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultOrderType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      isPendingSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPendingSync',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      isSetupCompleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSetupComplete',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      localIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      localIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      localIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      localIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'logoPath',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'logoPath',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'logoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'logoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'logoPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'logoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'logoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'logoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'logoPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      logoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'logoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextReceiptNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextReceiptNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextReceiptNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextReceiptNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nextReceiptNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nextReceiptNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nextReceiptNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nextReceiptNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextReceiptNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      nextReceiptNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nextReceiptNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      openTicketsEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openTicketsEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'phone',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'phone',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'phone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'phone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phone',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      phoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'phone',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptFooter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiptFooter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiptFooter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiptFooter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiptFooter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiptFooter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiptFooter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiptFooter',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptFooter',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptFooterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiptFooter',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptHeader',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiptHeader',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiptHeader',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiptHeader',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiptHeader',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiptHeader',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiptHeader',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiptHeader',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptHeader',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptHeaderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiptHeader',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptNextNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptNextNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptNextNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiptNextNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptNextNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiptNextNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptNextNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiptNextNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'receiptPrefix',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'receiptPrefix',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptPrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiptPrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiptPrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiptPrefix',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiptPrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiptPrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiptPrefix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiptPrefix',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptPrefix',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      receiptPrefixIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiptPrefix',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ruc',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ruc',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ruc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ruc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ruc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ruc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ruc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ruc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ruc',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruc',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      rucIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ruc',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serverId',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxIncludedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taxIncluded',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'taxName',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'taxName',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taxName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taxName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taxName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taxName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'taxName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'taxName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'taxName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'taxName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taxName',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'taxName',
        value: '',
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taxRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taxRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taxRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      taxRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taxRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      trackInventoryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackInventory',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
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

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterFilterCondition>
      usePredefinedTicketsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usePredefinedTickets',
        value: value,
      ));
    });
  }
}

extension BusinessConfigQueryObject
    on QueryBuilder<BusinessConfig, BusinessConfig, QFilterCondition> {}

extension BusinessConfigQueryLinks
    on QueryBuilder<BusinessConfig, BusinessConfig, QFilterCondition> {}

extension BusinessConfigQuerySortBy
    on QueryBuilder<BusinessConfig, BusinessConfig, QSortBy> {
  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByAllowDecimalQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowDecimalQty', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByAllowDecimalQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowDecimalQty', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByBusinessName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByBusinessNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByCurrencySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencySymbol', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByCurrencySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencySymbol', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByDefaultOrderType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultOrderType', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByDefaultOrderTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultOrderType', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByIsPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByIsSetupComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSetupComplete', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByIsSetupCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSetupComplete', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByLogoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoPath', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByLogoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoPath', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByNextReceiptNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReceiptNumber', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByNextReceiptNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReceiptNumber', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByOpenTicketsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openTicketsEnabled', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByOpenTicketsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openTicketsEnabled', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByReceiptFooter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptFooter', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByReceiptFooterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptFooter', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByReceiptHeader() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptHeader', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByReceiptHeaderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptHeader', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByReceiptNextNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptNextNumber', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByReceiptNextNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptNextNumber', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByReceiptPrefix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptPrefix', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByReceiptPrefixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptPrefix', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByRuc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruc', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByRucDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruc', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByTaxIncluded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxIncluded', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByTaxIncludedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxIncluded', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByTaxName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxName', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByTaxNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxName', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByTaxRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxRate', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByTaxRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxRate', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByTrackInventory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackInventory', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByTrackInventoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackInventory', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByUsePredefinedTickets() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usePredefinedTickets', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      sortByUsePredefinedTicketsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usePredefinedTickets', Sort.desc);
    });
  }
}

extension BusinessConfigQuerySortThenBy
    on QueryBuilder<BusinessConfig, BusinessConfig, QSortThenBy> {
  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByAllowDecimalQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowDecimalQty', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByAllowDecimalQtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowDecimalQty', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByBusinessName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByBusinessNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByCurrencySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencySymbol', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByCurrencySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currencySymbol', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByDefaultOrderType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultOrderType', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByDefaultOrderTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultOrderType', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByIsPendingSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPendingSync', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByIsSetupComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSetupComplete', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByIsSetupCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSetupComplete', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByLogoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoPath', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByLogoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoPath', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByNextReceiptNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReceiptNumber', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByNextReceiptNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReceiptNumber', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByOpenTicketsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openTicketsEnabled', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByOpenTicketsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openTicketsEnabled', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByReceiptFooter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptFooter', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByReceiptFooterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptFooter', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByReceiptHeader() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptHeader', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByReceiptHeaderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptHeader', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByReceiptNextNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptNextNumber', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByReceiptNextNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptNextNumber', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByReceiptPrefix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptPrefix', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByReceiptPrefixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptPrefix', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByRuc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruc', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByRucDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruc', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByTaxIncluded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxIncluded', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByTaxIncludedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxIncluded', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByTaxName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxName', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByTaxNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxName', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByTaxRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxRate', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByTaxRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxRate', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByTrackInventory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackInventory', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByTrackInventoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackInventory', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByUsePredefinedTickets() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usePredefinedTickets', Sort.asc);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QAfterSortBy>
      thenByUsePredefinedTicketsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usePredefinedTickets', Sort.desc);
    });
  }
}

extension BusinessConfigQueryWhereDistinct
    on QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> {
  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByAllowDecimalQty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowDecimalQty');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByBusinessName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'businessName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByCurrency(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByCurrencySymbol({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currencySymbol',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByDefaultOrderType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultOrderType');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByIsPendingSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPendingSync');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByIsSetupComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSetupComplete');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByLogoPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'logoPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByNextReceiptNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextReceiptNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByOpenTicketsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openTicketsEnabled');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByPhone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByReceiptFooter({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptFooter',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByReceiptHeader({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptHeader',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByReceiptNextNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptNextNumber');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByReceiptPrefix({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptPrefix',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByRuc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ruc', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByTaxIncluded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxIncluded');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByTaxName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct> distinctByTaxRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxRate');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByTrackInventory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackInventory');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<BusinessConfig, BusinessConfig, QDistinct>
      distinctByUsePredefinedTickets() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usePredefinedTickets');
    });
  }
}

extension BusinessConfigQueryProperty
    on QueryBuilder<BusinessConfig, BusinessConfig, QQueryProperty> {
  QueryBuilder<BusinessConfig, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<BusinessConfig, String?, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<BusinessConfig, bool, QQueryOperations>
      allowDecimalQtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowDecimalQty');
    });
  }

  QueryBuilder<BusinessConfig, String, QQueryOperations>
      businessNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'businessName');
    });
  }

  QueryBuilder<BusinessConfig, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<BusinessConfig, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<BusinessConfig, String?, QQueryOperations>
      currencySymbolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currencySymbol');
    });
  }

  QueryBuilder<BusinessConfig, OrderType, QQueryOperations>
      defaultOrderTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultOrderType');
    });
  }

  QueryBuilder<BusinessConfig, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<BusinessConfig, String?, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<BusinessConfig, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<BusinessConfig, bool, QQueryOperations> isPendingSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPendingSync');
    });
  }

  QueryBuilder<BusinessConfig, bool, QQueryOperations>
      isSetupCompleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSetupComplete');
    });
  }

  QueryBuilder<BusinessConfig, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<BusinessConfig, String, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<BusinessConfig, String?, QQueryOperations> logoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logoPath');
    });
  }

  QueryBuilder<BusinessConfig, String, QQueryOperations>
      nextReceiptNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextReceiptNumber');
    });
  }

  QueryBuilder<BusinessConfig, bool, QQueryOperations>
      openTicketsEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openTicketsEnabled');
    });
  }

  QueryBuilder<BusinessConfig, String?, QQueryOperations> phoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phone');
    });
  }

  QueryBuilder<BusinessConfig, String, QQueryOperations>
      receiptFooterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptFooter');
    });
  }

  QueryBuilder<BusinessConfig, String, QQueryOperations>
      receiptHeaderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptHeader');
    });
  }

  QueryBuilder<BusinessConfig, int, QQueryOperations>
      receiptNextNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptNextNumber');
    });
  }

  QueryBuilder<BusinessConfig, String?, QQueryOperations>
      receiptPrefixProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptPrefix');
    });
  }

  QueryBuilder<BusinessConfig, String?, QQueryOperations> rucProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ruc');
    });
  }

  QueryBuilder<BusinessConfig, String?, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<BusinessConfig, SyncStatus, QQueryOperations>
      syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<BusinessConfig, bool, QQueryOperations> taxIncludedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxIncluded');
    });
  }

  QueryBuilder<BusinessConfig, String?, QQueryOperations> taxNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxName');
    });
  }

  QueryBuilder<BusinessConfig, double, QQueryOperations> taxRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxRate');
    });
  }

  QueryBuilder<BusinessConfig, bool, QQueryOperations>
      trackInventoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackInventory');
    });
  }

  QueryBuilder<BusinessConfig, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<BusinessConfig, bool, QQueryOperations>
      usePredefinedTicketsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usePredefinedTickets');
    });
  }
}
