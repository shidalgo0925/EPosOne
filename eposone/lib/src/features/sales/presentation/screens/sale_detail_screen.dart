import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/presentation/providers/sales_provider.dart';
import 'package:eposone/src/features/sales/presentation/widgets/sale_detail_panel.dart';

class SaleDetailScreen extends ConsumerWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(saleDetailProvider(saleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Venta'),
        actions: [
          detailAsync.when(
            data: (detail) {
              final sale = detail['sale'] as Sale?;
              if (sale != null && sale.status == SaleStatus.completed) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SaleDetailActionsMenu(saleId: saleId, sale: sale),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SaleDetailPanel(saleId: saleId),
    );
  }
}
