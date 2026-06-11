import 'package:isar/isar.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';

/// Datos demo de productos (después del onboarding o para pruebas).
Future<void> seedDemoProducts(Isar isar) async {
  await isar.writeTxn(() async {
    final categories = await isar.categorys.where().findAll();
    late final Category category;
    if (categories.isEmpty) {
      category = Category.create(
        name: 'Combos y Acompañamientos',
        color: '#FF6B35',
        icon: 'fastfood',
      );
      await isar.categorys.put(category);
    } else {
      category = categories.first;
    }

    final existingProducts = await isar.products.where().findAll();
    if (existingProducts.isNotEmpty) return;

    final products = [
      Product.create(
        name: 'Hamburguesa Clásica',
        description: 'Carne 150g, lechuga, tomate, cebolla, salsa especial',
        price: 5.50,
        cost: 2.80,
        sku: 'HAM-001',
        barcode: '123456789001',
        categoryId: category.localId,
        stock: 100,
        minStockAlert: 10,
      ),
      Product.create(
        name: 'Hot Dog Sencillo',
        description: 'Salchicha 100g, pan artesanal, cebolla, mostaza, kétchup',
        price: 3.00,
        cost: 1.40,
        sku: 'HOT-001',
        barcode: '123456789002',
        categoryId: category.localId,
        stock: 150,
        minStockAlert: 15,
      ),
      Product.create(
        name: 'Papas Fritas Medianas',
        description: 'Papas fritas crujientes con sal',
        price: 2.50,
        cost: 0.80,
        sku: 'PAP-001',
        barcode: '123456789003',
        categoryId: category.localId,
        stock: 80,
        minStockAlert: 10,
      ),
      Product.create(
        name: 'Refresco 12oz',
        description: 'Bebida gaseosa o natural 12 onzas',
        price: 1.50,
        cost: 0.60,
        sku: 'REF-001',
        barcode: '123456789004',
        categoryId: category.localId,
        stock: 200,
        minStockAlert: 20,
      ),
    ];

    for (final product in products) {
      await isar.products.put(product);
    }

    final customers = await isar.customers.where().findAll();
    if (customers.isEmpty) {
      await isar.customers.put(Customer.create(name: 'Cliente Ocasional', phone: '', document: ''));
    }
  });
}

/// Ya no inserta config ni caja; eso lo hace el onboarding.
Future<void> seedTestData(Isar isar) async {
  // Mantener vacío para flujo POS real.
}
