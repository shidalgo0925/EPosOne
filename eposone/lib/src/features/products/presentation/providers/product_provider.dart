import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/products/data/repositories/product_repository.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';

/// Provider del repositorio de productos
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (isar) => ProductRepository(isar),
    loading: () => throw StateError('Database not initialized'),
    error: (e, _) => throw StateError('Database error: $e'),
  );
});

/// Provider de lista de productos
final productsListProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getAllProducts();
});

/// Provider de búsqueda de productos
final productsSearchProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    final repo = ref.watch(productRepositoryProvider);
    return repo.getAllProducts();
  }
  final repo = ref.watch(productRepositoryProvider);
  return repo.searchProducts(query.trim());
});

/// Provider de producto por ID
final productByIdProvider = FutureProvider.family<Product?, String>((ref, localId) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProductById(localId);
});

/// Provider de categorías
final categoriesListProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getAllCategories();
});

/// Notifier para operaciones de producto
class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repo;
  ProductNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> saveProduct(Product product) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveProduct(product);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProduct(String localId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteProduct(localId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleActive(Product product) async {
    state = const AsyncValue.loading();
    try {
      final updated = product.copyWith(
        isActive: !product.isActive,
        updatedAt: DateTime.now(),
      ).markAsModified();
      await _repo.saveProduct(updated);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final productNotifierProvider = StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return ProductNotifier(repo);
});