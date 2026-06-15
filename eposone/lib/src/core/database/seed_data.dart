import 'package:isar/isar.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/domain/entities/modifier_group.dart';
import 'package:eposone/src/features/products/domain/entities/modifier.dart';
import 'package:eposone/src/features/products/domain/entities/product_modifier_link.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page_item.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/premium/domain/entities/coupon.dart';

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

    await _seedDemoModifiers(isar, products.first.localId);
    await _seedDemoPosPages(isar, category.localId);

    final customers = await isar.customers.where().findAll();
    if (customers.isEmpty) {
      await isar.customers.put(Customer.create(name: 'Cliente Ocasional', phone: '', document: ''));
    }

    final coupons = await isar.coupons.where().findAll();
    if (coupons.isEmpty) {
      await isar.coupons.put(
        Coupon.create(
          code: 'WELCOME10',
          description: '10% de bienvenida',
          discountType: CouponDiscountType.percent,
          value: 10,
        ),
      );
    }
  });
}

Future<void> _seedDemoModifiers(Isar isar, String hamburgerProductId) async {
  final existing = await isar.modifierGroups.where().findAll();
  if (existing.isNotEmpty) return;

  final extras = ModifierGroup.create(name: 'Extras', minSelect: 0, maxSelect: 99);
  await isar.modifierGroups.put(extras);

  final extrasOptions = [
    Modifier.create(groupId: extras.localId, name: 'Extra queso', priceDelta: 0.75),
    Modifier.create(groupId: extras.localId, name: 'Extra bacon', priceDelta: 1.00),
    Modifier.create(groupId: extras.localId, name: 'Sin cebolla', priceDelta: 0),
  ];
  for (final m in extrasOptions) {
    await isar.modifiers.put(m);
  }

  await isar.productModifierLinks.put(
    ProductModifierLink.create(productId: hamburgerProductId, groupId: extras.localId),
  );
}

Future<void> _seedDemoPosPages(Isar isar, String categoryId) async {
  final existing = await isar.posPages.where().findAll();
  if (existing.isNotEmpty) return;

  final pageAll = PosPage.create(name: 'Principal', sortOrder: 0);
  final pageCat = PosPage.create(name: 'Combos', sortOrder: 1);
  await isar.posPages.put(pageAll);
  await isar.posPages.put(pageCat);

  await isar.posPageItems.put(
    PosPageItem.create(
      pageId: pageCat.localId,
      itemType: PosPageItemType.category,
      refId: categoryId,
    ),
  );
}

/// Ya no inserta config ni caja; eso lo hace el onboarding.
Future<void> seedTestData(Isar isar) async {
  // Mantener vacío para flujo POS real.
}
