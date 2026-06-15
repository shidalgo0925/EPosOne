import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/pos/data/repositories/pos_page_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
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

final posPagesEnabledProvider = FutureProvider<bool>((ref) async {
  final pages = await ref.watch(posPagesListProvider.future);
  return pages.isNotEmpty;
});
