import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/inventory/domain/entities/stock_adjustment.dart';
import 'package:eposone/src/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:eposone/src/features/inventory/presentation/widgets/stock_adjust_sheet.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackInventory = ref.watch(businessConfigProvider)?.trackInventory ?? false;

    if (!trackInventory) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventario')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'El control de inventario está desactivado.\nActívalo en configuración del negocio.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventario'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bajo stock'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LowStockTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _LowStockTab extends ConsumerWidget {
  const _LowStockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowAsync = ref.watch(lowStockProductsProvider);

    return lowAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                SizedBox(height: 12),
                Text('Todo el stock está dentro del mínimo'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _LowStockTile(product: products[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _LowStockTile extends ConsumerWidget {
  final Product product;
  const _LowStockTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final min = product.minStockAlert ?? 0;
    final stockLabel = product.stock % 1 == 0 ? product.stock.toStringAsFixed(0) : product.stock.toStringAsFixed(1);

    return Card(
      color: Colors.orange.withValues(alpha: 0.08),
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: EposBrand.orange),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Stock: $stockLabel · Mínimo: ${min.toStringAsFixed(0)}'),
        trailing: TextButton(
          onPressed: () => showStockAdjustSheet(context, ref, product),
          child: const Text('Ajustar'),
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(stockAdjustmentsHistoryProvider);
    final dateFmt = DateFormat('dd/MM HH:mm');

    return historyAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('Sin ajustes registrados', style: TextStyle(color: EposBrand.textSecondary)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final adj = items[i];
            final deltaSign = adj.delta >= 0 ? '+' : '';
            final deltaColor = adj.delta >= 0 ? Colors.green : Colors.red;

            return ListTile(
              title: Text(adj.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${stockAdjustmentTypeLabel(adj.type)} · ${dateFmt.format(adj.adjustmentDate)}'
                '${adj.cashierName != null ? ' · ${adj.cashierName}' : ''}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$deltaSign${adj.delta % 1 == 0 ? adj.delta.toStringAsFixed(0) : adj.delta.toStringAsFixed(1)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: deltaColor),
                  ),
                  Text(
                    '→ ${adj.newStock % 1 == 0 ? adj.newStock.toStringAsFixed(0) : adj.newStock.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11, color: EposBrand.textSecondary),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
