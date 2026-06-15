import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_operation.dart';

final syncPendingCountProvider = FutureProvider<int>((ref) async {
  if (ref.watch(businessConfigProvider)?.isEn1SyncReady != true) return 0;
  return ref.watch(syncRepositoryProvider).countPending();
});

final syncOperationsProvider = FutureProvider<List<SyncOperation>>((ref) async {
  return ref.watch(syncRepositoryProvider).getRecent();
});

final syncRunningProvider = StateProvider<bool>((ref) => false);

final runSyncCycleProvider = Provider<Future<SyncRunResult> Function()>((ref) {
  return () async {
    if (ref.read(syncRunningProvider)) {
      throw StateError('Sincronización en curso');
    }
    ref.read(syncRunningProvider.notifier).state = true;
    try {
      final result = await ref.read(syncRepositoryProvider).runSyncCycle();
      ref.invalidate(syncPendingCountProvider);
      ref.invalidate(syncOperationsProvider);
      ref.invalidate(businessConfigAsyncProvider);
      return result;
    } finally {
      ref.read(syncRunningProvider.notifier).state = false;
    }
  };
});
