import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/printing/receipt_document_service.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/sales/presentation/providers/sales_provider.dart';

/// Detalle de venta reutilizable — pantalla completa o panel embebido (tablet).
class SaleDetailPanel extends ConsumerWidget {
  final String saleId;
  final bool embedded;
  final VoidCallback? onCancelSuccess;

  const SaleDetailPanel({
    super.key,
    required this.saleId,
    this.embedded = false,
    this.onCancelSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(saleDetailProvider(saleId));
    final symbol = ref.watch(businessConfigProvider)?.currencySymbol ?? 'B/.';

    ref.listen(salesNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        },
      );
    });

    return detailAsync.when(
      data: (detail) {
        final sale = detail['sale'] as Sale?;
        final items = detail['items'] as List<SaleItem>?;

        if (sale == null) {
          return const Center(child: Text('Venta no encontrada'));
        }

        final content = SingleChildScrollView(
          padding: EdgeInsets.all(embedded ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _statusColor(sale.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _statusColor(sale.status).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(_statusIcon(sale.status), size: embedded ? 40 : 48, color: _statusColor(sale.status)),
                    const SizedBox(height: 8),
                    Text(
                      _statusLabel(sale.status),
                      style: TextStyle(
                        fontSize: embedded ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(sale.status),
                      ),
                    ),
                    if (sale.receiptNumber != null)
                      Text('Ticket: ${sale.receiptNumber}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _InfoRow(label: 'Fecha', value: DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)),
              _InfoRow(label: 'Metodo de pago', value: paymentMethodLabel(sale.paymentMethod)),
                if (sale.cashierName != null) _InfoRow(label: 'Cajero', value: sale.cashierName!),
                if (sale.orderType != OrderType.generic)
                  _InfoRow(label: 'Tipo de orden', value: orderTypeLabel(sale.orderType)),
                if (sale.openTicketLabel != null)
                  _InfoRow(label: 'Ticket', value: sale.openTicketLabel!),
                const Divider(height: 32),
              Text('Productos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...?items?.map((item) => _SaleItemRow(item: item, symbol: symbol)),
              const Divider(height: 32),
              _TotalRow(label: 'Subtotal', value: sale.subtotal, symbol: symbol),
              if (sale.discount > 0)
                _TotalRow(label: 'Descuento', value: -sale.discount, symbol: symbol, isDiscount: true),
              if (sale.taxAmount > 0) _TotalRow(label: 'Impuestos', value: sale.taxAmount, symbol: symbol),
              if (sale.tipAmount > 0) _TotalRow(label: 'Propina', value: sale.tipAmount, symbol: symbol),
              _TotalRow(label: 'TOTAL', value: sale.total, symbol: symbol, isTotal: true),
              const SizedBox(height: 16),
              if (sale.amountPaid > 0) ...[
                _TotalRow(label: 'Monto pagado', value: sale.amountPaid, symbol: symbol),
                if (sale.change > 0)
                  _TotalRow(label: 'Vuelto', value: sale.change, symbol: symbol, isDiscount: true),
              ],
            ],
          ),
        );

        if (!embedded) return content;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text('Detalle', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  if (sale.status == SaleStatus.completed)
                    SaleDetailActionsMenu(
                      sale: sale,
                      saleId: saleId,
                      onCancelSuccess: onCancelSuccess,
                    ),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class SaleDetailActionsMenu extends ConsumerWidget {
  final Sale sale;
  final String saleId;
  final VoidCallback? onCancelSuccess;

  const SaleDetailActionsMenu({
    super.key,
    required this.sale,
    required this.saleId,
    this.onCancelSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'refund') {
          _confirmRefund(context, ref, sale);
        } else if (value == 'cancel') {
          _confirmCancel(context, ref, sale);
        } else if (value == 'print' || value == 'share') {
          final detail = await ref.read(saleDetailProvider(saleId).future);
          final items = detail['items'] as List<SaleItem>? ?? [];
          final config = ref.read(businessConfigProvider);
          final symbol = config?.currencySymbol ?? 'B/.';
          if (!context.mounted) return;
          if (value == 'print') {
            await ReceiptDocumentService.printSale(
              context: context,
              config: config,
              sale: sale,
              items: items,
              symbol: symbol,
            );
          } else {
            await ReceiptDocumentService.shareSalePdf(
              sale: sale,
              config: config,
              items: items,
              symbol: symbol,
            );
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print_outlined),
              SizedBox(width: 8),
              Text('Imprimir recibo'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined),
              SizedBox(width: 8),
              Text('Compartir PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'refund',
          child: Row(
            children: [
              Icon(Icons.replay, color: Colors.orange),
              SizedBox(width: 8),
              Text('Reembolsar'),
            ],
          ),
        ),
        PopupMenuItem(
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

  void _confirmRefund(BuildContext context, WidgetRef ref, Sale sale) {
    final trackInventory = ref.read(businessConfigProvider)?.trackInventory ?? true;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reembolsar venta'),
        content: Text(
          '¿Reembolsar la venta ${sale.receiptNumber ?? sale.localId}?'
          '${trackInventory ? '\nEl stock de los productos será restaurado.' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(salesNotifierProvider.notifier).refundSale(
                    sale.localId,
                    trackInventory: trackInventory,
                  );
              ref.invalidate(saleDetailProvider(saleId));
              ref.invalidate(salesHistoryProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Venta reembolsada')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reembolsar'),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, Sale sale) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anular venta'),
        content: Text(
          '¿Anular la venta ${sale.receiptNumber ?? sale.localId}?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(salesNotifierProvider.notifier).cancelSale(sale.localId);
              ref.invalidate(salesHistoryProvider);
              if (context.mounted) {
                onCancelSuccess?.call();
                if (onCancelSuccess == null) context.pop();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(SaleStatus status) {
  switch (status) {
    case SaleStatus.completed:
      return Colors.green;
    case SaleStatus.cancelled:
      return Colors.red;
    case SaleStatus.refunded:
      return Colors.orange;
  }
}

IconData _statusIcon(SaleStatus status) {
  switch (status) {
    case SaleStatus.completed:
      return Icons.check_circle;
    case SaleStatus.cancelled:
      return Icons.cancel;
    case SaleStatus.refunded:
      return Icons.replay;
  }
}

String _statusLabel(SaleStatus status) {
  switch (status) {
    case SaleStatus.completed:
      return 'Venta Completada';
    case SaleStatus.cancelled:
      return 'Venta Anulada';
    case SaleStatus.refunded:
      return 'Venta Reembolsada';
  }
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
  final String symbol;

  const _SaleItemRow({required this.item, required this.symbol});

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
                  '${item.quantity} x $symbol${item.unitPrice.toStringAsFixed(2)}',
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
                  '$symbol${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (item.discount > 0)
                  Text(
                    '-$symbol${item.discount.toStringAsFixed(2)}',
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
  final String symbol;
  final bool isTotal;
  final bool isDiscount;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.symbol,
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
            '${isDiscount ? '-' : ''}$symbol${value.abs().toStringAsFixed(2)}',
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
