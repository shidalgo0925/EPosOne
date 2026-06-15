import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/inventory/data/repositories/stock_adjustment_repository.dart';
import 'package:eposone/src/features/inventory/domain/entities/stock_adjustment.dart';
import 'package:eposone/src/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';

Future<bool> showStockAdjustSheet(BuildContext context, WidgetRef ref, Product product) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => _StockAdjustSheet(product: product),
  );
  return result ?? false;
}

class _StockAdjustSheet extends ConsumerStatefulWidget {
  final Product product;
  const _StockAdjustSheet({required this.product});

  @override
  ConsumerState<_StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends ConsumerState<_StockAdjustSheet> {
  late final TextEditingController _stockCtrl;
  StockAdjustmentType _type = StockAdjustmentType.count;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stockCtrl = TextEditingController(
      text: widget.product.stock % 1 == 0
          ? widget.product.stock.toStringAsFixed(0)
          : widget.product.stock.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newStock = double.tryParse(_stockCtrl.text.replaceAll(',', '.'));
    if (newStock == null || newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indica un stock válido')));
      return;
    }

    setState(() => _saving = true);
    try {
      final session = ref.read(posSessionProvider);
      await ref.read(stockAdjustmentRepositoryProvider).adjustStock(
            productId: widget.product.localId,
            newStock: newStock,
            type: _type,
            cashierId: session?.cashierId,
            cashierName: session?.cashierName,
          );
      ref.invalidate(productsListProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(lowStockCountProvider);
      ref.invalidate(stockAdjustmentsHistoryProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: EposBrand.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Ajustar stock', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(widget.product.name, style: const TextStyle(color: EposBrand.textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Stock actual: ${widget.product.stock % 1 == 0 ? widget.product.stock.toStringAsFixed(0) : widget.product.stock.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stockCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nuevo stock',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<StockAdjustmentType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder()),
            items: StockAdjustmentType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(stockAdjustmentTypeLabel(t))))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar ajuste'),
          ),
        ],
      ),
    );
  }
}
