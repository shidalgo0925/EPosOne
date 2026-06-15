import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/pos/presentation/utils/pos_layout.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/presentation/providers/sales_provider.dart';
import 'package:eposone/src/features/sales/presentation/widgets/sale_detail_panel.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  final String? initialSaleId;

  const SalesHistoryScreen({super.key, this.initialSaleId});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedSaleId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSaleId = widget.initialSaleId;
  }

  @override
  void didUpdateWidget(SalesHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSaleId != oldWidget.initialSaleId) {
      _selectedSaleId = widget.initialSaleId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Sale> _filterSales(List<Sale> sales) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return sales;
    return sales.where((s) {
      final receipt = s.receiptNumber?.toLowerCase() ?? '';
      final cashier = s.cashierName?.toLowerCase() ?? '';
      final id = s.localId.toLowerCase();
      final total = s.total.toStringAsFixed(2);
      final payment = paymentMethodLabel(s.paymentMethod).toLowerCase();
      return receipt.contains(q) ||
          cashier.contains(q) ||
          id.contains(q) ||
          total.contains(q) ||
          payment.contains(q);
    }).toList();
  }

  void _selectSale(Sale sale, {required bool isTablet}) {
    if (isTablet) {
      setState(() => _selectedSaleId = sale.localId);
      context.go('/sales/${sale.localId}');
    } else {
      context.push('/sales/${sale.localId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = PosLayout.isTablet(context);
    final symbol = ref.watch(businessConfigProvider)?.currencySymbol ?? 'B/.';
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
          if (_selectedSaleId != null) {
            ref.invalidate(saleDetailProvider(_selectedSaleId!));
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
        title: const Text('Recibos'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: _showDateFilter),
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
          final filtered = _filterSales(sales);

          if (sales.isEmpty) {
            return const _EmptySalesState();
          }

          if (filtered.isEmpty) {
            return Column(
              children: [
                _SearchBar(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const Expanded(
                  child: Center(child: Text('Sin resultados para la búsqueda')),
                ),
              ],
            );
          }

          final totalSales = filtered.fold<double>(0, (sum, s) => sum + s.total);
          final listPane = Column(
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  children: [
                    _SummaryChip(label: 'Ventas', value: '${filtered.length}', icon: Icons.receipt),
                    const SizedBox(width: 12),
                    _SummaryChip(
                      label: 'Total',
                      value: '$symbol${totalSales.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final sale = filtered[index];
                    final selected = _selectedSaleId == sale.localId;
                    return _SaleCard(
                      sale: sale,
                      symbol: symbol,
                      selected: isTablet && selected,
                      onTap: () => _selectSale(sale, isTablet: isTablet),
                    );
                  },
                ),
              ),
            ],
          );

          if (!isTablet) return listPane;

          return Row(
            children: [
              Expanded(flex: 4, child: listPane),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 6,
                child: _selectedSaleId == null
                    ? const _SelectSalePlaceholder()
                    : SaleDetailPanel(
                        key: ValueKey(_selectedSaleId),
                        saleId: _selectedSaleId!,
                        embedded: true,
                        onCancelSuccess: () => setState(() => _selectedSaleId = null),
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SearchBar(
        controller: controller,
        hintText: 'Buscar recibo, cajero, monto...',
        leading: const Icon(Icons.search),
        trailing: controller.text.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
              ]
            : null,
        onChanged: onChanged,
      ),
    );
  }
}

class _EmptySalesState extends StatelessWidget {
  const _EmptySalesState();

  @override
  Widget build(BuildContext context) {
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
}

class _SelectSalePlaceholder extends StatelessWidget {
  const _SelectSalePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 72, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'Selecciona un recibo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  final String symbol;
  final bool selected;
  final VoidCallback onTap;

  const _SaleCard({
    required this.sale,
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInactive = sale.status == SaleStatus.cancelled || sale.status == SaleStatus.refunded;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35)
          : isInactive
              ? Colors.grey.shade900
              : null,
      shape: selected
          ? RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(sale.status).withOpacity(0.2),
          child: Icon(_statusIcon(sale.status), color: _statusColor(sale.status), size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sale.receiptNumber ?? 'Venta #${sale.localId.substring(0, 8)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isInactive ? TextDecoration.lineThrough : null,
                  color: isInactive ? Colors.grey : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _paymentColor(sale.paymentMethod).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                paymentMethodLabel(sale.paymentMethod),
                style: TextStyle(
                  fontSize: 11,
                  color: _paymentColor(sale.paymentMethod),
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
            if (sale.cashierName != null)
              Text(sale.cashierName!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: Text(
          '$symbol${sale.total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isInactive ? Colors.grey : Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: onTap,
      ),
    );
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

Color _paymentColor(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return Colors.green;
    case PaymentMethod.card:
      return Colors.blue;
    case PaymentMethod.transfer:
      return Colors.purple;
    case PaymentMethod.yappy:
      return Colors.orange;
    case PaymentMethod.other:
      return Colors.grey;
  }
}
