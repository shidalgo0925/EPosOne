import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/entities/predefined_ticket.dart';

part 'predefined_ticket_repository.g.dart';

@riverpod
PredefinedTicketRepository predefinedTicketRepository(PredefinedTicketRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return PredefinedTicketRepository(db);
}

class PredefinedTicketRepository {
  final Isar _isar;
  PredefinedTicketRepository(this._isar);

  Future<List<PredefinedTicket>> getAllActive() async {
    return _isar.predefinedTickets
        .filter()
        .isDeletedEqualTo(false)
        .isActiveEqualTo(true)
        .sortBySortOrder()
        .thenByName()
        .findAll();
  }

  Future<List<PredefinedTicket>> getAll() async {
    return _isar.predefinedTickets
        .filter()
        .isDeletedEqualTo(false)
        .sortBySortOrder()
        .thenByName()
        .findAll();
  }

  Future<PredefinedTicket?> getById(String localId) async {
    return _isar.predefinedTickets.filter().localIdEqualTo(localId).findFirst();
  }

  Future<Set<String>> getOccupiedSlotIds() async {
    final open = await _isar.openTickets
        .filter()
        .isDeletedEqualTo(false)
        .statusEqualTo(OpenTicketStatus.open)
        .findAll();
    return open
        .where((t) => t.predefinedSlotId != null)
        .map((t) => t.predefinedSlotId!)
        .toSet();
  }

  Future<List<PredefinedTicket>> getAvailableSlots() async {
    final occupied = await getOccupiedSlotIds();
    final all = await getAllActive();
    return all.where((s) => !occupied.contains(s.localId)).toList();
  }

  Future<PredefinedTicket> save(PredefinedTicket ticket) async {
    await _isar.writeTxn(() => _isar.predefinedTickets.put(ticket));
    return ticket;
  }

  Future<void> delete(String localId) async {
    final ticket = await getById(localId);
    if (ticket != null) {
      await _isar.writeTxn(() => _isar.predefinedTickets.put(ticket.markAsDeleted()));
    }
  }

  Future<void> reorder(List<PredefinedTicket> ordered) async {
    await _isar.writeTxn(() async {
      for (var i = 0; i < ordered.length; i++) {
        await _isar.predefinedTickets.put(ordered[i].copyWith(sortOrder: i));
      }
    });
  }
}
