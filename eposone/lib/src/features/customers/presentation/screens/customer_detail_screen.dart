import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/customers/presentation/providers/customer_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/premium/presentation/providers/premium_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));
    final salesAsync = ref.watch(customerSalesProvider(customerId));
    final symbol = ref.watch(businessConfigProvider)?.currencySymbol ?? 'B/.';
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/customers/$customerId/edit'),
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Cliente no encontrado'));
          }

          return salesAsync.when(
            data: (summary) {
              final sales = summary.sales;
              final lifetime = summary.lifetimeTotal;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          if (customer.phone != null) Text(customer.phone!),
                          if (customer.document != null) Text('Doc: ${customer.document}'),
                          if (customer.email != null) Text(customer.email!),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatChip(label: 'Compras', value: '${sales.where((s) => s.status == SaleStatus.completed).length}'),
                              const SizedBox(width: 8),
                              _StatChip(label: 'Total', value: '$symbol${lifetime.toStringAsFixed(2)}'),
                              if (customer.loyaltyPoints > 0) ...[
                                const SizedBox(width: 8),
                                _StatChip(label: 'Puntos', value: '${customer.loyaltyPoints}'),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Historial de compras', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (sales.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Sin compras registradas', style: TextStyle(color: EposBrand.textSecondary))),
                    )
                  else
                    ...sales.map(
                      (sale) => Card(
                        child: ListTile(
                          title: Text(sale.receiptNumber ?? sale.localId, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${dateFmt.format(sale.saleDate)} · ${paymentMethodLabel(sale.paymentMethod)}'),
                          trailing: Text(
                            '$symbol${sale.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: EposBrand.navy),
                          ),
                          onTap: () => context.push('/sales/${sale.localId}'),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EposBrand.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: EposBrand.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
