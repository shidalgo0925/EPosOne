import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/discount/data/discount_program_record.dart';
import 'package:eposone/src/features/discount/domain/discount_program.dart';
import 'package:eposone/src/features/discount/seed/system_discount_programs.dart';

final discountProgramRepositoryProvider =
    Provider<DiscountProgramRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return DiscountProgramRepository(db);
});

class DiscountProgramRepository {
  DiscountProgramRepository(this._isar);

  final Isar _isar;

  Future<List<DiscountProgram>> listAll() async {
    final rows = await _isar.discountProgramRecords
        .filter()
        .deletedAtIsNull()
        .findAll();
    rows.sort((a, b) => a.code.compareTo(b.code));
    return rows.map((r) => r.toDomain()).toList(growable: false);
  }

  Future<DiscountProgram?> getByCode(String code) async {
    final row = await _isar.discountProgramRecords
        .filter()
        .codeEqualTo(code)
        .deletedAtIsNull()
        .findFirst();
    return row?.toDomain();
  }

  Future<void> upsert(DiscountProgram program) async {
    final existing = await _isar.discountProgramRecords
        .filter()
        .codeEqualTo(program.code)
        .findFirst();
    final now = DateTime.now();
    final record = existing == null
        ? DiscountProgramRecord.fromDomain(program)
        : existing.copyWith(
            name: program.name,
            type: program.type.name,
            source: program.source.name,
            valueType: program.valueType.name,
            value: program.value,
            scope: program.scope.name,
            status: program.status.name,
            version: program.version,
            effectiveFrom: program.effectiveFrom,
            effectiveTo: program.effectiveTo,
            requiresAuthorization: program.requiresAuthorization,
            requiresCustomer: program.requiresCustomer,
            requiresDocumentCheck: program.requiresDocumentCheck,
            maxPercent: program.maxPercent,
            establishmentTypesCsv:
                program.establishmentTypes.map((e) => e.name).join(','),
            notes: program.notes,
            updatedAt: now,
          );
    await _isar.writeTxn(() async {
      await _isar.discountProgramRecords.put(record);
    });
  }

  Future<void> setActive(String code, bool active) async {
    final row = await _isar.discountProgramRecords
        .filter()
        .codeEqualTo(code)
        .findFirst();
    if (row == null) return;
    if (row.source == 'system' &&
        code.startsWith('LEGAL_') &&
        !active &&
        code == 'LEGAL_PENSIONER_RESTAURANT_PA') {
      // Allow deactivate for ops, but keep record.
    }
    await _isar.writeTxn(() async {
      await _isar.discountProgramRecords.put(
        row.copyWith(
          status: active ? 'active' : 'inactive',
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  /// Idempotent SYSTEM seed (does not overwrite LOCAL edits to non-system).
  Future<void> ensureSystemSeeds() async {
    for (final p in SystemDiscountPrograms.defaultCatalog()) {
      final existing = await _isar.discountProgramRecords
          .filter()
          .codeEqualTo(p.code)
          .findFirst();
      if (existing == null) {
        await upsert(p);
        continue;
      }
      if (existing.source != 'system') continue;
      // Refresh SYSTEM definition but preserve local active/inactive for fast-food seed.
      final keepStatus = existing.code == 'LEGAL_PENSIONER_FAST_FOOD_PA'
          ? existing.status
          : p.status.name;
      await _isar.writeTxn(() async {
        await _isar.discountProgramRecords.put(
          existing.copyWith(
            name: p.name,
            type: p.type.name,
            valueType: p.valueType.name,
            value: p.value,
            scope: p.scope.name,
            status: keepStatus,
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
            updatedAt: DateTime.now(),
          ),
        );
      });
    }
  }
}
