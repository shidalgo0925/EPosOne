import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:eposone/src/core/database/seed_data.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
class Database extends _$Database {
  Isar? _isar;

  @override
  Future<Isar> build() async {
    if (_isar != null && _isar!.isOpen) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        CategorySchema,
        ProductSchema,
        CustomerSchema,
        SaleSchema,
        SaleItemSchema,
        CashRegisterSchema,
        BusinessConfigSchema,
      ],
      directory: dir.path,
      inspector: true,
    );

    // Insertar datos de prueba si la base de datos está vacía
    await seedTestData(_isar!);

    return _isar!;
  }

  Isar get isar {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('Database not initialized. Call build() first.');
    }
    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}