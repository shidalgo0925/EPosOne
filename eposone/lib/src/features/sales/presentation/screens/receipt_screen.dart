import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/sales/presentation/providers/sales_provider.dart';

class ReceiptScreen extends ConsumerWidget {
  final String saleId;
  const ReceiptScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(saleDetailProvider(saleId));
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';

    return Scaffold(
      appBar: AppBar(title: const Text('Recibo')),
      body: detailAsync.when(
        data: (detail) {
          final sale = detail['sale'] as Sale?;
          final items = detail['items'] as List<SaleItem>? ?? [];
          if (sale == null) {
            return const Center(child: Text('Venta no encontrada'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 56, color: Colors.green.shade400),
                      const SizedBox(height: 8),
                      const Text('¡Venta completada!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(config?.businessName ?? 'EPOSOne',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            if (config?.address != null) Text(config!.address!, style: const TextStyle(color: Colors.grey)),
                            const Divider(height: 24),
                            if (sale.receiptNumber != null)
                              Text('Recibo: ${sale.receiptNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)),
                            if (sale.cashierName != null) Text('Cajero: ${sale.cashierName}'),
                            const Divider(height: 24),
                            ...items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text('${item.quantity.toStringAsFixed(item.quantity == item.quantity.toInt() ? 0 : 1)} x ${item.productName}'),
                                      ),
                                      Text('$symbol${(item.quantity * item.unitPrice).toStringAsFixed(2)}'),
                                    ],
                                  ),
                                )),
                            const Divider(height: 24),
                            _row('Subtotal', sale.subtotal, symbol),
                            if (sale.discount > 0) _row('Descuento', -sale.discount, symbol),
                            if (sale.taxAmount > 0) _row(config?.taxName ?? 'ITBMS', sale.taxAmount, symbol),
                            _row('TOTAL', sale.total, symbol, bold: true),
                            const SizedBox(height: 8),
                            _row('Pago', sale.amountPaid, symbol),
                            _row('Método', 0, symbol, text: paymentMethodLabel(sale.paymentMethod)),
                            if (sale.change > 0) _row('Vuelto', sale.change, symbol),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, ViewInsets.bottom(context)),
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
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Impresión: próximamente')),
                              );
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Imprimir'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Compartir: próximamente')),
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir'),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/sales/${sale.localId}'),
                      child: const Text('Ver historial'),
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

  Widget _row(String label, double value, String symbol, {bool bold = false, String? text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          Text(
            text ?? '$symbol${value.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, fontSize: bold ? 18 : 14),
          ),
        ],
      ),
    );
  }
}
