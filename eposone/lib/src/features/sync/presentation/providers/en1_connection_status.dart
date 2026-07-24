import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/time/en1_clock_guard.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/orders/presentation/providers/order_providers.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';

enum En1LinkState { unknown, connected, offline, syncing }

class En1StatusSnapshot {
  const En1StatusSnapshot({
    required this.link,
    required this.pendingOrders,
    this.lastSyncAt,
  });

  final En1LinkState link;
  final int pendingOrders;
  final DateTime? lastSyncAt;
}

final en1StatusSnapshotProvider = FutureProvider<En1StatusSnapshot>((ref) async {
  final config = ref.watch(businessConfigProvider);
  final running = ref.watch(syncRunningProvider);
  final dirty = await ref.watch(orderRepositoryProvider).countDirty();
  final pendingOps = await ref.watch(syncPendingCountProvider.future);
  final pending = dirty + pendingOps;

  if (running) {
    return En1StatusSnapshot(
      link: En1LinkState.syncing,
      pendingOrders: pending,
      lastSyncAt: config?.en1LastSyncAt,
    );
  }

  if (config?.isEn1SyncReady != true) {
    return En1StatusSnapshot(
      link: En1LinkState.offline,
      pendingOrders: pending,
      lastSyncAt: config?.en1LastSyncAt,
    );
  }

  final online = await _probeOnline(
    config?.en1ApiUrl ?? (await ProvisioningStore.loadConfig())?.apiBaseUrl,
  );
  return En1StatusSnapshot(
    link: online ? En1LinkState.connected : En1LinkState.offline,
    pendingOrders: pending,
    lastSyncAt: config?.en1LastSyncAt,
  );
});

/// Ciclo automático 30s — solo si hay dirty / pendientes.
final en1AutoSyncKeeperProvider = Provider<void>((ref) {
  Timer? timer;

  Future<void> tick() async {
    final config = ref.read(businessConfigProvider);
    if (config?.isEn1SyncReady != true) return;
    if (ref.read(syncRunningProvider)) return;

    final hasWork = await ref.read(orderServiceProvider).hasPendingWork();
    if (!hasWork) return;

    final online = await _probeOnline(
      config?.en1ApiUrl ?? (await ProvisioningStore.loadConfig())?.apiBaseUrl,
    );
    if (!online) return;

    try {
      ref.read(syncRunningProvider.notifier).state = true;
      await ref.read(orderServiceProvider).flushPendingToEn1(config: config);
      unawaited(En1ClockGuard.checkQuiet(apiBaseUrl: config?.en1ApiUrl));
      try {
        final cfg = await ref.read(businessConfigRepositoryProvider).getConfig();
        await ref.read(businessConfigRepositoryProvider).saveConfig(
              cfg.copyWith(en1LastSyncAt: En1DateTimeService.nowUtc()).markAsModified(),
            );
      } catch (_) {}
      ref.invalidate(syncPendingCountProvider);
      ref.invalidate(syncOperationsProvider);
      ref.invalidate(localOrdersProvider);
      ref.invalidate(openTicketsListProvider);
      ref.invalidate(openTicketsCountProvider);
      ref.invalidate(en1StatusSnapshotProvider);
      ref.invalidate(businessConfigAsyncProvider);
    } catch (_) {
      // Offline-first: reintento en el próximo ciclo.
    } finally {
      ref.read(syncRunningProvider.notifier).state = false;
    }
  }

  timer = Timer.periodic(const Duration(seconds: 30), (_) => tick());
  // Primer chequeo breve al entrar al POS.
  Future<void>.delayed(const Duration(seconds: 2), tick);
  ref.onDispose(() => timer?.cancel());
});

Future<bool> _probeOnline(String? baseUrl) async {
  final base = (baseUrl ?? '').trim();
  if (base.isEmpty) return false;
  final client = HttpClient();
  try {
    var uri = Uri.parse(base.endsWith('/') ? base.substring(0, base.length - 1) : base);
    if (!uri.hasScheme) uri = Uri.parse('https://$base');
    final req = await client.headUrl(uri).timeout(const Duration(seconds: 3));
    final res = await req.close().timeout(const Duration(seconds: 3));
    final dateHeader = res.headers.value(HttpHeaders.dateHeader);
    await res.drain<void>();
    if (dateHeader != null) {
      unawaited(En1DateTimeService.applyServerDateHeader(dateHeader));
    }
    return res.statusCode < 500;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
