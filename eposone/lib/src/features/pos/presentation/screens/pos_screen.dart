import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = _searchQuery.isEmpty
        ? ref.watch(productsListProvider)
        : ref.watch(productsSearchProvider(_searchQuery));

    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vender'),
        actions: [
          if (cart.itemCount > 0)
            Badge(
              label: Text('${cart.itemCount}'),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCart(context),
              ),
            ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final activeProducts = products.where((p) => p.isActive).toList();

          if (activeProducts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Sin productos activos'),
                  Text(
                    'Agrega productos primero',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Catálogo
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: activeProducts.length,
                  itemBuilder: (context, index) {
                    final product = activeProducts[index];
                    return _ProductCard(
                      product: product,
                      onTap: () => _addToCart(product),
                      onLongPress: () => _showQtyDialog(product),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: cart.itemCount > 0 ? _CartSummary(cart: cart, onTap: () => _showCart(context)) : null,
    );
  }

  void _addToCart(Product product) {
    ref.read(cartProvider.notifier).addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'DESHACER',
          onPressed: () => ref.read(cartProvider.notifier).removeItem(
            ref.read(cartProvider).items.last.id,
          ),
        ),
      ),
    );
  }

  void _showQtyDialog(Product product) {
    final qtyController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Precio: \$${product.price.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 1;
              if (qty > 0) {
                ref.read(cartProvider.notifier).addProduct(product, quantity: qty);
              }
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _CartSheet(),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.minStockAlert != null && product.stock <= product.minStockAlert!;

    return Card(
      elevation: 2,
      color: isOutOfStock ? Colors.grey.shade900 : null,
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        onLongPress: isOutOfStock ? null : onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stock indicator
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOutOfStock ? Colors.red : isLowStock ? Colors.orange : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOutOfStock ? 'Sin stock' : 'Stock: ${product.stock.toStringAsFixed(product.stock == product.stock.toInt() ? 0 : 1)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOutOfStock ? Colors.red : isLowStock ? Colors.orange : Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOutOfStock ? Colors.grey : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.barcode != null && product.barcode!.isNotEmpty)
                Text(
                  product.barcode!,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock ? Colors.grey : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (!isOutOfStock)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartState cart;
  final VoidCallback onTap;

  const _CartSummary({required this.cart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'} - ${cart.totalQuantity} unidades',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Text(
                      '\$${cart.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ver carrito'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartSheet extends ConsumerStatefulWidget {
  const _CartSheet();

  @override
  ConsumerState<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<_CartSheet> {
  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Text(
                'Carrito',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ref.read(cartProvider.notifier).clear(),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Vaciar'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Carrito vacío'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemTile(
                        item: item,
                        onUpdateQty: (qty) => ref.read(cartProvider.notifier).updateQuantity(item.id, qty),
                        onUpdateDiscount: (discount) => ref.read(cartProvider.notifier).updateDiscount(item.id, discount),
                        onRemove: () => ref.read(cartProvider.notifier).removeItem(item.id),
                      );
                    },
                  ),
          ),

          // Totales
          if (cart.items.isNotEmpty) ...[
            const Divider(),
            _buildTotalRow('Subtotal', cart.subtotal),
            if (cart.totalDiscount > 0)
              _buildTotalRow('Descuento items', -cart.totalDiscount, isNegative: true),
            if (cart.discountGlobal > 0)
              _buildTotalRow('Descuento global', -cart.discountGlobal, isNegative: true),
            _buildTotalRow('TOTAL', cart.total, isTotal: true),
            const SizedBox(height: 16),

            // Checkout button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _showCheckout(context),
                icon: const Icon(Icons.payment),
                label: Text('Checkout - \$${cart.total.toStringAsFixed(2)}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isTotal = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.green : null,
            ),
          ),
          const Spacer(),
          Text(
            '${isNegative ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isNegative ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckout(BuildContext context) {
    Navigator.pop(context); // Close cart sheet

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _CheckoutSheet(),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final Function(double) onUpdateQty;
  final Function(double) onUpdateDiscount;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onUpdateQty,
    required this.onUpdateDiscount,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Qty controls
                _QtyButton(
                  icon: Icons.remove,
                  onPressed: () => onUpdateQty(item.quantity - (item.product.allowDecimalQty ? 0.5 : 1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    item.quantity.toStringAsFixed(item.product.allowDecimalQty && item.quantity != item.quantity.toInt() ? 1 : 0),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onPressed: () => onUpdateQty(item.quantity + (item.product.allowDecimalQty ? 0.5 : 1)),
                ),
                const Spacer(),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${item.unitPrice.toStringAsFixed(2)} x ${item.quantity.toStringAsFixed(item.product.allowDecimalQty ? 1 : 0)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (item.discount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Descuento: -\$${item.discount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet();

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  final _amountController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.total;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Checkout',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Total
          Center(
            child: Column(
              children: [
                const Text('TOTAL A PAGAR', style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment method
          Text('Método de pago', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<PaymentMethod>(
            segments: const [
              ButtonSegment(value: PaymentMethod.cash, label: Text('Efectivo'), icon: Icon(Icons.money)),
              ButtonSegment(value: PaymentMethod.card, label: Text('Tarjeta'), icon: Icon(Icons.credit_card)),
              ButtonSegment(value: PaymentMethod.transfer, label: Text('Transfer'), icon: Icon(Icons.send)),
            ],
            selected: {_paymentMethod},
            onSelectionChanged: (set) => setState(() => _paymentMethod = set.first),
          ),
          const SizedBox(height: 20),

          // Amount paid (for cash)
          if (_paymentMethod == PaymentMethod.cash) ...[
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto recibido',
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Quick amounts
            Wrap(
              spacing: 8,
              children: [
                _QuickAmount(total: total, amount: total, controller: _amountController),
                _QuickAmount(total: total, amount: (total / 5).ceil() * 5, controller: _amountController),
                _QuickAmount(total: total, amount: (total / 10).ceil() * 10, controller: _amountController),
                _QuickAmount(total: total, amount: (total / 20).ceil() * 20, controller: _amountController),
                _QuickAmount(total: total, amount: (total / 50).ceil() * 50, controller: _amountController),
              ],
            ),
            const SizedBox(height: 16),
            // Change
            Builder(builder: (context) {
              final paid = double.tryParse(_amountController.text) ?? 0;
              final change = paid - total;
              if (change > 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.change_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      const Text('Vuelto:', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Text(
                        '\$${change.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 16),
          ],

          const Spacer(),

          // Complete button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _completeSale(context, total),
              icon: const Icon(Icons.check_circle),
              label: const Text('Completar venta'),
            ),
          ),
        ],
      ),
    );
  }

  void _completeSale(BuildContext context, double total) {
    // Validate cash amount
    if (_paymentMethod == PaymentMethod.cash) {
      final paid = double.tryParse(_amountController.text) ?? 0;
      if (paid < total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El monto recibido es menor al total')),
        );
        return;
      }
    }

    ref.read(checkoutProvider.notifier)
      ..setPaymentMethod(_paymentMethod)
      ..setAmountPaid(double.tryParse(_amountController.text) ?? total);

    // Execute sale
    // In real implementation, call posSaleProvider
    // For now, just show success

    ref.read(cartProvider.notifier).clear();
    ref.read(checkoutProvider.notifier).reset();

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('¡Venta completada!'),
        content: Text('Total: \$${total.toStringAsFixed(2)}\nMétodo: ${_paymentMethod.name}'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

class _QuickAmount extends StatelessWidget {
  final double total;
  final double amount;
  final TextEditingController controller;

  const _QuickAmount({
    required this.total,
    required this.amount,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('\$${amount.toStringAsFixed(amount == amount.toInt() ? 0 : 2)}'),
      onPressed: () => controller.text = amount.toString(),
    );
  }
}