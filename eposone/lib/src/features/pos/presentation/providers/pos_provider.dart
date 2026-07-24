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
import 'package:eposone/src/features/orders/data/order_service.dart';
import 'package:eposone/src/features/orders/domain/en1_tender_methods.dart';
import 'package:eposone/src/features/orders/presentation/providers/order_providers.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';
import 'package:eposone/src/features/customers/data/repositories/customer_repository.dart';
import 'package:eposone/src/features/premium/data/repositories/coupon_repository.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';
import 'package:eposone/src/features/auth/domain/cashier_display.dart';

/// Estado del checkout
class CheckoutState {
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final String? customerId;
  final double tipAmount;

  /// Pago mixto EN1 (códigos contrato). Vacío = un solo [paymentMethod].
  final List<TenderAmount> paymentTenders;

  const CheckoutState({
    this.paymentMethod = PaymentMethod.cash,
    this.amountPaid = 0,
    this.customerId,
    this.tipAmount = 0,
    this.paymentTenders = const [],
  });

  CheckoutState copyWith({
    PaymentMethod? paymentMethod,
    double? amountPaid,
    String? customerId,
    double? tipAmount,
    List<TenderAmount>? paymentTenders,
  }) =>
      CheckoutState(
        paymentMethod: paymentMethod ?? this.paymentMethod,
        amountPaid: amountPaid ?? this.amountPaid,
        customerId: customerId ?? this.customerId,
        tipAmount: tipAmount ?? this.tipAmount,
        paymentTenders: paymentTenders ?? this.paymentTenders,
      );
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(const CheckoutState());

  void setPaymentMethod(PaymentMethod method) =>
      state = state.copyWith(paymentMethod: method);

  void setAmountPaid(double amount) =>
      state = state.copyWith(amountPaid: amount);

  void setCustomerId(String? id) => state = state.copyWith(customerId: id);

  void setCustomer(String? customerId) => setCustomerId(customerId);

  void setTipAmount(double amount) =>
      state = state.copyWith(tipAmount: amount.clamp(0, double.infinity));

  void setPaymentTenders(List<TenderAmount> tenders) =>
      state = state.copyWith(paymentTenders: tenders);

  void reset() => state = const CheckoutState();
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
    (ref) => CheckoutNotifier());

double _lineNet(CartItem item) =>
    (item.quantity * item.unitPrice) - item.discount;

/// Cupón fijo del carrito: en cobro parcial se prorratea por base neta
/// para no reaplicar el monto completo en cada split.
double _allocatedCouponDiscount(CartState cart, List<CartItem> items) {
  if (cart.couponDiscount <= 0 || cart.items.isEmpty || items.isEmpty) {
    return 0;
  }
  if (items.length == cart.items.length &&
      items.every((item) => cart.items.any((c) => c.id == item.id))) {
    return cart.couponDiscount;
  }
  final fullBase =
      cart.items.fold<double>(0, (sum, item) => sum + _lineNet(item));
  if (fullBase <= 0) return 0;
  final partBase = items.fold<double>(0, (sum, item) => sum + _lineNet(item));
  return double.parse(
    (cart.couponDiscount * partBase / fullBase).toStringAsFixed(2),
  );
}

CommercialOrderInput commercialOrderFromCart(
  CartState cart, {
  List<CartItem>? itemsOverride,
  double tipAmount = 0,
  double? tipPercent,
}) {
  final items = itemsOverride ?? cart.items;
  return CommercialOrderInput(
    lines: [
      for (final item in items)
        CommercialLineInput(
          lineId: item.id,
          productId: item.product.localId,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          lineDiscount: item.discount,
          fiscalCategoryCode: item.product.fiscalCategoryCode,
        ),
    ],
    documentDiscountPercent: cart.discountPercent ?? 0,
    couponDiscount: _allocatedCouponDiscount(cart, items),
    tipAmount: tipAmount,
    tipPercent: tipPercent,
  );
}

final saleTotalsProvider = Provider<CalculationResult>((ref) {
  final cart = ref.watch(cartProvider);
  final engine = ref.watch(commercialEngineProvider);
  return engine.calculateTotals(commercialOrderFromCart(cart));
});

final completeSaleProvider = Provider<
    Future<Sale?> Function(
        {List<CartItem>? itemsOverride, String? notes})>((ref) {
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

    final orderInput = commercialOrderFromCart(
      cart,
      itemsOverride: itemsToSell,
      tipAmount: checkout.tipAmount,
    );
    final totals =
        ref.read(commercialEngineProvider).calculateTotals(orderInput);

    final tip = totals.tips;
    final saleTotal = totals.total;

    final hasMix = checkout.paymentTenders.isNotEmpty;
    final hasCash = hasMix
        ? checkout.paymentTenders.any((t) => t.code == 'cash')
        : checkout.paymentMethod == PaymentMethod.cash;
    final payment = ref.read(commercialEngineProvider).completePayment(
          total: saleTotal,
          enteredAmount: checkout.amountPaid,
          allowsChange: hasCash,
        );

    if (!payment.isSufficient) {
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
      final ot = await ref
          .read(openTicketRepositoryProvider)
          .getById(cart.openTicketId!);
      openTicketLabel = ot?.label;
    }

    final cashierName = await CashierDisplay.resolve(
      name: session.cashierName,
      contactId: session.cashierContactId,
    );

    final sale = Sale.create(
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      total: saleTotal,
      amountPaid: payment.amountPaid,
      change: payment.change,
      tipAmount: tip,
      paymentMethod: checkout.paymentMethod,
      customerId: checkout.customerId ?? cart.customerId,
      discount: totals.discount,
      receiptNumber: receiptNumber,
      notes: notes,
      cashierName: cashierName,
      cashierId: session.cashierContactId != null
          ? 'en1_cashier_${session.cashierContactId}'
          : session.cashierId,
      cashRegisterId: session.cashRegisterId,
      orderType: cart.orderType,
      openTicketLabel: openTicketLabel,
      couponCode: cart.appliedCouponCode,
      couponDiscount: orderInput.couponDiscount,
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
            taxRate: totals.lineTaxRate(item.id),
            modifiersJson:
                item.modifiersJson.isEmpty ? null : item.modifiersJson,
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

    // Hito 3B.1: cobro POS → Order Domain (reutiliza pedido del ticket si existe).
    if (config.isEn1SyncReady) {
      try {
        String en1ProductRef(String localId, String? serverId) {
          if (serverId != null && serverId.trim().isNotEmpty) {
            return serverId.trim();
          }
          if (localId.startsWith('en1_')) return localId.substring(4);
          return localId;
        }

        String methodCode(PaymentMethod m) => switch (m) {
              PaymentMethod.cash => 'cash',
              PaymentMethod.card => 'card',
              PaymentMethod.transfer => 'transfer',
              PaymentMethod.yappy => 'yappy',
              PaymentMethod.other => 'other',
            };

        final tenders = checkout.paymentTenders.isNotEmpty
            ? checkout.paymentTenders
            : [
                TenderAmount(
                  code: methodCode(checkout.paymentMethod),
                  amount: payment.amountPaid,
                ),
              ];

        String? linkedOrderId;
        if (cart.openTicketId != null) {
          linkedOrderId = (await ref
                  .read(openTicketRepositoryProvider)
                  .getById(cart.openTicketId!))
              ?.linkedOrderLocalId;
        }

        await ref.read(orderServiceProvider).createPaidOrderFromPosSale(
              localNumber: saved.receiptNumber ?? saved.localId,
              lines: itemsToSell
                  .map(
                    (item) => PosOrderLineInput(
                      productLocalId: item.product.localId,
                      productRef: en1ProductRef(
                          item.product.localId, item.product.serverId),
                      productName: item.displayName,
                      quantity: item.quantity,
                      unitPrice: item.unitPrice,
                      discount: item.discount,
                      notes: item.modifiersJson.isEmpty
                          ? null
                          : item.modifiersJson,
                    ),
                  )
                  .toList(),
              paymentTenders: tenders,
              subtotal: totals.subtotal,
              taxAmount: totals.taxAmount,
              discount: totals.discount,
              tipAmount: tip,
              total: saleTotal,
              config: config,
              customerId: checkout.customerId ?? cart.customerId,
              cashierId: session.cashierContactId != null
                  ? 'en1_cashier_${session.cashierContactId}'
                  : session.cashierId,
              tableRef: openTicketLabel,
              notes: notes,
              currency: config.currency,
              existingOrderLocalId: linkedOrderId,
            );
        ref.invalidate(syncPendingCountProvider);
        ref.invalidate(syncOperationsProvider);
        ref.invalidate(localOrdersProvider);
      } catch (_) {
        // Venta local OK; pedido EN1 queda para reintento desde Pedidos / Sync.
      }
    }

    if (cart.appliedCouponId != null) {
      try {
        await ref
            .read(couponRepositoryProvider)
            .recordUse(cart.appliedCouponId!);
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
              customer
                  .copyWith(loyaltyPoints: customer.loyaltyPoints + points)
                  .markAsModified(),
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
        await ref
            .read(openTicketRepositoryProvider)
            .deleteTicket(remaining.openTicketId!);
        ref.invalidate(openTicketsCountProvider);
      }
    } else {
      if (cart.openTicketId != null) {
        await ref
            .read(openTicketRepositoryProvider)
            .deleteTicket(cart.openTicketId!);
        ref.invalidate(openTicketsCountProvider);
      }
      ref.read(cartProvider.notifier).clear();
    }

    ref.read(checkoutProvider.notifier).reset();
    ref.read(posSessionProvider.notifier).touch();
    ref.invalidate(salesHistoryProvider);
    ref.invalidate(productsListProvider);

    if (checkout.paymentMethod == PaymentMethod.cash ||
        checkout.paymentTenders.any((t) => t.code == 'cash')) {
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
