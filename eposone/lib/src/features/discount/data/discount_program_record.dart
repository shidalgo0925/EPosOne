import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/discount/domain/discount_mappers.dart';
import 'package:eposone/src/features/discount/domain/discount_program.dart';

part 'discount_program_record.g.dart';

/// Persisted discount program catalog (ADR-015 Fase B).
@collection
class DiscountProgramRecord extends SyncEntity {
  Id get isarId => localId.hashCode;

  @Index(unique: true, replace: true)
  final String code;
  final String name;
  final String type;
  final String source;
  final String valueType;
  final int value;
  final String scope;
  final String status;
  final int version;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final bool requiresAuthorization;
  final bool requiresCustomer;
  final bool requiresDocumentCheck;
  final int? maxPercent;

  /// CSV of [DiscountEstablishmentClass] names; empty = all.
  final String establishmentTypesCsv;
  final String? notes;

  const DiscountProgramRecord({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
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
    this.establishmentTypesCsv = '',
    this.notes,
  });

  DiscountProgram toDomain() => DiscountProgramMapper.fromRecordFields(
        id: localId,
        code: code,
        name: name,
        type: type,
        source: source,
        valueType: valueType,
        value: value,
        scope: scope,
        status: status,
        version: version,
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
        requiresAuthorization: requiresAuthorization,
        requiresCustomer: requiresCustomer,
        requiresDocumentCheck: requiresDocumentCheck,
        maxPercent: maxPercent,
        establishmentTypesCsv: establishmentTypesCsv,
        notes: notes,
      );

  static DiscountProgramRecord fromDomain(DiscountProgram p) {
    final now = DateTime.now();
    return DiscountProgramRecord(
      localId: p.id,
      syncStatus: SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
      code: p.code,
      name: p.name,
      type: p.type.name,
      source: p.source.name,
      valueType: p.valueType.name,
      value: p.value,
      scope: p.scope.name,
      status: p.status.name,
      version: p.version,
      effectiveFrom: p.effectiveFrom,
      effectiveTo: p.effectiveTo,
      requiresAuthorization: p.requiresAuthorization,
      requiresCustomer: p.requiresCustomer,
      requiresDocumentCheck: p.requiresDocumentCheck,
      maxPercent: p.maxPercent,
      establishmentTypesCsv:
          p.establishmentTypes.map((e) => e.name).join(','),
      notes: p.notes,
    );
  }

  @override
  DiscountProgramRecord markAsModified() => copyWith(
        syncStatus: SyncStatus.modified,
        updatedAt: DateTime.now(),
      );

  @override
  DiscountProgramRecord markAsSynced(String serverId) => copyWith(
        serverId: serverId,
        syncStatus: SyncStatus.synced,
        updatedAt: DateTime.now(),
      );

  @override
  DiscountProgramRecord markAsDeleted() => copyWith(
        deletedAt: DateTime.now(),
        syncStatus: SyncStatus.modified,
        updatedAt: DateTime.now(),
      );

  DiscountProgramRecord copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? code,
    String? name,
    String? type,
    String? source,
    String? valueType,
    int? value,
    String? scope,
    String? status,
    int? version,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    bool? requiresAuthorization,
    bool? requiresCustomer,
    bool? requiresDocumentCheck,
    int? maxPercent,
    String? establishmentTypesCsv,
    String? notes,
  }) =>
      DiscountProgramRecord(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        code: code ?? this.code,
        name: name ?? this.name,
        type: type ?? this.type,
        source: source ?? this.source,
        valueType: valueType ?? this.valueType,
        value: value ?? this.value,
        scope: scope ?? this.scope,
        status: status ?? this.status,
        version: version ?? this.version,
        effectiveFrom: effectiveFrom ?? this.effectiveFrom,
        effectiveTo: effectiveTo ?? this.effectiveTo,
        requiresAuthorization:
            requiresAuthorization ?? this.requiresAuthorization,
        requiresCustomer: requiresCustomer ?? this.requiresCustomer,
        requiresDocumentCheck:
            requiresDocumentCheck ?? this.requiresDocumentCheck,
        maxPercent: maxPercent ?? this.maxPercent,
        establishmentTypesCsv:
            establishmentTypesCsv ?? this.establishmentTypesCsv,
        notes: notes ?? this.notes,
      );
}
