import 'package:eposone/src/features/orders/domain/en1_tender_methods.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

/// Mapea código de tender EN1 → [PaymentMethod] de venta local.
PaymentMethod paymentMethodFromTenderCode(String code) {
  switch (code.trim().toLowerCase()) {
    case 'cash':
      return PaymentMethod.cash;
    case 'yappy':
      return PaymentMethod.yappy;
    case 'visa':
    case 'mastercard':
    case 'clave':
    case 'card':
      return PaymentMethod.card;
    case 'ach':
    case 'transfer':
      return PaymentMethod.transfer;
    default:
      return PaymentMethod.other;
  }
}

/// Método principal de la venta = tender de **mayor monto**.
///
/// Antes: cualquier `cash` en el mixto → toda la venta “Efectivo”
/// (Visa/Clave/Yappy + centavos de efectivo quedaban mal etiquetados).
PaymentMethod paymentMethodFromTenders(List<TenderAmount> posts) {
  if (posts.isEmpty) return PaymentMethod.cash;

  final sorted = List<TenderAmount>.from(posts)
    ..sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      if (byAmount != 0) return byAmount;
      // Empate: preferir no-efectivo para no “comerse” tarjeta/Yappy.
      final aCash = a.code == 'cash';
      final bCash = b.code == 'cash';
      if (aCash && !bCash) return 1;
      if (!aCash && bCash) return -1;
      return 0;
    });

  return paymentMethodFromTenderCode(sorted.first.code);
}
