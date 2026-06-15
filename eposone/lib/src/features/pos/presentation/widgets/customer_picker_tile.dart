import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/customers/presentation/providers/customer_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';

class CustomerPickerTile extends ConsumerWidget {
  final bool compact;

  const CustomerPickerTile({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final customerAsync = cart.customerId != null
        ? ref.watch(customerByIdProvider(cart.customerId!))
        : const AsyncValue<Customer?>.data(null);

    final label = customerAsync.when(
      data: (c) => c?.displayName ?? 'Cliente ocasional',
      loading: () => 'Cargando...',
      error: (_, __) => 'Cliente',
    );

    return InkWell(
      onTap: () => _pickCustomer(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 5 : 8),
        decoration: BoxDecoration(
          color: EposBrand.background,
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          border: Border.all(color: EposBrand.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, size: compact ? 15 : 18, color: EposBrand.navy.withValues(alpha: 0.7)),
            SizedBox(width: compact ? 6 : 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 11 : 13, fontWeight: FontWeight.w500),
              ),
            ),
            if (cart.customerId != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => ref.read(cartProvider.notifier).setCustomer(null),
              )
            else
              Icon(Icons.chevron_right, size: 18, color: EposBrand.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomer(BuildContext context, WidgetRef ref) async {
    final customers = await ref.read(customersListProvider.future);
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CustomerPickerSheet(customers: customers),
    );

    if (selected == _clearCustomerSentinel) {
      ref.read(cartProvider.notifier).setCustomer(null);
    } else if (selected is Customer) {
      ref.read(cartProvider.notifier).setCustomer(selected.localId);
    }
  }
}

const _clearCustomerSentinel = Object();

class _CustomerPickerSheet extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerPickerSheet({required this.customers});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Customer> get _filtered {
    if (_query.isEmpty) return widget.customers;
    final q = _query.toLowerCase();
    return widget.customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.phone?.contains(q) ?? false) ||
          (c.document?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: EposBrand.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: EposBrand.background, child: Icon(Icons.person_off, color: EposBrand.textSecondary)),
            title: const Text('Cliente ocasional'),
            onTap: () => Navigator.pop(context, _clearCustomerSentinel),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Sin clientes'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: EposBrand.orange.withValues(alpha: 0.15),
                          child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?', style: const TextStyle(color: EposBrand.navy)),
                        ),
                        title: Text(c.name),
                        subtitle: Text([c.phone, c.document].whereType<String>().join(' · ')),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
