import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/domain/entities/selected_modifier.dart';
import 'package:eposone/src/features/products/domain/modifier_codec.dart';

/// Item en el carrito POS
class CartItem {
  final String id;
  final Product product;
  double quantity;
  double? customPrice;
  double discount;
  final List<SelectedModifier> modifiers;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.customPrice,
    this.discount = 0,
    this.modifiers = const [],
  });

  double get modifiersTotal => modifiers.fold(0.0, (sum, m) => sum + m.priceDelta);
  double get unitPrice => customPrice ?? (product.price + modifiersTotal);
  double get subtotal => unitPrice * quantity;
  double get total => subtotal - discount;

  String get displayName {
    final label = ModifierCodec.modifiersLabel(modifiers);
    if (label.isEmpty) return product.name;
    return '${product.name} ($label)';
  }

  String get modifiersJson => ModifierCodec.encode(modifiers);

  CartItem copyWith({
    String? id,
    Product? product,
    double? quantity,
    double? customPrice,
    double? discount,
    List<SelectedModifier>? modifiers,
  }) =>
      CartItem(
        id: id ?? this.id,
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
        customPrice: customPrice ?? this.customPrice,
        discount: discount ?? this.discount,
        modifiers: modifiers ?? this.modifiers,
      );

  static bool sameConfiguration(CartItem a, CartItem b) {
    if (a.product.localId != b.product.localId) return false;
    if (a.modifiers.length != b.modifiers.length) return false;
    final aIds = a.modifiers.map((m) => m.modifierId).toSet();
    final bIds = b.modifiers.map((m) => m.modifierId).toSet();
    return aIds.length == bIds.length && aIds.containsAll(bIds);
  }
}

/// Estado del carrito
class CartState {
  final List<CartItem> items;
  final String? customerId;
  final double? discountPercent;
  final String? openTicketId;
  final OrderType orderType;
  final String? appliedCouponId;
  final String? appliedCouponCode;
  final double couponDiscount;

  const CartState({
    this.items = const [],
    this.customerId,
    this.discountPercent,
    this.openTicketId,
    this.orderType = OrderType.generic,
    this.appliedCouponId,
    this.appliedCouponCode,
    this.couponDiscount = 0,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get totalDiscount => items.fold(0, (sum, i) => sum + i.discount);
  double get discountGlobal => discountPercent != null ? subtotal * (discountPercent! / 100) : 0;
  double get total =>
      (subtotal - totalDiscount - discountGlobal - couponDiscount).clamp(0, double.infinity);
  int get itemCount => items.length;
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity.toInt());

  CartState copyWith({
    List<CartItem>? items,
    String? customerId,
    bool clearCustomer = false,
    double? discountPercent,
    bool clearDiscountPercent = false,
    String? openTicketId,
    bool clearOpenTicket = false,
    OrderType? orderType,
    String? appliedCouponId,
    String? appliedCouponCode,
    bool clearCoupon = false,
    double? couponDiscount,
  }) =>
      CartState(
        items: items ?? this.items,
        customerId: clearCustomer ? null : (customerId ?? this.customerId),
        discountPercent: clearDiscountPercent ? null : (discountPercent ?? this.discountPercent),
        openTicketId: clearOpenTicket ? null : (openTicketId ?? this.openTicketId),
        orderType: orderType ?? this.orderType,
        appliedCouponId: clearCoupon ? null : (appliedCouponId ?? this.appliedCouponId),
        appliedCouponCode: clearCoupon ? null : (appliedCouponCode ?? this.appliedCouponCode),
        couponDiscount: clearCoupon ? 0 : (couponDiscount ?? this.couponDiscount),
      );
}

/// Notifier del carrito
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(
    Product product, {
    double quantity = 1,
    double? customPrice,
    List<SelectedModifier> modifiers = const [],
  }) {
    final candidate = CartItem(
      id: '',
      product: product,
      quantity: quantity,
      customPrice: customPrice,
      modifiers: modifiers,
    );
    final existingIndex = state.items.indexWhere((i) => CartItem.sameConfiguration(i, candidate));

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + quantity);
      final newItems = [...state.items];
      newItems[existingIndex] = updated;
      state = state.copyWith(items: newItems);
    } else {
      state = state.copyWith(items: [
        ...state.items,
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: quantity,
          customPrice: customPrice,
          modifiers: modifiers,
        ),
      ]);
    }
  }

  void updateQuantity(String itemId, double quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    state = state.copyWith(
      items: state.items.map((i) => i.id == itemId ? i.copyWith(quantity: quantity) : i).toList(),
    );
  }

  void updateDiscount(String itemId, double discount) {
    state = state.copyWith(
      items: state.items.map((i) => i.id == itemId ? i.copyWith(discount: discount) : i).toList(),
    );
  }

  void updateCustomPrice(String itemId, double? price) {
    state = state.copyWith(
      items: state.items.map((i) => i.id == itemId ? i.copyWith(customPrice: price) : i).toList(),
    );
  }

  void removeItem(String itemId) {
    state = state.copyWith(items: state.items.where((i) => i.id != itemId).toList());
  }

  void removeQuantity(String itemId, double quantity) {
    if (quantity <= 0) return;
    final index = state.items.indexWhere((i) => i.id == itemId);
    if (index < 0) return;
    final item = state.items[index];
    final remaining = item.quantity - quantity;
    if (remaining <= 0.0001) {
      removeItem(itemId);
    } else {
      final newItems = [...state.items];
      newItems[index] = item.copyWith(quantity: remaining);
      state = state.copyWith(items: newItems);
    }
  }

  List<CartItem> takeItems(Iterable<String> itemIds) {
    final idSet = itemIds.toSet();
    final taken = state.items.where((i) => idSet.contains(i.id)).toList();
    state = state.copyWith(items: state.items.where((i) => !idSet.contains(i.id)).toList());
    return taken;
  }

  void setCustomer(String? customerId) {
    state = state.copyWith(customerId: customerId, clearCustomer: customerId == null);
  }

  void setGlobalDiscount(double percent) {
    state = state.copyWith(discountPercent: percent);
  }

  void clearGlobalDiscount() {
    state = state.copyWith(clearDiscountPercent: true);
  }

  void applyCoupon({required String couponId, required String code, required double discountAmount}) {
    state = state.copyWith(
      appliedCouponId: couponId,
      appliedCouponCode: code,
      couponDiscount: discountAmount,
    );
  }

  void clearCoupon() {
    state = state.copyWith(clearCoupon: true);
  }

  void setOpenTicketId(String? id) {
    state = state.copyWith(openTicketId: id, clearOpenTicket: id == null);
  }

  void setOrderType(OrderType type) {
    state = state.copyWith(orderType: type);
  }

  void loadCart({
    required List<CartItem> items,
    String? customerId,
    String? openTicketId,
    double? discountPercent,
    OrderType orderType = OrderType.generic,
  }) {
    state = CartState(
      items: items,
      customerId: customerId,
      openTicketId: openTicketId,
      discountPercent: discountPercent,
      orderType: orderType,
    );
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
