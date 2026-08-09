import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';
import 'package:eposone/src/features/orders/domain/en1_tender_methods.dart';
import 'package:eposone/src/features/orders/presentation/widgets/multi_tender_payment_dialog.dart';
import 'package:eposone/src/features/pos/domain/payment_method_from_tenders.dart';
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
  final GlobalKey<MultiTenderPaymentPanelState> _tenderKey =
      GlobalKey<MultiTenderPaymentPanelState>();
  bool _processing = false;
  double _tipAmount = 0;
  double? _tipPercent;
  TenderLiveStatus? _live;

  // Clasificación de venta: tender dominante (no “cualquier cash ⇒ efectivo”).
  PaymentMethod _saleMethodFromPosts(List<TenderAmount> posts) =>
      paymentMethodFromTenders(posts);

  ({
    List<CartItem> items,
    CalculationResult result,
    String? splitLabel,
    bool isSplit,
  }) _paymentContext() {
    final cart = ref.read(cartProvider);
    final split = ref.read(splitBillProvider);
    final engine = ref.read(commercialEngineProvider);

    if (split.mode == SplitMode.byItems && split.selectedItemIds.isNotEmpty) {
      final items = cart.items
          .where((i) => split.selectedItemIds.contains(i.id))
          .toList();
      return (
        items: items,
        result: engine.calculateTotals(
          commercialOrderFromCart(
            cart,
            itemsOverride: items,
            tipAmount: _tipAmount,
            tipPercent: _tipPercent,
          ),
        ),
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
        result: engine.calculateTotals(
          commercialOrderFromCart(
            cart,
            itemsOverride: items,
            tipAmount: _tipAmount,
            tipPercent: _tipPercent,
          ),
        ),
        splitLabel:
            'Parte ${split.equalCurrentPart} de ${split.equalTotalParts}',
        isSplit: true,
      );
    }

    return (
      items: cart.items,
      result: engine.calculateTotals(
        commercialOrderFromCart(
          cart,
          tipAmount: _tipAmount,
          tipPercent: _tipPercent,
        ),
      ),
      splitLabel: null,
      isSplit: false,
    );
  }

  Future<void> _confirm() async {
    final settlement = _tenderKey.currentState?.tryConfirm();
    if (settlement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete montos y referencias antes de confirmar'),
        ),
      );
      return;
    }

    final ctx = _paymentContext();
    final split = ref.read(splitBillProvider);
    final saleMethod = _saleMethodFromPosts(settlement.paymentsToPost);

    ref.read(checkoutProvider.notifier)
      ..setTipAmount(ctx.result.tips)
      ..setPaymentMethod(saleMethod)
      ..setAmountPaid(settlement.amountReceived)
      ..setPaymentTenders(settlement.paymentsToPost);

    setState(() => _processing = true);
    try {
      String? notes;
      if (split.isEqualSplit) {
        notes = 'División ${split.equalCurrentPart}/${split.equalTotalParts}';
      } else if (split.mode == SplitMode.byItems) {
        notes = 'División por ítems';
      }
      if (settlement.paymentsToPost.length > 1) {
        final mix = settlement.paymentsToPost
            .map((t) => '${t.code}:${t.amount.toStringAsFixed(2)}')
            .join(', ');
        notes = [notes, 'Mixto: $mix'].whereType<String>().join(' · ');
      }

      final sale = await ref.read(completeSaleProvider)(
        itemsOverride: ctx.isSplit ? ctx.items : null,
        notes: notes,
      );

      if (sale == null || !mounted) return;

      final equalPartial =
          split.isEqualSplit && split.equalCurrentPart < split.equalTotalParts;
      final wasItemSplit = split.mode == SplitMode.byItems;

      if (equalPartial) {
        ref.read(splitBillProvider.notifier).advanceEqualPart();
        setState(() {
          _processing = false;
          _live = null;
        });
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
          const SnackBar(
              content:
                  Text('Cobro parcial completado. Quedan ítems en el ticket')),
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

  void _setTipPercent(double percent) {
    setState(() {
      _tipPercent = percent;
      _tipAmount = 0;
    });
  }

  void _clearTip() {
    setState(() {
      _tipAmount = 0;
      _tipPercent = null;
    });
  }

  Future<void> _customTip() async {
    final ctrl = TextEditingController(
        text: _tipAmount > 0 ? _tipAmount.toStringAsFixed(2) : '');
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Propina personalizada'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Monto', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', ''));
              if (v == null || v < 0) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (value == null) return;
    setState(() {
      _tipPercent = null;
      _tipAmount = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final split = ref.watch(splitBillProvider);
    final config = ref.watch(businessConfigProvider);
    final engine = ref.watch(commercialEngineProvider);
    final symbol = config?.currencySymbol ?? 'B/.';

    if (cart.items.isEmpty && !split.isEqualSplit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pos');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<CartItem> paymentItems;
    String? splitLabel;

    if (split.mode == SplitMode.byItems && split.selectedItemIds.isNotEmpty) {
      paymentItems = cart.items
          .where((i) => split.selectedItemIds.contains(i.id))
          .toList();
      splitLabel = 'Cobro parcial (${paymentItems.length} ítems)';
    } else if (split.isEqualSplit && split.equalSplitSnapshot != null) {
      paymentItems = equalSplitPartItems(
        split.equalSplitSnapshot!,
        split.equalCurrentPart,
        split.equalTotalParts,
      );
      splitLabel =
          'Parte ${split.equalCurrentPart} de ${split.equalTotalParts}';
    } else {
      paymentItems = cart.items;
    }

    if (paymentItems.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pos');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final result = engine.calculateTotals(
      commercialOrderFromCart(
        cart,
        itemsOverride: paymentItems,
        tipAmount: _tipAmount,
        tipPercent: _tipPercent,
      ),
    );
    final grandTotal = result.total;
    final canConfirm = _live?.canConfirm == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobrar Pedido'),
        actions: [
          if (!split.isActive)
            TextButton.icon(
              onPressed: () => context.push('/payment/split'),
              icon: const Icon(Icons.call_split),
              label: const Text('Dividir'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (splitLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Chip(
                avatar: Icon(Icons.call_split,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                label: Text(splitLabel),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Propina (opcional)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in [10.0, 15.0, 20.0])
                      ChoiceChip(
                        label: Text('${p.toStringAsFixed(0)}%'),
                        selected: _tipPercent == p,
                        onSelected: (_) => _setTipPercent(p),
                      ),
                    ActionChip(
                      label: const Text('Otro monto'),
                      onPressed: _customTip,
                    ),
                    if (_tipAmount > 0 || _tipPercent != null)
                      ActionChip(
                        label: const Text('Sin propina'),
                        onPressed: _clearTip,
                      ),
                  ],
                ),
                if (result.tips > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Propina: $symbol${result.tips.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: MultiTenderPaymentPanel(
              key: _tenderKey,
              balanceDue: grandTotal,
              engine: engine,
              orderTotal: grandTotal,
              alreadyPaid: 0,
              orderLabel: splitLabel ?? 'Venta POS',
              currencySymbol: symbol,
              embedded: true,
              onSettlementChanged: (s) => setState(() => _live = s),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, ViewInsets.bottom(context)),
        child: SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _processing || !canConfirm ? null : _confirm,
            icon: _processing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(
              split.isEqualSplit
                  ? 'Confirmar parte ${split.equalCurrentPart}'
                  : 'Confirmar Cobro',
            ),
          ),
        ),
      ),
    );
  }
}
