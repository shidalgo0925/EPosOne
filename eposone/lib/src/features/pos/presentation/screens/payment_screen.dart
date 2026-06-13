import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
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

  Future<void> _confirm(double total) async {
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
      final sale = await ref.read(completeSaleProvider)();
      if (sale != null && mounted) {
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
    final totals = ref.watch(saleTotalsProvider);
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';

    if (cart.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pos');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final paid = double.tryParse(_amountController.text) ?? 0;
    final change = _method == PaymentMethod.cash ? (paid - totals.total).clamp(0, double.infinity) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Cobrar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        children: [
          Center(
            child: Column(
              children: [
                const Text('TOTAL A PAGAR', style: TextStyle(color: Colors.grey)),
                Text(
                  '$symbol${totals.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                if (totals.taxAmount > 0)
                  Text('Incluye ${config?.taxName ?? 'ITBMS'}: $symbol${totals.taxAmount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
            Wrap(
              spacing: 8,
              children: [
                for (final amt in [
                  totals.total,
                  (math.max(1, (totals.total / 5).ceil()) * 5).toDouble(),
                  (math.max(1, (totals.total / 10).ceil()) * 10).toDouble(),
                  (math.max(1, (totals.total / 20).ceil()) * 20).toDouble(),
                ])
                  ActionChip(
                    label: Text('$symbol${amt.toStringAsFixed(amt == amt.roundToDouble() ? 0 : 2)}'),
                    onPressed: () {
                      _amountController.text = amt.toStringAsFixed(2);
                      setState(() {});
                    },
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
            onPressed: _processing ? null : () => _confirm(totals.total),
            icon: _processing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle),
            label: const Text('Confirmar pago'),
          ),
        ),
      ),
    );
  }
}
