import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/printing/receipt_document_service.dart';
import 'package:eposone/src/core/printing/receipt_text_builder.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/core/widgets/business_logo_header.dart';
import 'package:eposone/src/features/customers/presentation/providers/customer_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/sales/presentation/providers/sales_provider.dart';

void _confirmRefund(BuildContext context, WidgetRef ref, Sale sale) {
  final trackInventory = ref.read(businessConfigProvider)?.trackInventory ?? true;
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reembolsar venta'),
      content: Text(
        '¿Reembolsar esta venta?'
        '${trackInventory ? '\nEl stock de los productos será restaurado.' : ''}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            await ref.read(salesNotifierProvider.notifier).refundSale(
                  sale.localId,
                  trackInventory: trackInventory,
                );
            ref.invalidate(saleDetailProvider(sale.localId));
            ref.invalidate(salesHistoryProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Venta reembolsada')),
              );
              context.go('/pos');
            }
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Reembolsar'),
        ),
      ],
    ),
  );
}

Future<({String? name, String? document})> _customerFields(
  WidgetRef ref,
  Sale sale,
) async {
  if (sale.customerId == null) return (name: null, document: null);
  final c = await ref.read(customerByIdProvider(sale.customerId!).future);
  return (name: c?.name, document: c?.document);
}

/// Pantalla post-cobro: auto-imprime el recibo una vez (como precuenta al pedir).
class ReceiptScreen extends ConsumerStatefulWidget {
  final String saleId;
  const ReceiptScreen({super.key, required this.saleId});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _autoPrinted = false;

  Future<void> _autoPrintIfNeeded(Sale sale, List<SaleItem> items) async {
    if (_autoPrinted) return;
    _autoPrinted = true;
    final config = ref.read(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';
    final c = await _customerFields(ref, sale);
    if (!mounted) return;
    await ReceiptDocumentService.printSale(
      context: context,
      config: config,
      sale: sale,
      items: items,
      symbol: symbol,
      customerName: c.name,
      customerDocument: c.document,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(saleDetailProvider(widget.saleId));
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/pos');
            }
          },
        ),
        title: const Text('Recibo'),
      ),
      body: detailAsync.when(
        data: (detail) {
          final sale = detail['sale'] as Sale?;
          final items = detail['items'] as List<SaleItem>? ?? [];
          if (sale == null) {
            return const Center(child: Text('Venta no encontrada'));
          }

          // Auto-impresión al llegar tras cobrar (una sola vez).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoPrintIfNeeded(sale, items);
          });

          final previewLines = ReceiptTextBuilder.buildSaleReceipt(
            config: config,
            sale: sale,
            items: items,
            symbol: symbol,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle,
                          size: 56, color: Colors.green.shade400),
                      const SizedBox(height: 8),
                      const Text('¡Venta completada!',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BusinessLogoHeader(logoPath: config?.logoPath),
                            for (final line in previewLines)
                              if (line.trim().isNotEmpty)
                                Text(
                                  line,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    height: 1.25,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, ViewInsets.bottom(context)),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/pos'),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Nueva venta'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final c = await _customerFields(ref, sale);
                              if (!context.mounted) return;
                              await ReceiptDocumentService.printSale(
                                context: context,
                                config: config,
                                sale: sale,
                                items: items,
                                symbol: symbol,
                                customerName: c.name,
                                customerDocument: c.document,
                              );
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Reimprimir'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final c = await _customerFields(ref, sale);
                              await ReceiptDocumentService.shareSalePdf(
                                sale: sale,
                                config: config,
                                items: items,
                                symbol: symbol,
                                customerName: c.name,
                                customerDocument: c.document,
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir'),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () =>
                          context.go('/sales?id=${sale.localId}'),
                      child: const Text('Ver historial'),
                    ),
                    if (sale.status == SaleStatus.completed)
                      TextButton.icon(
                        onPressed: () => _confirmRefund(context, ref, sale),
                        icon: const Icon(Icons.replay, color: Colors.orange),
                        label: const Text('Reembolsar',
                            style: TextStyle(color: Colors.orange)),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
