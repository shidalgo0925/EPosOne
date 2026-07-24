import 'package:isar/isar.dart';
import 'package:eposone/src/core/database/istmo_seed_data.dart';

/// Carga manual del catálogo Istmo (solo para demos / desarrollo).
/// No se llama en instalación ni onboarding: el catálogo operativo viene de EN1.
Future<void> seedClientCatalog(Isar isar) => seedIstmoCatalog(isar);

/// Al abrir la app: sin catálogo precargado.
/// Productos, categorías y páginas Comida/Bar llegan con bootstrap EN1.
Future<void> seedTestData(Isar isar) async {
  // Intencionalmente vacío: instalación limpia.
}
