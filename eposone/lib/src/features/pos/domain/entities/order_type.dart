/// Tipo de orden — generalista (retail, restaurante, delivery, taller…).
enum OrderType {
  generic,
  dineIn,
  takeaway,
  delivery,
}

String orderTypeLabel(OrderType type) {
  switch (type) {
    case OrderType.generic:
      return 'General';
    case OrderType.dineIn:
      return 'Comer aquí';
    case OrderType.takeaway:
      return 'Para llevar';
    case OrderType.delivery:
      return 'Delivery';
  }
}
