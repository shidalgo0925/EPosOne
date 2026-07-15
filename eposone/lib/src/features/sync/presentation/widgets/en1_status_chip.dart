import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/sync/presentation/providers/en1_connection_status.dart';

/// Indicador visible EN1 (Hito 3B.1).
class En1StatusChip extends ConsumerWidget {
  const En1StatusChip({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(en1StatusSnapshotProvider);
    return async.when(
      data: (s) {
        final (color, icon, label) = switch (s.link) {
          En1LinkState.connected => (
              Colors.green.shade700,
              Icons.cloud_done_outlined,
              'EN1 Conectado',
            ),
          En1LinkState.syncing => (
              EposBrand.orange,
              Icons.sync,
              'Sincronizando…',
            ),
          En1LinkState.offline || En1LinkState.unknown => (
              Colors.orange.shade800,
              Icons.cloud_off_outlined,
              s.pendingOrders > 0
                  ? 'Offline · ${s.pendingOrders} pend.'
                  : 'Offline',
            ),
        };
        final time = s.lastSyncAt == null
            ? null
            : DateFormat('HH:mm:ss').format(s.lastSyncAt!.toLocal());

        if (compact) {
          return Tooltip(
            message: [
              label,
              if (time != null) 'Última sync $time',
              if (s.pendingOrders > 0) '${s.pendingOrders} pendientes',
            ].join('\n'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(icon, size: 22, color: color),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  time == null ? label : '$label · $time',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
