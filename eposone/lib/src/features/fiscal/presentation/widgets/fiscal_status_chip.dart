import 'package:flutter/material.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/fiscal/domain/entities/fiscal_document.dart';

class FiscalStatusChip extends StatelessWidget {
  final FiscalDocumentStatus status;

  const FiscalStatusChip({super.key, required this.status});

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
        fiscalDocumentStatusLabel(status),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }

  Color get _color => switch (status) {
        FiscalDocumentStatus.accepted => Colors.green.shade700,
        FiscalDocumentStatus.pending || FiscalDocumentStatus.submitted => EposBrand.orange,
        FiscalDocumentStatus.rejected => Colors.red.shade700,
        FiscalDocumentStatus.error => Colors.red.shade900,
      };
}
