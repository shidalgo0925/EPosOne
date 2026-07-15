import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket_line.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
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
        .statusEqualTo(OpenTicketStatus.open)
        .sortBySavedAtDesc()
        .findAll();
  }

  Future<int> countOpenTickets() async {
    return _isar.openTickets
        .filter()
        .isDeletedEqualTo(false)
        .statusEqualTo(OpenTicketStatus.open)
        .count();
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

  Future<OpenTicket?> getByPredefinedSlotId(String slotId) async {
    return _isar.openTickets
        .filter()
        .predefinedSlotIdEqualTo(slotId)
        .statusEqualTo(OpenTicketStatus.open)
        .isDeletedEqualTo(false)
        .findFirst();
  }

  Future<OpenTicket> saveFromCart({
    required CartState cart,
    String? openTicketId,
    String? label,
    String? comment,
    String? predefinedSlotId,
    OrderType? orderType,
    String? cashierId,
    String? cashRegisterId,
  }) async {
    final now = DateTime.now();
    final existing = openTicketId != null ? await getById(openTicketId) : null;

    if (predefinedSlotId != null) {
      final conflict = await getByPredefinedSlotId(predefinedSlotId);
      if (conflict != null && conflict.localId != openTicketId) {
        throw StateError('El ticket "$label" ya está en uso');
      }
    }

    final ticket = existing != null
        ? existing.copyWith(
            label: label ?? existing.label,
            comment: comment ?? existing.comment,
            predefinedSlotId: predefinedSlotId,
            customerId: cart.customerId,
            discountPercent: cart.discountPercent,
            orderType: orderType ?? cart.orderType,
            savedAt: now,
            updatedAt: now,
            linkedOrderLocalId: existing.linkedOrderLocalId,
          )
        : OpenTicket.create(
            label: label,
            comment: comment,
            predefinedSlotId: predefinedSlotId,
            customerId: cart.customerId,
            cashierId: cashierId,
            cashRegisterId: cashRegisterId,
            discountPercent: cart.discountPercent,
            orderType: orderType ?? cart.orderType,
          );

    final lines = cart.items
        .map(
          (item) => OpenTicketLine.create(
            openTicketId: ticket.localId,
            productId: item.product.localId,
            productName: item.displayName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            discount: item.discount,
            modifiersJson: item.modifiersJson.isEmpty ? null : item.modifiersJson,
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

  Future<OpenTicket> linkOrder({
    required String ticketId,
    required String orderLocalId,
  }) async {
    final ticket = await getById(ticketId);
    if (ticket == null) throw StateError('Ticket no encontrado');
    final updated = ticket.copyWith(
      linkedOrderLocalId: orderLocalId,
      updatedAt: DateTime.now(),
    );
    await _isar.writeTxn(() => _isar.openTickets.put(updated));
    return updated;
  }

  Future<OpenTicket> moveToSlot({
    required String ticketId,
    required String targetSlotId,
    required String targetLabel,
  }) async {
    final ticket = await getById(ticketId);
    if (ticket == null) throw StateError('Ticket no encontrado');

    final conflict = await getByPredefinedSlotId(targetSlotId);
    if (conflict != null && conflict.localId != ticketId) {
      throw StateError('El destino "$targetLabel" ya está en uso');
    }

    final updated = ticket.copyWith(
      predefinedSlotId: targetSlotId,
      label: targetLabel,
      updatedAt: DateTime.now(),
    );
    await _isar.writeTxn(() => _isar.openTickets.put(updated));
    return updated;
  }

  Future<OpenTicket> updateMeta({
    required String ticketId,
    String? label,
    String? comment,
    OrderType? orderType,
    bool clearPredefinedSlot = false,
    String? predefinedSlotId,
  }) async {
    final ticket = await getById(ticketId);
    if (ticket == null) throw StateError('Ticket no encontrado');

    if (predefinedSlotId != null) {
      final conflict = await getByPredefinedSlotId(predefinedSlotId);
      if (conflict != null && conflict.localId != ticketId) {
        throw StateError('El destino ya está en uso');
      }
    }

    final updated = ticket.copyWith(
      label: label ?? ticket.label,
      comment: comment ?? ticket.comment,
      orderType: orderType ?? ticket.orderType,
      predefinedSlotId: predefinedSlotId,
      clearPredefinedSlot: clearPredefinedSlot,
      updatedAt: DateTime.now(),
    );
    await _isar.writeTxn(() => _isar.openTickets.put(updated));
    return updated;
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

  Future<OpenTicket> createEmptyTicket({
    required String label,
    String? comment,
    String? predefinedSlotId,
    OrderType orderType = OrderType.generic,
    String? cashierId,
    String? cashRegisterId,
  }) async {
    if (predefinedSlotId != null) {
      final conflict = await getByPredefinedSlotId(predefinedSlotId);
      if (conflict != null) {
        throw StateError('El ticket "$label" ya está en uso');
      }
    }

    final ticket = OpenTicket.create(
      label: label,
      comment: comment,
      predefinedSlotId: predefinedSlotId,
      cashierId: cashierId,
      cashRegisterId: cashRegisterId,
      orderType: orderType,
    );

    await _isar.writeTxn(() => _isar.openTickets.put(ticket));
    return ticket;
  }

  /// Mueve líneas entre tickets abiertos. Si el origen queda vacío, se elimina.
  Future<void> moveLinesToTicket({
    required String fromTicketId,
    required String toTicketId,
    required List<String> lineIds,
  }) async {
    if (fromTicketId == toTicketId) {
      throw StateError('El origen y destino deben ser distintos');
    }

    final fromTicket = await getById(fromTicketId);
    final toTicket = await getById(toTicketId);
    if (fromTicket == null || toTicket == null) {
      throw StateError('Ticket no encontrado');
    }

    final fromLines = await getLines(fromTicketId);
    final toLines = await getLines(toTicketId);
    final moving = fromLines.where((l) => lineIds.contains(l.localId)).toList();
    if (moving.isEmpty) {
      throw StateError('Selecciona al menos un producto');
    }

    final updatedTo = [...toLines];
    for (final line in moving) {
      final matchIdx = updatedTo.indexWhere(
        (t) => t.productId == line.productId &&
            t.unitPrice == line.unitPrice &&
            t.discount == line.discount &&
            t.modifiersJson == line.modifiersJson,
      );
      if (matchIdx >= 0) {
        updatedTo[matchIdx] = updatedTo[matchIdx].copyWith(
          quantity: updatedTo[matchIdx].quantity + line.quantity,
        );
      } else {
        updatedTo.add(
          OpenTicketLine.create(
            openTicketId: toTicketId,
            productId: line.productId,
            productName: line.productName,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            discount: line.discount,
            modifiersJson: line.modifiersJson,
          ),
        );
      }
    }

    final remainingFrom = fromLines.where((l) => !lineIds.contains(l.localId)).toList();
    final now = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.openTicketLines.filter().openTicketIdEqualTo(fromTicketId).deleteAll();
      if (remainingFrom.isNotEmpty) {
        await _isar.openTicketLines.putAll(remainingFrom);
        await _isar.openTickets.put(fromTicket.copyWith(savedAt: now, updatedAt: now));
      } else {
        await _isar.openTickets.put(fromTicket.markAsDeleted());
      }

      await _isar.openTicketLines.filter().openTicketIdEqualTo(toTicketId).deleteAll();
      await _isar.openTicketLines.putAll(updatedTo);
      await _isar.openTickets.put(toTicket.copyWith(savedAt: now, updatedAt: now));
    });
  }

  /// Fusiona todo el ticket origen en el destino y elimina el origen.
  Future<void> mergeTickets({required String fromTicketId, required String toTicketId}) async {
    final lines = await getLines(fromTicketId);
    await moveLinesToTicket(
      fromTicketId: fromTicketId,
      toTicketId: toTicketId,
      lineIds: lines.map((l) => l.localId).toList(),
    );
  }
}
