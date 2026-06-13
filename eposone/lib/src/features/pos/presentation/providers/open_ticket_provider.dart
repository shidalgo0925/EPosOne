import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/pos/data/repositories/open_ticket_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket_line.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/products/data/repositories/product_repository.dart';

final openTicketsListProvider = FutureProvider<List<OpenTicket>>((ref) async {
  final repo = ref.watch(openTicketRepositoryProvider);
  return repo.getAllOpenTickets();
});

final openTicketsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(openTicketRepositoryProvider);
  return repo.countOpenTickets();
});

typedef OpenTicketDetail = ({OpenTicket ticket, List<OpenTicketLine> lines, double total});

final openTicketDetailProvider = FutureProvider.family<OpenTicketDetail?, String>((ref, id) async {
  final repo = ref.watch(openTicketRepositoryProvider);
  final ticket = await repo.getById(id);
  if (ticket == null) return null;
  final lines = await repo.getLines(id);
  final total = lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
  return (ticket: ticket, lines: lines, total: total);
});

class OpenTicketActions {
  final Ref _ref;
  OpenTicketActions(this._ref);

  Future<void> saveCurrentCart({String? label}) async {
    final cart = _ref.read(cartProvider);
    if (cart.items.isEmpty) {
      throw StateError('El ticket está vacío');
    }

    final session = _ref.read(posSessionProvider);
    final repo = _ref.read(openTicketRepositoryProvider);

    await repo.saveFromCart(
      cart: cart,
      openTicketId: cart.openTicketId,
      label: label,
      cashierId: session?.cashierId,
      cashRegisterId: session?.cashRegisterId,
    );

    _ref.read(cartProvider.notifier).clear();
    _ref.invalidate(openTicketsListProvider);
    _ref.invalidate(openTicketsCountProvider);
  }

  Future<void> restoreTicket(String ticketId) async {
    final repo = _ref.read(openTicketRepositoryProvider);
    final productRepo = _ref.read(productRepositoryProvider);

    final ticket = await repo.getById(ticketId);
    if (ticket == null) throw StateError('Ticket no encontrado');

    final lines = await repo.getLines(ticketId);
    final cartItems = <CartItem>[];

    for (final line in lines) {
      final product = await productRepo.getProductById(line.productId);
      if (product == null || !product.isActive) continue;
      cartItems.add(
        CartItem(
          id: line.localId,
          product: product,
          quantity: line.quantity,
          customPrice: line.unitPrice != product.price ? line.unitPrice : null,
          discount: line.discount,
        ),
      );
    }

    _ref.read(cartProvider.notifier).loadCart(
          items: cartItems,
          customerId: ticket.customerId,
          openTicketId: ticket.localId,
          discountPercent: ticket.discountPercent,
        );
  }

  Future<void> deleteTicket(String ticketId) async {
    final repo = _ref.read(openTicketRepositoryProvider);
    await repo.deleteTicket(ticketId);

    final cart = _ref.read(cartProvider);
    if (cart.openTicketId == ticketId) {
      _ref.read(cartProvider.notifier).clear();
    }

    _ref.invalidate(openTicketsListProvider);
    _ref.invalidate(openTicketsCountProvider);
  }
}

final openTicketActionsProvider = Provider<OpenTicketActions>((ref) => OpenTicketActions(ref));
