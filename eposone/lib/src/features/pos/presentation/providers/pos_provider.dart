import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/sales/presentation/providers/sales_provider.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';

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

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(const CheckoutState());

  void setPaymentMethod(PaymentMethod method) => state = state.copyWith(paymentMethod: method);
  void setAmountPaid(double amount) => state = state.copyWith(amountPaid: amount);
  void setCustomer(String? customerId) => state = state.copyWith(customerId: customerId);
  void reset() => state = const CheckoutState();
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) => CheckoutNotifier());

class SaleTotals {
  final double subtotal;
  final double discount;
  final double taxAmount;
  final double total;

  const SaleTotals({
    required this.subtotal,
    required this.discount,
    required this.taxAmount,
    required this.total,
  });
}

SaleTotals calculateSaleTotals(CartState cart, {required double taxRate, required bool taxIncluded}) {
  final subtotal = cart.subtotal;
  final discount = cart.totalDiscount + cart.discountGlobal;
  final taxable = (subtotal - discount).clamp(0, double.infinity);
  final taxAmount = taxIncluded ? 0.0 : taxable * (taxRate / 100);
  final total = taxable + taxAmount;
  return SaleTotals(subtotal: subtotal, discount: discount, taxAmount: taxAmount, total: total);
}

final saleTotalsProvider = Provider<SaleTotals>((ref) {
  final cart = ref.watch(cartProvider);
  final config = ref.watch(businessConfigProvider);
  return calculateSaleTotals(
    cart,
    taxRate: config?.taxRate ?? 0,
    taxIncluded: config?.taxIncluded ?? false,
  );
});

final completeSaleProvider = Provider<Future<Sale?> Function()>((ref) {
  return () async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return null;

    final session = ref.read(posSessionProvider);
    if (session == null || session.cashRegisterId == null) {
      throw StateError('Sesión o caja no disponible');
    }

    final checkout = ref.read(checkoutProvider);
    final config = await ref.read(businessConfigAsyncProvider.future);
    final saleRepo = ref.read(saleRepositoryProvider);
    final configRepo = ref.read(businessConfigRepositoryProvider);

    final totals = calculateSaleTotals(
      cart,
      taxRate: config.taxRate,
      taxIncluded: config.taxIncluded,
    );

    final amountPaid = checkout.paymentMethod == PaymentMethod.cash
        ? (checkout.amountPaid > 0 ? checkout.amountPaid : totals.total)
        : totals.total;
    final change = checkout.paymentMethod == PaymentMethod.cash
        ? (amountPaid - totals.total).clamp(0, double.infinity)
        : 0.0;

    if (checkout.paymentMethod == PaymentMethod.cash && amountPaid < totals.total) {
      throw StateError('Monto recibido insuficiente');
    }

    for (final item in cart.items) {
      if (config.trackInventory && item.quantity > item.product.stock) {
        throw StateError('Stock insuficiente: ${item.product.name}');
      }
    }

    final receiptNumber = await configRepo.getNextReceiptNumber();

    final sale = Sale.create(
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      total: totals.total,
      amountPaid: amountPaid,
      change: change.toDouble(),
      paymentMethod: checkout.paymentMethod,
      customerId: checkout.customerId ?? cart.customerId,
      discount: totals.discount,
      receiptNumber: receiptNumber,
      cashierName: session.cashierName,
      cashierId: session.cashierId,
      cashRegisterId: session.cashRegisterId,
    );

    final items = cart.items
        .map(
          (item) => SaleItem.create(
            saleId: sale.localId,
            productId: item.product.localId,
            productName: item.product.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            discount: item.discount,
            taxRate: config.taxRate,
          ),
        )
        .toList();

    final saved = await saleRepo.completeSale(
      sale: sale,
      items: items,
      trackInventory: config.trackInventory,
    );

    ref.read(cartProvider.notifier).clear();
    ref.read(checkoutProvider.notifier).reset();
    ref.read(posSessionProvider.notifier).touch();
    ref.invalidate(salesHistoryProvider);
    ref.invalidate(productsListProvider);

    return saved;
  };
});

String paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'Efectivo';
    case PaymentMethod.card:
      return 'Tarjeta';
    case PaymentMethod.transfer:
      return 'Transferencia';
    case PaymentMethod.yappy:
      return 'Yappy';
    case PaymentMethod.other:
      return 'Otro';
  }
}
