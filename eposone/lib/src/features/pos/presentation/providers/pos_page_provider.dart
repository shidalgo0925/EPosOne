import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/pos/data/repositories/pos_page_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page_item.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/presentation/providers/category_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';

final posPagesListProvider = FutureProvider<List<PosPage>>((ref) async {
  final repo = ref.watch(posPageRepositoryProvider);
  return repo.getActivePages();
});

final posPagesAdminProvider = FutureProvider<List<PosPage>>((ref) async {
  final repo = ref.watch(posPageRepositoryProvider);
  return repo.getAllPages();
});

final posPageProductsProvider = FutureProvider.family<List<Product>, String>((ref, pageId) async {
  final repo = ref.watch(posPageRepositoryProvider);
  final all = await ref.watch(productsListProvider.future);
  final active = all.where((p) => p.isActive).toList();
  return repo.resolveProductsForPage(pageId, active);
});

/// Categorías visibles en una página POS (orden del menú Comida/Bar).
final posPageCategoriesProvider = FutureProvider.family<List<Category>, String>((ref, pageId) async {
  final repo = ref.watch(posPageRepositoryProvider);
  final allCategories = await ref.watch(categoriesProvider.future);
  final byId = {for (final c in allCategories) c.localId: c};
  final items = await repo.getItems(pageId);

  return [
    for (final item in items)
      if (item.itemType == PosPageItemType.category && byId[item.refId] != null) byId[item.refId]!,
  ];
});

final posPagesEnabledProvider = FutureProvider<bool>((ref) async {
  final pages = await ref.watch(posPagesListProvider.future);
  return pages.isNotEmpty;
});
