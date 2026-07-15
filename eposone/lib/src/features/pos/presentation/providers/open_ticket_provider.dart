import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/orders/presentation/providers/order_providers.dart';
import 'package:eposone/src/features/pos/data/repositories/open_ticket_repository.dart';
import 'package:eposone/src/features/pos/data/repositories/predefined_ticket_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket_line.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/pos/domain/entities/predefined_ticket.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/products/data/repositories/product_repository.dart';
import 'package:eposone/src/features/products/domain/modifier_codec.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';

final openTicketsListProvider = FutureProvider<List<OpenTicket>>((ref) async {
  final repo = ref.watch(openTicketRepositoryProvider);
  return repo.getAllOpenTickets();
});

final openTicketsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(openTicketRepositoryProvider);
  return repo.countOpenTickets();
});

final availablePredefinedSlotsProvider = FutureProvider<List<PredefinedTicket>>((ref) async {
  final repo = ref.watch(predefinedTicketRepositoryProvider);
  return repo.getAvailableSlots();
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

class SaveOpenTicketParams {
  final String? label;
  final String? comment;
  final String? predefinedSlotId;
  final OrderType? orderType;

  const SaveOpenTicketParams({
    this.label,
    this.comment,
    this.predefinedSlotId,
    this.orderType,
  });
}

class OpenTicketActions {
  final Ref _ref;
  OpenTicketActions(this._ref);

  Future<OpenTicket> saveCurrentCart(SaveOpenTicketParams params) async {
    final cart = _ref.read(cartProvider);
    if (cart.items.isEmpty) {
      throw StateError('El pedido está vacío');
    }

    final session = _ref.read(posSessionProvider);
    final repo = _ref.read(openTicketRepositoryProvider);

    final ticket = await repo.saveFromCart(
      cart: cart,
      openTicketId: cart.openTicketId,
      label: params.label,
      comment: params.comment,
      predefinedSlotId: params.predefinedSlotId,
      orderType: params.orderType ?? cart.orderType,
      cashierId: session?.cashierId,
      cashRegisterId: session?.cashRegisterId,
    );

    _ref.read(cartProvider.notifier).clear();
    _invalidate();
    return ticket;
  }

  Future<void> restoreTicket(String ticketId) async {
    final repo = _ref.read(openTicketRepositoryProvider);

    final productRepo = _ref.read(productRepositoryProvider);

    final ticket = await repo.getById(ticketId);
    if (ticket == null) throw StateError('Ticket no encontrado');

    final lines = await repo.getLines(ticketId);
    final cartItems = <CartItem>[];
    final skipped = <String>[];

    for (final line in lines) {
      final product = await productRepo.getProductById(line.productId);
      if (product == null || !product.isActive) {
        skipped.add(line.productName);
        continue;
      }
      cartItems.add(
        CartItem(
          id: line.localId,
          product: product,
          quantity: line.quantity,
          discount: line.discount,
          modifiers: ModifierCodec.decode(line.modifiersJson),
        ),
      );
    }

    if (skipped.isNotEmpty) {
      throw StateError('Productos no disponibles: ${skipped.join(', ')}');
    }

    _ref.read(cartProvider.notifier).loadCart(
          items: cartItems,
          customerId: ticket.customerId,
          openTicketId: ticket.localId,
          discountPercent: ticket.discountPercent,
          orderType: ticket.orderType,
        );
  }

  Future<void> moveTicket(String ticketId, String targetSlotId, String targetLabel) async {
    await _ref.read(openTicketRepositoryProvider).moveToSlot(
          ticketId: ticketId,
          targetSlotId: targetSlotId,
          targetLabel: targetLabel,
        );
    _invalidate();
  }

  Future<void> updateTicketMeta({
    required String ticketId,
    String? label,
    String? comment,
    OrderType? orderType,
    bool clearPredefinedSlot = false,
  }) async {
    await _ref.read(openTicketRepositoryProvider).updateMeta(
          ticketId: ticketId,
          label: label,
          comment: comment,
          orderType: orderType,
          clearPredefinedSlot: clearPredefinedSlot,
        );
    _invalidate();
  }

  Future<void> deleteTicket(String ticketId) async {
    final repo = _ref.read(openTicketRepositoryProvider);
    final ticket = await repo.getById(ticketId);
    final linkedOrderId = ticket?.linkedOrderLocalId;

    await repo.deleteTicket(ticketId);

    final cart = _ref.read(cartProvider);
    if (cart.openTicketId == ticketId) {
      _ref.read(cartProvider.notifier).clear();
    }

    if (linkedOrderId != null && linkedOrderId.isNotEmpty) {
      try {
        await _ref.read(orderServiceProvider).voidOrder(
              orderLocalId: linkedOrderId,
              reason: 'ticket_deleted',
              syncNow: true,
            );
        _ref.invalidate(syncPendingCountProvider);
        _ref.invalidate(syncOperationsProvider);
        _ref.invalidate(localOrdersProvider);
      } catch (_) {}
    }

    _invalidate();
    _ref.invalidate(openTicketDetailProvider(ticketId));
  }

  Future<OpenTicket> createEmptyTicket(SaveOpenTicketParams params) async {
    final session = _ref.read(posSessionProvider);
    final ticket = await _ref.read(openTicketRepositoryProvider).createEmptyTicket(
          label: params.label ?? 'Ticket ${DateTime.now().millisecondsSinceEpoch % 10000}',
          comment: params.comment,
          predefinedSlotId: params.predefinedSlotId,
          orderType: params.orderType ?? OrderType.generic,
          cashierId: session?.cashierId,
          cashRegisterId: session?.cashRegisterId,
        );
    _invalidate();
    return ticket;
  }

  Future<void> moveLines({
    required String fromTicketId,
    required String toTicketId,
    required List<String> lineIds,
  }) async {
    await _ref.read(openTicketRepositoryProvider).moveLinesToTicket(
          fromTicketId: fromTicketId,
          toTicketId: toTicketId,
          lineIds: lineIds,
        );
    _invalidate();
    _ref.invalidate(openTicketDetailProvider(fromTicketId));
    _ref.invalidate(openTicketDetailProvider(toTicketId));
  }

  Future<void> mergeInto({required String fromTicketId, required String toTicketId}) async {
    await _ref.read(openTicketRepositoryProvider).mergeTickets(
          fromTicketId: fromTicketId,
          toTicketId: toTicketId,
        );
    _invalidate();
    _ref.invalidate(openTicketDetailProvider(fromTicketId));
    _ref.invalidate(openTicketDetailProvider(toTicketId));
  }

  void _invalidate() {
    _ref.invalidate(openTicketsListProvider);
    _ref.invalidate(openTicketsCountProvider);
    _ref.invalidate(availablePredefinedSlotsProvider);
  }
}

final openTicketActionsProvider = Provider<OpenTicketActions>((ref) => OpenTicketActions(ref));
