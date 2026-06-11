import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/presentation/providers/sales_provider.dart';

class SaleDetailScreen extends ConsumerWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(saleDetailProvider(saleId));

    ref.listen(salesNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ref.invalidate(saleDetailProvider(saleId));
          context.pop();
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Venta'),
        actions: [
          detailAsync.when(
            data: (detail) {
              final sale = detail['sale'] as Sale?;
              if (sale != null && sale.status == SaleStatus.completed) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'cancel') _confirmCancel(context, ref, sale);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Anular venta'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          final sale = detail['sale'] as Sale?;
          final items = detail['items'] as List<SaleItem>?;

          if (sale == null) {
            return const Center(child: Text('Venta no encontrada'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getStatusColor(sale.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getStatusColor(sale.status).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(sale.status),
                        size: 48,
                        color: _getStatusColor(sale.status),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusLabel(sale.status),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(sale.status),
                        ),
                      ),
                      if (sale.receiptNumber != null)
                        Text(
                          'Ticket: ${sale.receiptNumber}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Date & payment
                _InfoRow(label: 'Fecha', value: DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)),
                _InfoRow(label: 'Metodo de pago', value: _getPaymentLabel(sale.paymentMethod)),
                if (sale.cashierName != null)
                  _InfoRow(label: 'Cajero', value: sale.cashierName!),
                const Divider(height: 32),

                // Items
                Text('Productos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...?items?.map((item) => _SaleItemRow(item: item)),
                const Divider(height: 32),

                // Totals
                _TotalRow(label: 'Subtotal', value: sale.subtotal),
                if (sale.discount > 0)
                  _TotalRow(label: 'Descuento', value: -sale.discount, isDiscount: true),
                if (sale.taxAmount > 0)
                  _TotalRow(label: 'Impuestos', value: sale.taxAmount),
                _TotalRow(label: 'TOTAL', value: sale.total, isTotal: true),
                const SizedBox(height: 16),

                // Payment details
                if (sale.amountPaid > 0) ...[
                  _TotalRow(label: 'Monto pagado', value: sale.amountPaid),
                  if (sale.change > 0)
                    _TotalRow(label: 'Vuelto', value: sale.change, isDiscount: true),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular venta'),
        content: Text('¿Anular la venta ${sale.receiptNumber ?? sale.localId}?\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(salesNotifierProvider.notifier).cancelSale(sale.localId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed: return Colors.green;
      case SaleStatus.cancelled: return Colors.red;
      case SaleStatus.refunded: return Colors.orange;
    }
  }

  IconData _getStatusIcon(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed: return Icons.check_circle;
      case SaleStatus.cancelled: return Icons.cancel;
      case SaleStatus.refunded: return Icons.replay;
    }
  }

  String _getStatusLabel(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed: return 'Venta Completada';
      case SaleStatus.cancelled: return 'Venta Anulada';
      case SaleStatus.refunded: return 'Venta Reembolsada';
    }
  }

  String _getPaymentLabel(PaymentMethod method) => paymentMethodLabel(method);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SaleItemRow extends StatelessWidget {
  final SaleItem item;

  const _SaleItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (item.discount > 0)
                  Text(
                    '-\$${item.discount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isDiscount;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            '${isDiscount ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isDiscount ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}