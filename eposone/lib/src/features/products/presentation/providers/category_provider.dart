import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/products/data/repositories/product_repository.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';

/// Provider de lista de categorías
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final isar = await ref.read(databaseProvider.future);
  final repo = ProductRepository(isar);
  return repo.getAllCategories();
});

/// Notifier para operaciones de categoría
class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repo;
  CategoryNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> saveCategory(Category category) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveCategory(category);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCategory(String localId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteCategory(localId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  // Necesitamos esperar a que la DB esté lista
  return dbAsync.when(
    data: (isar) => CategoryNotifier(ProductRepository(isar)),
    loading: () => throw StateError('Database not initialized'),
    error: (e, _) => throw StateError('Database error: $e'),
  );
});