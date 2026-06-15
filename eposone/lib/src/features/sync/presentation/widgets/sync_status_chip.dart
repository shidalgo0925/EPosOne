import 'package:flutter/material.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';

class SyncStatusChip extends StatelessWidget {
  final SyncOperationStatus status;

  const SyncStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        syncOperationStatusLabel(status),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }

  Color get _color => switch (status) {
        SyncOperationStatus.completed => Colors.green.shade700,
        SyncOperationStatus.pending || SyncOperationStatus.processing => EposBrand.orange,
        SyncOperationStatus.failed => Colors.red.shade700,
      };
}
