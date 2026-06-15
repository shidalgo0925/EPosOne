import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/products/data/repositories/modifier_repository.dart';
import 'package:eposone/src/features/products/domain/entities/modifier_group.dart';

final modifierGroupsListProvider = FutureProvider<List<ModifierGroup>>((ref) async {
  final repo = ref.watch(modifierRepositoryProvider);
  return repo.getAllGroups();
});

final productModifierGroupsProvider = FutureProvider.family<List<ModifierGroupWithOptions>, String>((ref, productId) async {
  final repo = ref.watch(modifierRepositoryProvider);
  return repo.getGroupsForProduct(productId);
});

final productHasModifiersProvider = FutureProvider.family<bool, String>((ref, productId) async {
  final repo = ref.watch(modifierRepositoryProvider);
  return repo.productHasModifiers(productId);
});
