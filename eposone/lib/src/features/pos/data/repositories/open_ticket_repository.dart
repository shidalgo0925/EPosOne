import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket_line.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';

part 'open_ticket_repository.g.dart';

@riverpod
OpenTicketRepository openTicketRepository(OpenTicketRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return OpenTicketRepository(db);
}

class OpenTicketRepository {
  final Isar _isar;
  OpenTicketRepository(this._isar);

  Future<List<OpenTicket>> getAllOpenTickets() async {
    return _isar.openTickets
        .filter()
        .isDeletedEqualTo(false)
        .sortBySavedAtDesc()
        .findAll();
  }

  Future<int> countOpenTickets() async {
    return _isar.openTickets.filter().isDeletedEqualTo(false).count();
  }

  Future<List<OpenTicketLine>> getLines(String openTicketId) async {
    return _isar.openTicketLines
        .filter()
        .openTicketIdEqualTo(openTicketId)
        .isDeletedEqualTo(false)
        .findAll();
  }

  Future<OpenTicket?> getById(String localId) async {
    return _isar.openTickets.filter().localIdEqualTo(localId).findFirst();
  }

  Future<OpenTicket> saveFromCart({
    required CartState cart,
    String? openTicketId,
    String? label,
    String? cashierId,
    String? cashRegisterId,
  }) async {
    final now = DateTime.now();
    final existing = openTicketId != null ? await getById(openTicketId) : null;

    final ticket = existing != null
        ? existing.copyWith(
            label: label ?? existing.label,
            customerId: cart.customerId,
            discountPercent: cart.discountPercent,
            savedAt: now,
            updatedAt: now,
          )
        : OpenTicket.create(
            label: label,
            customerId: cart.customerId,
            cashierId: cashierId,
            cashRegisterId: cashRegisterId,
            discountPercent: cart.discountPercent,
          );

    final lines = cart.items
        .map(
          (item) => OpenTicketLine.create(
            openTicketId: ticket.localId,
            productId: item.product.localId,
            productName: item.product.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            discount: item.discount,
          ),
        )
        .toList();

    await _isar.writeTxn(() async {
      await _isar.openTickets.put(ticket);
      await _isar.openTicketLines.filter().openTicketIdEqualTo(ticket.localId).deleteAll();
      await _isar.openTicketLines.putAll(lines);
    });

    return ticket;
  }

  Future<void> deleteTicket(String localId) async {
    await _isar.writeTxn(() async {
      final ticket = await getById(localId);
      if (ticket != null) {
        await _isar.openTickets.put(ticket.markAsDeleted());
      }
      await _isar.openTicketLines.filter().openTicketIdEqualTo(localId).deleteAll();
    });
  }
}
