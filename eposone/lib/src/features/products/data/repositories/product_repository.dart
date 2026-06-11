import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';

part 'product_repository.g.dart';

@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return ProductRepository(db);
}

class ProductRepository {
  final Isar _isar;
  ProductRepository(this._isar);

  // Productos
  Future<List<Product>> getAllProducts({bool includeInactive = false}) async {
    return _isar.products
        .filter()
        .isDeletedEqualTo(false)
        .optional(includeInactive == false, (q) => q.isActiveEqualTo(true))
        .sortByName()
        .findAll();
  }

  Future<Product?> getProductById(String localId) async {
    return _isar.products.filter().localIdEqualTo(localId).findFirst();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    return _isar.products
        .filter()
        .barcodeEqualTo(barcode)
        .isDeletedEqualTo(false)
        .findFirst();
  }

  Future<List<Product>> searchProducts(String query) async {
    return _isar.products
        .filter()
        .isDeletedEqualTo(false)
        .isActiveEqualTo(true)
        .group((q) => q
            .nameContains(query, caseSensitive: false)
            .or()
            .barcodeContains(query, caseSensitive: false)
            .or()
            .skuContains(query, caseSensitive: false))
        .sortByName()
        .findAll();
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    return _isar.products
        .filter()
        .categoryIdEqualTo(categoryId)
        .isDeletedEqualTo(false)
        .isActiveEqualTo(true)
        .sortByName()
        .findAll();
  }

  Future<void> saveProduct(Product product) => _isar.writeTxn(() => _isar.products.put(product));

  Future<void> deleteProduct(String localId) async {
    final product = await getProductById(localId);
    if (product != null) {
      await _isar.writeTxn(() => _isar.products.put(product.markAsDeleted()));
    }
  }

  Future<void> updateStock(String localId, double delta) async {
    final product = await getProductById(localId);
    if (product != null) {
      final newStock = (product.stock + delta).clamp(0, double.infinity).toDouble();
      await saveProduct(product.copyWith(stock: newStock));
    }
  }

  // Categorías
  Future<List<Category>> getAllCategories() async {
    return _isar.categorys.filter().isDeletedEqualTo(false).sortByName().findAll();
  }

  Future<Category?> getCategoryById(String localId) async {
    return _isar.categorys.filter().localIdEqualTo(localId).findFirst();
  }

  Future<void> saveCategory(Category category) => _isar.writeTxn(() => _isar.categorys.put(category));

  Future<void> deleteCategory(String localId) async {
    final cat = await getCategoryById(localId);
    if (cat != null) {
      await _isar.writeTxn(() => _isar.categorys.put(cat.markAsDeleted()));
    }
  }
}