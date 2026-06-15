import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/split_bill_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _amountController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  bool _processing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addCash(double amount) {
    final current = double.tryParse(_amountController.text) ?? 0;
    _amountController.text = (current + amount).toStringAsFixed(2);
    setState(() {});
  }

  void _setExact(double total) {
    _amountController.text = total.toStringAsFixed(2);
    setState(() {});
  }

  ({List<CartItem> items, SaleTotals totals, String? splitLabel, bool isSplit}) _paymentContext() {
    final cart = ref.read(cartProvider);
    final split = ref.read(splitBillProvider);
    final config = ref.read(businessConfigProvider);
    final taxRate = config?.taxRate ?? 0;
    final taxIncluded = config?.taxIncluded ?? false;

    if (split.mode == SplitMode.byItems && split.selectedItemIds.isNotEmpty) {
      final items = cart.items.where((i) => split.selectedItemIds.contains(i.id)).toList();
      return (
        items: items,
        totals: calculateTotalsForItems(items, cart, taxRate: taxRate, taxIncluded: taxIncluded),
        splitLabel: 'Cobro parcial (${items.length} ítems)',
        isSplit: true,
      );
    }

    if (split.isEqualSplit && split.equalSplitSnapshot != null) {
      final items = equalSplitPartItems(
        split.equalSplitSnapshot!,
        split.equalCurrentPart,
        split.equalTotalParts,
      );
      return (
        items: items,
        totals: calculateTotalsForItems(items, cart, taxRate: taxRate, taxIncluded: taxIncluded),
        splitLabel: 'Parte ${split.equalCurrentPart} de ${split.equalTotalParts}',
        isSplit: true,
      );
    }

    return (
      items: cart.items,
      totals: ref.read(saleTotalsProvider),
      splitLabel: null,
      isSplit: false,
    );
  }

  Future<void> _confirm() async {
    final ctx = _paymentContext();
    final total = ctx.totals.total;
    final split = ref.read(splitBillProvider);

    if (_method == PaymentMethod.cash) {
      final paid = double.tryParse(_amountController.text) ?? 0;
      if (paid < total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El monto recibido es menor al total')),
        );
        return;
      }
      ref.read(checkoutProvider.notifier)
        ..setPaymentMethod(_method)
        ..setAmountPaid(paid);
    } else {
      ref.read(checkoutProvider.notifier)
        ..setPaymentMethod(_method)
        ..setAmountPaid(total);
    }

    setState(() => _processing = true);
    try {
      String? notes;
      if (split.isEqualSplit) {
        notes = 'División ${split.equalCurrentPart}/${split.equalTotalParts}';
      } else if (split.mode == SplitMode.byItems) {
        notes = 'División por ítems';
      }

      final sale = await ref.read(completeSaleProvider)(
        itemsOverride: ctx.isSplit ? ctx.items : null,
        notes: notes,
      );

      if (sale == null || !mounted) return;

      final equalPartial = split.isEqualSplit && split.equalCurrentPart < split.equalTotalParts;
      final wasItemSplit = split.mode == SplitMode.byItems;

      if (equalPartial) {
        ref.read(splitBillProvider.notifier).advanceEqualPart();
        _amountController.clear();
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Parte ${split.equalCurrentPart} cobrada. Siguiente: parte ${split.equalCurrentPart + 1} de ${split.equalTotalParts}',
            ),
          ),
        );
        return;
      }

      ref.read(splitBillProvider.notifier).reset();

      final remaining = ref.read(cartProvider).items;
      if (remaining.isNotEmpty && wasItemSplit) {
        context.go('/pos');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cobro parcial completado. Quedan ítems en el ticket')),
        );
      } else {
        context.go('/receipt/${sale.localId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final split = ref.watch(splitBillProvider);
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';
    final taxRate = config?.taxRate ?? 0;
    final taxIncluded = config?.taxIncluded ?? false;

    if (cart.items.isEmpty && !split.isEqualSplit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pos');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<CartItem> paymentItems;
    SaleTotals totals;
    String? splitLabel;

    if (split.mode == SplitMode.byItems && split.selectedItemIds.isNotEmpty) {
      paymentItems = cart.items.where((i) => split.selectedItemIds.contains(i.id)).toList();
      totals = calculateTotalsForItems(paymentItems, cart, taxRate: taxRate, taxIncluded: taxIncluded);
      splitLabel = 'Cobro parcial (${paymentItems.length} ítems)';
    } else if (split.isEqualSplit && split.equalSplitSnapshot != null) {
      paymentItems = equalSplitPartItems(
        split.equalSplitSnapshot!,
        split.equalCurrentPart,
        split.equalTotalParts,
      );
      totals = calculateTotalsForItems(paymentItems, cart, taxRate: taxRate, taxIncluded: taxIncluded);
      splitLabel = 'Parte ${split.equalCurrentPart} de ${split.equalTotalParts}';
    } else {
      paymentItems = cart.items;
      totals = ref.watch(saleTotalsProvider);
    }

    if (paymentItems.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pos');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final paid = double.tryParse(_amountController.text) ?? 0;
    final change = _method == PaymentMethod.cash ? (paid - totals.total).clamp(0, double.infinity) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobrar'),
        actions: [
          if (!split.isActive)
            TextButton.icon(
              onPressed: () => context.push('/payment/split'),
              icon: const Icon(Icons.call_split),
              label: const Text('Dividir'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        children: [
          if (splitLabel != null) ...[
            Center(
              child: Chip(
                avatar: Icon(Icons.call_split, size: 18, color: Theme.of(context).colorScheme.primary),
                label: Text(splitLabel),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Center(
            child: Column(
              children: [
                Text(
                  split.isEqualSplit ? 'TOTAL ESTA PARTE' : 'TOTAL A PAGAR',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '$symbol${totals.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                if (totals.taxAmount > 0)
                  Text(
                    'Incluye ${config?.taxName ?? 'ITBMS'}: $symbol${totals.taxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Método de pago', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaymentMethod.values.map((m) {
              final selected = _method == m;
              return ChoiceChip(
                label: Text(paymentMethodLabel(m)),
                selected: selected,
                onSelected: (_) => setState(() => _method = m),
              );
            }).toList(),
          ),
          if (_method == PaymentMethod.cash) ...[
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto recibido',
                prefixText: '$symbol ',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text('Billetes rápidos', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final bill in [1.0, 5.0, 10.0, 20.0])
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text('$symbol${bill.toStringAsFixed(0)}'),
                    onPressed: () => _addCash(bill),
                  ),
                ActionChip(
                  avatar: Icon(Icons.payments_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                  label: const Text('Exacto'),
                  onPressed: () => _setExact(totals.total),
                ),
              ],
            ),
            if (change > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.change_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    const Text('Vuelto'),
                    const Spacer(),
                    Text(
                      '$symbol${change.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, ViewInsets.bottom(context)),
        child: SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _processing ? null : _confirm,
            icon: _processing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle),
            label: Text(split.isEqualSplit ? 'Confirmar parte ${split.equalCurrentPart}' : 'Confirmar pago'),
          ),
        ),
      ),
    );
  }
}
