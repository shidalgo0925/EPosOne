import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';

enum OpenTicketsScope { mine, all }

/// Autoría de tickets abiertos: el pedido es de la org, el creador no se pierde.
class OpenTicketAuthorship {
  OpenTicketAuthorship._();

  static bool isMine(OpenTicket ticket, PosSession? session) {
    if (session == null) return false;
    final id = ticket.cashierId?.trim();
    if (id == null || id.isEmpty) return false;
    if (id == session.cashierId) return true;
    final contact = session.cashierContactId;
    if (contact != null && id == 'en1_cashier_$contact') return true;
    return false;
  }

  static List<OpenTicket> visible({
    required List<OpenTicket> all,
    required OpenTicketsScope scope,
    required PosSession? session,
  }) {
    if (scope == OpenTicketsScope.all) return all;
    return all.where((t) => isMine(t, session)).toList();
  }
}
