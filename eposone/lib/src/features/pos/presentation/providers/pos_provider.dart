import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/printing/thermal_printer_service.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/sales/presentation/providers/sales_provider.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/pos/data/repositories/open_ticket_repository.dart';
import 'package:eposone/src/features/pos/presentation/providers/open_ticket_provider.dart';
import 'package:eposone/src/features/fiscal/data/repositories/fiscal_repository.dart';
import 'package:eposone/src/features/fiscal/presentation/providers/fiscal_provider.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';
import 'package:eposone/src/features/customers/data/repositories/customer_repository.dart';
import 'package:eposone/src/features/premium/data/repositories/coupon_repository.dart';

/// Estado del checkout
class CheckoutState {
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final String? customerId;
  final double tipAmount;

  const CheckoutState({
    this.paymentMethod = PaymentMethod.cash,
    this.amountPaid = 0,
    this.customerId,
    this.tipAmount = 0,
  });

  CheckoutState copyWith({
    PaymentMethod? paymentMethod,
    double? amountPaid,
    String? customerId,
    double? tipAmount,
  }) =>
      CheckoutState(
        paymentMethod: paymentMethod ?? this.paymentMethod,
        amountPaid: amountPaid ?? this.amountPaid,
        customerId: customerId ?? this.customerId,
        tipAmount: tipAmount ?? this.tipAmount,
      );
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(const CheckoutState());

  void setPaymentMethod(PaymentMethod method) => state = state.copyWith(paymentMethod: method);
  void setAmountPaid(double amount) => state = state.copyWith(amountPaid: amount);
  void setCustomer(String? customerId) => state = state.copyWith(customerId: customerId);
  void setTipAmount(double amount) => state = state.copyWith(tipAmount: amount.clamp(0, double.infinity));
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
  final discount = cart.totalDiscount + cart.discountGlobal + cart.couponDiscount;
  final taxable = (subtotal - discount).clamp(0, double.infinity);
  final taxAmount = taxIncluded ? 0.0 : taxable * (taxRate / 100);
  final total = taxable + taxAmount;
  return SaleTotals(subtotal: subtotal, discount: discount, taxAmount: taxAmount, total: total);
}

SaleTotals calculateTotalsForItems(List<CartItem> items, CartState cart, {required double taxRate, required bool taxIncluded}) {
  return calculateSaleTotals(
    CartState(items: items, discountPercent: cart.discountPercent, customerId: cart.customerId),
    taxRate: taxRate,
    taxIncluded: taxIncluded,
  );
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

final completeSaleProvider = Provider<Future<Sale?> Function({List<CartItem>? itemsOverride, String? notes})>((ref) {
  return ({List<CartItem>? itemsOverride, String? notes}) async {
    final cart = ref.read(cartProvider);
    final itemsToSell = itemsOverride ?? cart.items;
    if (itemsToSell.isEmpty) return null;

    final session = ref.read(posSessionProvider);
    if (session == null || session.cashRegisterId == null) {
      throw StateError('Sesión o caja no disponible');
    }

    final checkout = ref.read(checkoutProvider);
    final config = await ref.read(businessConfigAsyncProvider.future);
    final saleRepo = ref.read(saleRepositoryProvider);
    final configRepo = ref.read(businessConfigRepositoryProvider);

    final totals = calculateSaleTotals(
      CartState(
        items: itemsToSell,
        discountPercent: cart.discountPercent,
        customerId: cart.customerId,
      ),
      taxRate: config.taxRate,
      taxIncluded: config.taxIncluded,
    );

    final tip = checkout.tipAmount;
    final saleTotal = totals.total + tip;

    final amountPaid = checkout.paymentMethod == PaymentMethod.cash
        ? (checkout.amountPaid > 0 ? checkout.amountPaid : saleTotal)
        : saleTotal;
    final change = checkout.paymentMethod == PaymentMethod.cash
        ? (amountPaid - saleTotal).clamp(0, double.infinity)
        : 0.0;

    if (checkout.paymentMethod == PaymentMethod.cash && amountPaid < saleTotal) {
      throw StateError('Monto recibido insuficiente');
    }

    for (final item in itemsToSell) {
      if (config.trackInventory && item.quantity > item.product.stock) {
        throw StateError('Stock insuficiente: ${item.product.name}');
      }
    }

    final receiptNumber = await configRepo.getNextReceiptNumber();

    String? openTicketLabel;
    if (cart.openTicketId != null) {
      final ot = await ref.read(openTicketRepositoryProvider).getById(cart.openTicketId!);
      openTicketLabel = ot?.label;
    }

    final sale = Sale.create(
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      total: saleTotal,
      amountPaid: amountPaid,
      change: change.toDouble(),
      tipAmount: tip,
      paymentMethod: checkout.paymentMethod,
      customerId: checkout.customerId ?? cart.customerId,
      discount: totals.discount,
      receiptNumber: receiptNumber,
      notes: notes,
      cashierName: session.cashierName,
      cashierId: session.cashierId,
      cashRegisterId: session.cashRegisterId,
      orderType: cart.orderType,
      openTicketLabel: openTicketLabel,
      couponCode: cart.appliedCouponCode,
      couponDiscount: cart.couponDiscount,
    );

    final items = itemsToSell
        .map(
          (item) => SaleItem.create(
            saleId: sale.localId,
            productId: item.product.localId,
            productName: item.displayName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            discount: item.discount,
            taxRate: config.taxRate,
            modifiersJson: item.modifiersJson.isEmpty ? null : item.modifiersJson,
          ),
        )
        .toList();

    final saved = await saleRepo.completeSale(
      sale: sale,
      items: items,
      trackInventory: config.trackInventory,
    );

    if (config.isFiscalReady) {
      try {
        await ref.read(fiscalRepositoryProvider).emitInvoiceForSale(
              sale: saved,
              items: items,
              config: config,
            );
        ref.invalidate(fiscalDocumentForSaleProvider(saved.localId));
        ref.invalidate(fiscalDocumentsProvider);
      } catch (_) {
        // La venta ya quedó registrada; el comprobante fiscal queda en error para reintento.
      }
    }

    if (config.isEn1SyncReady) {
      try {
        await ref.read(syncRepositoryProvider).enqueuePush(SyncEntityKind.sale, saved.localId);
        ref.invalidate(syncPendingCountProvider);
        ref.read(runSyncCycleProvider)();
      } catch (_) {}
    }

    if (cart.appliedCouponId != null) {
      try {
        await ref.read(couponRepositoryProvider).recordUse(cart.appliedCouponId!);
      } catch (_) {}
    }

    final customerId = checkout.customerId ?? cart.customerId;
    if (config.loyaltyEnabled && customerId != null) {
      try {
        final customerRepo = ref.read(customerRepositoryProvider);
        final customer = await customerRepo.getCustomerById(customerId);
        if (customer != null) {
          final points = (saleTotal * config.loyaltyPointsPerUnit).floor();
          if (points > 0) {
            await customerRepo.saveCustomer(
              customer.copyWith(loyaltyPoints: customer.loyaltyPoints + points).markAsModified(),
            );
          }
        }
      } catch (_) {}
    }

    if (itemsOverride != null) {
      for (final item in itemsToSell) {
        ref.read(cartProvider.notifier).removeQuantity(item.id, item.quantity);
      }
      final remaining = ref.read(cartProvider);
      if (remaining.items.isEmpty && remaining.openTicketId != null) {
        await ref.read(openTicketRepositoryProvider).deleteTicket(remaining.openTicketId!);
        ref.invalidate(openTicketsCountProvider);
      }
    } else {
      if (cart.openTicketId != null) {
        await ref.read(openTicketRepositoryProvider).deleteTicket(cart.openTicketId!);
        ref.invalidate(openTicketsCountProvider);
      }
      ref.read(cartProvider.notifier).clear();
    }

    ref.read(checkoutProvider.notifier).reset();
    ref.read(posSessionProvider.notifier).touch();
    ref.invalidate(salesHistoryProvider);
    ref.invalidate(productsListProvider);

    if (checkout.paymentMethod == PaymentMethod.cash) {
      ThermalPrinterService.openDrawerIfConfigured(isCashPayment: true);
    }

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
