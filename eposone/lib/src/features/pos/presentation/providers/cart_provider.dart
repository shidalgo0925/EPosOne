import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';

/// Item en el carrito POS
class CartItem {
  final String id;
  final Product product;
  double quantity;
  double? customPrice;
  double discount;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.customPrice,
    this.discount = 0,
  });

  double get unitPrice => customPrice ?? product.price;
  double get subtotal => unitPrice * quantity;
  double get total => subtotal - discount;

  CartItem copyWith({
    String? id,
    Product? product,
    double? quantity,
    double? customPrice,
    double? discount,
  }) =>
      CartItem(
        id: id ?? this.id,
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
        customPrice: customPrice ?? this.customPrice,
        discount: discount ?? this.discount,
      );
}

/// Estado del carrito
class CartState {
  final List<CartItem> items;
  final String? customerId;
  final double? discountPercent;
  final String? openTicketId;
  final OrderType orderType;

  const CartState({
    this.items = const [],
    this.customerId,
    this.discountPercent,
    this.openTicketId,
    this.orderType = OrderType.generic,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get totalDiscount => items.fold(0, (sum, i) => sum + i.discount);
  double get discountGlobal => discountPercent != null ? subtotal * (discountPercent! / 100) : 0;
  double get total => (subtotal - totalDiscount - discountGlobal).clamp(0, double.infinity);
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
  }) =>
      CartState(
        items: items ?? this.items,
        customerId: clearCustomer ? null : (customerId ?? this.customerId),
        discountPercent: clearDiscountPercent ? null : (discountPercent ?? this.discountPercent),
        openTicketId: clearOpenTicket ? null : (openTicketId ?? this.openTicketId),
        orderType: orderType ?? this.orderType,
      );
}

/// Notifier del carrito
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(Product product, {double quantity = 1, double? customPrice}) {
    final existingIndex = state.items.indexWhere((i) => i.product.localId == product.localId);
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

  /// Reduce cantidad de una línea; elimina si llega a cero.
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

  /// Extrae líneas del carrito y las devuelve (para cobro parcial).
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