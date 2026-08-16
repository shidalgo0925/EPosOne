import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/pos/domain/open_ticket_authorship.dart';
import 'package:flutter_test/flutter_test.dart';

OpenTicket _ticket({required String id, String? cashierId}) {
  final now = DateTime(2026, 8, 16);
  return OpenTicket(
    localId: id,
    createdAt: now,
    updatedAt: now,
    savedAt: now,
    cashierId: cashierId,
  );
}

PosSession _session({required String cashierId, int? contactId}) {
  final now = DateTime(2026, 8, 16);
  return PosSession(
    cashierId: cashierId,
    cashierName: 'Ana',
    role: CashierRole.cashier,
    cashierContactId: contactId,
    loggedInAt: now,
    lastActivityAt: now,
  );
}

void main() {
  test('Mis pedidos only includes tickets of the logged cashier', () {
    final session = _session(cashierId: 'c-ana');
    final all = [
      _ticket(id: '1', cashierId: 'c-ana'),
      _ticket(id: '2', cashierId: 'c-maria'),
      _ticket(id: '3'),
    ];
    final mine = OpenTicketAuthorship.visible(
      all: all,
      scope: OpenTicketsScope.mine,
      session: session,
    );
    expect(mine.map((t) => t.localId), ['1']);
  });

  test('Todos keeps every ticket including other waiters', () {
    final session = _session(cashierId: 'c-ana');
    final all = [
      _ticket(id: '1', cashierId: 'c-ana'),
      _ticket(id: '2', cashierId: 'c-maria'),
    ];
    final visible = OpenTicketAuthorship.visible(
      all: all,
      scope: OpenTicketsScope.all,
      session: session,
    );
    expect(visible.length, 2);
  });

  test('EN1 cashier_contact alias matches mine', () {
    final session = _session(cashierId: 'local-1', contactId: 44);
    expect(
      OpenTicketAuthorship.isMine(
        _ticket(id: '1', cashierId: 'en1_cashier_44'),
        session,
      ),
      isTrue,
    );
  });
}
