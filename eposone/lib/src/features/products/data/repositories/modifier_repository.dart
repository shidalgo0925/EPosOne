import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/products/domain/entities/modifier.dart';
import 'package:eposone/src/features/products/domain/entities/modifier_group.dart';
import 'package:eposone/src/features/products/domain/entities/product_modifier_link.dart';

part 'modifier_repository.g.dart';

typedef ModifierGroupWithOptions = ({ModifierGroup group, List<Modifier> options});

@riverpod
ModifierRepository modifierRepository(ModifierRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return ModifierRepository(db);
}

class ModifierRepository {
  final Isar _isar;
  ModifierRepository(this._isar);

  Future<List<ModifierGroup>> getAllGroups() async {
    final groups = await _isar.modifierGroups.filter().isDeletedEqualTo(false).findAll();
    groups.sort((a, b) {
      final o = a.sortOrder.compareTo(b.sortOrder);
      return o != 0 ? o : a.name.compareTo(b.name);
    });
    return groups;
  }

  Future<ModifierGroup?> getGroupById(String localId) async {
    return _isar.modifierGroups.filter().localIdEqualTo(localId).findFirst();
  }

  Future<List<Modifier>> getModifiersForGroup(String groupId) async {
    final mods = await _isar.modifiers.filter().groupIdEqualTo(groupId).isDeletedEqualTo(false).findAll();
    mods.sort((a, b) {
      final o = a.sortOrder.compareTo(b.sortOrder);
      return o != 0 ? o : a.name.compareTo(b.name);
    });
    return mods;
  }

  Future<List<ModifierGroupWithOptions>> getGroupsForProduct(String productId) async {
    final links = await _isar.productModifierLinks
        .filter()
        .productIdEqualTo(productId)
        .isDeletedEqualTo(false)
        .sortBySortOrder()
        .findAll();

    final result = <ModifierGroupWithOptions>[];
    for (final link in links) {
      final group = await getGroupById(link.groupId);
      if (group == null || group.isDeleted) continue;
      final options = await getModifiersForGroup(group.localId);
      if (options.isEmpty) continue;
      result.add((group: group, options: options));
    }
    return result;
  }

  Future<bool> productHasModifiers(String productId) async {
    final groups = await getGroupsForProduct(productId);
    return groups.isNotEmpty;
  }

  Future<void> saveGroup(ModifierGroup group) async {
    await _isar.writeTxn(() => _isar.modifierGroups.put(group));
  }

  Future<void> deleteGroup(String localId) async {
    final group = await getGroupById(localId);
    if (group == null) return;
    await _isar.writeTxn(() async {
      await _isar.modifierGroups.put(group.markAsDeleted());
      final mods = await getModifiersForGroup(localId);
      for (final m in mods) {
        await _isar.modifiers.put(m.markAsDeleted());
      }
      final links = await _isar.productModifierLinks.filter().groupIdEqualTo(localId).findAll();
      for (final l in links) {
        await _isar.productModifierLinks.put(l.markAsDeleted());
      }
    });
  }

  Future<void> saveModifier(Modifier modifier) async {
    await _isar.writeTxn(() => _isar.modifiers.put(modifier));
  }

  Future<void> deleteModifier(String localId) async {
    final mod = await _isar.modifiers.filter().localIdEqualTo(localId).findFirst();
    if (mod != null) {
      await _isar.writeTxn(() => _isar.modifiers.put(mod.markAsDeleted()));
    }
  }

  Future<List<String>> getLinkedGroupIds(String productId) async {
    final links = await _isar.productModifierLinks
        .filter()
        .productIdEqualTo(productId)
        .isDeletedEqualTo(false)
        .findAll();
    return links.map((l) => l.groupId).toList();
  }

  Future<void> setProductGroups(String productId, List<String> groupIds) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.productModifierLinks.filter().productIdEqualTo(productId).findAll();
      for (final l in existing) {
        await _isar.productModifierLinks.put(l.markAsDeleted());
      }
      for (var i = 0; i < groupIds.length; i++) {
        await _isar.productModifierLinks.put(
          ProductModifierLink.create(productId: productId, groupId: groupIds[i], sortOrder: i),
        );
      }
    });
  }
}
