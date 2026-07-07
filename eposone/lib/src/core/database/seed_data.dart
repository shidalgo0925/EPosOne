import 'package:isar/isar.dart';
import 'package:eposone/src/core/database/istmo_catalog_images.dart';
import 'package:eposone/src/core/database/istmo_seed_data.dart';

/// Carga el catálogo Istmo (borra catálogo previo si existe).
Future<void> seedClientCatalog(Isar isar) => seedIstmoCatalog(isar);

/// Al abrir la app: migra demo/legacy → catálogo Istmo si hace falta.
Future<void> seedTestData(Isar isar) async {
  if (await needsIstmoCatalog(isar)) {
    await seedIstmoCatalog(isar);
    return;
  }
  if (await needsIstmoImages(isar)) {
    await attachIstmoProductImages(isar);
  }
}
