import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';

/// Estado del checkout
class CheckoutState {
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final String? customerId;

  const CheckoutState({
    this.paymentMethod = PaymentMethod.cash,
    this.amountPaid = 0,
    this.customerId,
  });

  CheckoutState copyWith({
    PaymentMethod? paymentMethod,
    double? amountPaid,
    String? customerId,
  }) =>
      CheckoutState(
        paymentMethod: paymentMethod ?? this.paymentMethod,
        amountPaid: amountPaid ?? this.amountPaid,
        customerId: customerId ?? this.customerId,
      );
}

/// Notifier para checkout
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(const CheckoutState());

  void setPaymentMethod(PaymentMethod method) => state = state.copyWith(paymentMethod: method);
  void setAmountPaid(double amount) => state = state.copyWith(amountPaid: amount);
  void setCustomer(String? customerId) => state = state.copyWith(customerId: customerId);
  void reset() => state = const CheckoutState();
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) => CheckoutNotifier());

/// Provider para ejecutar venta
final posSaleProvider = Provider<Future<Sale?> Function()>((ref) {
  return () async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return null;

    final checkout = ref.read(checkoutProvider);
    final repo = ref.read(saleRepositoryProvider);
    final businessConfig = ref.read(businessConfigProvider);

    final taxRate = businessConfig?.taxRate ?? 0;
    final taxIncluded = businessConfig?.taxIncluded ?? false;

    final subtotal = cart.subtotal;
    final taxAmount = taxIncluded ? 0.0 : subtotal * (taxRate / 100);
    final total = cart.total + taxAmount;
    final amountPaid = checkout.amountPaid > 0 ? checkout.amountPaid : total;
    final change = amountPaid - total;

    final sale = Sale.create(
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
      amountPaid: amountPaid,
      change: change > 0 ? change : 0,
      paymentMethod: checkout.paymentMethod,
      customerId: checkout.customerId,
      discount: (cart.totalDiscount + cart.discountGlobal).toDouble(),
      receiptNumber: businessConfig?.nextReceiptNumber,
    );

    final items = cart.items.map((item) => SaleItem.create(
      saleId: sale.localId,
      productId: item.product.localId,
      productName: item.product.name,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      discount: item.discount,
      taxRate: taxRate,
    )).toList();

    return await repo.saveSale(sale, items);
  };
});

// Stub temporal
final businessConfigProvider = Provider((ref) => null);