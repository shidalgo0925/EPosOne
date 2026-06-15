import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/split_bill_provider.dart';

class SplitBillScreen extends ConsumerStatefulWidget {
  const SplitBillScreen({super.key});

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _selectedIds = <String>{};
  int _equalParts = 2;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';
    final taxRate = config?.taxRate ?? 0;
    final taxIncluded = config?.taxIncluded ?? false;

    if (cart.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pos');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedItems = cart.items.where((i) => _selectedIds.contains(i.id)).toList();
    final selectedTotals = selectedItems.isEmpty
        ? const SaleTotals(subtotal: 0, discount: 0, taxAmount: 0, total: 0)
        : calculateTotalsForItems(selectedItems, cart, taxRate: taxRate, taxIncluded: taxIncluded);

    final fullTotals = calculateTotalsForItems(cart.items, cart, taxRate: taxRate, taxIncluded: taxIncluded);
    final perPartTotal = fullTotals.total / _equalParts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dividir cuenta'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Por ítems', icon: Icon(Icons.checklist)),
            Tab(text: 'Partes iguales', icon: Icon(Icons.groups_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ItemsSplitTab(
            cart: cart,
            symbol: symbol,
            selectedIds: _selectedIds,
            selectedTotals: selectedTotals,
            onToggle: (id, selected) => setState(() {
              if (selected) {
                _selectedIds.add(id);
              } else {
                _selectedIds.remove(id);
              }
            }),
            onSelectAll: () => setState(() {
              _selectedIds
                ..clear()
                ..addAll(cart.items.map((i) => i.id));
            }),
            onClear: () => setState(_selectedIds.clear),
          ),
          _EqualSplitTab(
            symbol: symbol,
            parts: _equalParts,
            perPartTotal: perPartTotal,
            fullTotal: fullTotals.total,
            onPartsChanged: (n) => setState(() => _equalParts = n),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, ViewInsets.bottom(context)),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _tabs.index == 0 && _selectedIds.isEmpty ? null : () => _startPayment(cart),
            icon: const Icon(Icons.payments),
            label: Text(_tabs.index == 0 ? 'Cobrar selección' : 'Cobrar parte 1 de $_equalParts'),
          ),
        ),
      ),
    );
  }

  void _startPayment(CartState cart) {
    if (_tabs.index == 0) {
      if (_selectedIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona al menos un producto')),
        );
        return;
      }
      ref.read(splitBillProvider.notifier).setSelectedItems(_selectedIds);
    } else {
      ref.read(splitBillProvider.notifier).startEqualSplit(cart.items, _equalParts);
    }
    context.push('/payment');
  }
}

class _ItemsSplitTab extends StatelessWidget {
  final CartState cart;
  final String symbol;
  final Set<String> selectedIds;
  final SaleTotals selectedTotals;
  final void Function(String id, bool selected) onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  const _ItemsSplitTab({
    required this.cart,
    required this.symbol,
    required this.selectedIds,
    required this.selectedTotals,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              TextButton(onPressed: onSelectAll, child: const Text('Todos')),
              TextButton(onPressed: onClear, child: const Text('Ninguno')),
              const Spacer(),
              Text(
                'Selección: $symbol${selectedTotals.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cart.items.length,
            itemBuilder: (_, i) {
              final item = cart.items[i];
              final selected = selectedIds.contains(item.id);
              return Card(
                child: CheckboxListTile(
                  value: selected,
                  onChanged: (v) => onToggle(item.id, v ?? false),
                  title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} x $symbol${item.unitPrice.toStringAsFixed(2)}',
                  ),
                  secondary: Text(
                    '$symbol${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EqualSplitTab extends StatelessWidget {
  final String symbol;
  final int parts;
  final double perPartTotal;
  final double fullTotal;
  final ValueChanged<int> onPartsChanged;

  const _EqualSplitTab({
    required this.symbol,
    required this.parts,
    required this.perPartTotal,
    required this.fullTotal,
    required this.onPartsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Total del ticket',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          Text(
            '$symbol${fullTotal.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Text('Número de partes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final n in [2, 3, 4, 5, 6, 8])
                ChoiceChip(
                  label: Text('$n'),
                  selected: parts == n,
                  onSelected: (_) => onPartsChanged(n),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Cada parte paga'),
                const SizedBox(height: 8),
                Text(
                  '$symbol${perPartTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se crearán $parts ventas (una por cada cobro)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
