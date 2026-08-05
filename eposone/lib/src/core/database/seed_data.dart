import 'package:eposone/src/core/database/istmo_seed_data.dart';
import 'package:eposone/src/features/discount/data/discount_program_repository.dart';
import 'package:isar/isar.dart';

/// Carga manual del catálogo Istmo (solo para demos / desarrollo).
/// No se llama en instalación ni onboarding: el catálogo operativo viene de EN1.
Future<void> seedClientCatalog(Isar isar) => seedIstmoCatalog(isar);

/// Al abrir la app: sin catálogo de productos precargado.
/// Seeds SYSTEM del Discount Domain (idempotente).
Future<void> seedTestData(Isar isar) async {
  await DiscountProgramRepository(isar).ensureSystemSeeds();
}
