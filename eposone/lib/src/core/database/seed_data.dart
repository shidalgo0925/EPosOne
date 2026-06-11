import 'package:isar/isar.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';

/// Inserta datos de prueba para una tienda de comida rápida
Future<void> seedTestData(Isar isar) async {
  await isar.writeTxn(() async {
    // 1. Configuración del negocio
    final existingConfig = await isar.businessConfigs.get(1);
    if (existingConfig == null) {
      final config = BusinessConfig(
        localId: 'business_config_001',
        businessName: 'Burger Express',
        address: 'Vía España, Panamá',
        phone: '6000-1234',
        email: 'info@burgerexpress.com',
        currency: 'PAB',
        currencySymbol: 'B/.',
        taxRate: 7.0,
        taxName: 'ITBMS',
        taxIncluded: false,
        receiptHeader: '*** Burger Express ***\nVía España, Panamá\nTel: 6000-1234',
        receiptFooter: 'Gracias por su compra\nVuelva pronto',
        receiptPrefix: 'BE',
        receiptNextNumber: 1,
        allowDecimalQty: false,
        trackInventory: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await isar.businessConfigs.put(config);
    }

    // 2. Categoría (crear si no existe)
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

    // 3. Productos (4 productos de comida rápida) - insertar si no existen
    final existingProducts = await isar.products.where().findAll();
    if (existingProducts.isEmpty) {
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
    }

    // 4. Cliente genérico (para ventas sin cliente registrado)
    final customers = await isar.customers.where().findAll();
    if (customers.isEmpty) {
      final customer = Customer.create(
        name: 'Cliente Ocasional',
        phone: '',
        document: '',
      );
      await isar.customers.put(customer);
    }

    // 5. Caja inicial (abierta con $100.00)
    final registers = await isar.cashRegisters.where().findAll();
    if (registers.isEmpty) {
      final register = CashRegister.create(
        openingAmount: 100.00,
        openedBy: 'Administrador',
        notes: 'Apertura inicial con datos de prueba',
      );
      await isar.cashRegisters.put(register);
    }
  });
}