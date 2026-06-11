import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/presentation/providers/sales_provider.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    final salesAsync = (_fromDate != null && _toDate != null)
        ? ref.watch(salesByDateProvider((from: _fromDate!, to: _toDate!)))
        : ref.watch(salesHistoryProvider);

    ref.listen(salesNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ref.invalidate(salesHistoryProvider);
          if (_fromDate != null && _toDate != null) {
            ref.invalidate(salesByDateProvider((from: _fromDate!, to: _toDate!)));
          }
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
        title: const Text('Historial de Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDateFilter,
          ),
          if (_fromDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _fromDate = null;
                _toDate = null;
              }),
            ),
        ],
      ),
      body: salesAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Sin ventas registradas'),
                ],
              ),
            );
          }

          // Calculate totals
          final totalSales = sales.fold<double>(0, (sum, s) => sum + s.total);
          final totalCount = sales.length;

          return Column(
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  children: [
                    _SummaryChip(
                      label: 'Ventas',
                      value: '$totalCount',
                      icon: Icons.receipt,
                    ),
                    const SizedBox(width: 12),
                    _SummaryChip(
                      label: 'Total',
                      value: '\$${totalSales.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return _SaleCard(
                      sale: sale,
                      onTap: () => context.push('/sales/${sale.localId}'),
                    );
                  },
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

  void _showDateFilter() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback onTap;

  const _SaleCard({required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCancelled = sale.status == SaleStatus.cancelled;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      color: isCancelled ? Colors.grey.shade900 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(sale.status).withOpacity(0.2),
          child: Icon(
            _getStatusIcon(sale.status),
            color: _getStatusColor(sale.status),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sale.receiptNumber ?? 'Venta #${sale.localId.substring(0, 8)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                  color: isCancelled ? Colors.grey : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getPaymentColor(sale.paymentMethod).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getPaymentLabel(sale.paymentMethod),
                style: TextStyle(
                  fontSize: 11,
                  color: _getPaymentColor(sale.paymentMethod),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate),
              style: const TextStyle(fontSize: 12),
            ),
            if (sale.customerId != null)
              const Text('Cliente asignado', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: Text(
          '\$${sale.total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isCancelled ? Colors.grey : Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: onTap,
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

  Color _getPaymentColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Colors.green;
      case PaymentMethod.card: return Colors.blue;
      case PaymentMethod.transfer: return Colors.purple;
    }
  }

  String _getPaymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return 'Efectivo';
      case PaymentMethod.card: return 'Tarjeta';
      case PaymentMethod.transfer: return 'Transfer';
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}