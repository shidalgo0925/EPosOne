import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/fiscal/data/repositories/fiscal_repository.dart';
import 'package:eposone/src/features/fiscal/domain/entities/fiscal_document.dart';
import 'package:eposone/src/features/fiscal/presentation/providers/fiscal_provider.dart';
import 'package:eposone/src/features/fiscal/presentation/widgets/fiscal_status_chip.dart';

class FiscalDocumentSection extends ConsumerWidget {
  final String saleId;

  const FiscalDocumentSection({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(businessConfigProvider);
    if (config?.fiscalInvoicingEnabled != true) {
      return const SizedBox.shrink();
    }

    final invoiceAsync = ref.watch(fiscalDocumentForSaleProvider(saleId));
    final creditAsync = ref.watch(fiscalCreditNoteForSaleProvider(saleId));

    return invoiceAsync.when(
      data: (invoice) {
        return creditAsync.when(
          data: (credit) {
            if (invoice == null && credit == null) {
              return const _FiscalCard(
                child: Text('FE pendiente de emisión', style: TextStyle(color: EposBrand.textSecondary)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (invoice != null) _DocTile(doc: invoice, saleId: saleId),
                if (credit != null) ...[
                  const SizedBox(height: 8),
                  _DocTile(doc: credit, saleId: saleId),
                ],
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (e, _) => _FiscalCard(child: Text('Error FE: $e', style: const TextStyle(color: Colors.red))),
    );
  }
}

class _DocTile extends ConsumerWidget {
  final FiscalDocument doc;
  final String saleId;

  const _DocTile({required this.doc, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRetry = doc.status == FiscalDocumentStatus.error || doc.status == FiscalDocumentStatus.rejected;

    return _FiscalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fiscalDocumentTypeLabel(doc.documentType),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: EposBrand.navy),
                ),
              ),
              FiscalStatusChip(status: doc.status),
            ],
          ),
          const SizedBox(height: 8),
          Text('N° ${doc.fiscalNumber}', style: const TextStyle(fontSize: 13)),
          if (doc.cufe != null) ...[
            const SizedBox(height: 4),
            SelectableText('CUFE: ${doc.cufe}', style: const TextStyle(fontSize: 11, color: EposBrand.textSecondary)),
          ],
          if (doc.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(doc.errorMessage!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
          ],
          if (canRetry) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(fiscalRepositoryProvider).retryEmission(doc.localId);
                    ref.invalidate(fiscalDocumentForSaleProvider(saleId));
                    ref.invalidate(fiscalCreditNoteForSaleProvider(saleId));
                    ref.invalidate(fiscalDocumentsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reintento enviado')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FiscalCard extends StatelessWidget {
  final Widget child;

  const _FiscalCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EposBrand.navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EposBrand.navy.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}
