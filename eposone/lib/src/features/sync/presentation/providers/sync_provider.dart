import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/features/platform/domain/en1_bootstrap_models.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_page_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/category_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_operation.dart';

final syncPendingCountProvider = FutureProvider<int>((ref) async {
  if (ref.watch(businessConfigProvider)?.isEn1SyncReady != true) return 0;
  // Limpia Sale/Cliente/Caja sin contrato antes de contar (evita badge fantasma).
  final repo = ref.watch(syncRepositoryProvider);
  await repo.discardSalePushOps();
  return repo.countPending();
});

final syncOperationsProvider = FutureProvider<List<SyncOperation>>((ref) async {
  return ref.watch(syncRepositoryProvider).getRecent();
});

final syncLatestErrorProvider = FutureProvider<String?>((ref) async {
  if (ref.watch(businessConfigProvider)?.isEn1SyncReady != true) return null;
  return ref.watch(syncRepositoryProvider).latestQueueError();
});

final syncRunningProvider = StateProvider<bool>((ref) => false);

final runSyncCycleProvider =
    Provider<Future<SyncRunResult> Function({En1BootstrapProgressCallback? onProgress})>((ref) {
  return ({En1BootstrapProgressCallback? onProgress}) async {
    if (ref.read(syncRunningProvider)) {
      throw StateError('Sincronización en curso');
    }
    ref.read(syncRunningProvider.notifier).state = true;
    try {
      final result = await ref.read(syncRepositoryProvider).runSyncCycle(
            onProgress: onProgress,
            ensureCatalogPull: false,
          );
      ref.invalidate(syncPendingCountProvider);
      ref.invalidate(syncOperationsProvider);
      ref.invalidate(syncLatestErrorProvider);
      ref.invalidate(businessConfigAsyncProvider);
      // Por si hubo pull de catálogo encolado antes: refrescar menú POS.
      ref.invalidate(productsListProvider);
      ref.invalidate(categoriesListProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(posPagesListProvider);
      return result;
    } finally {
      ref.read(syncRunningProvider.notifier).state = false;
    }
  };
});
