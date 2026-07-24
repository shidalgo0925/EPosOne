import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';

class PosSession {
  final String cashierId;
  final String cashierName;
  final CashierRole role;
  /// EN1 `cashier_contact_id` (Hito 2.5). Null en modo local puro.
  final int? cashierContactId;
  final String? cashRegisterId;
  final DateTime loggedInAt;
  final DateTime lastActivityAt;

  const PosSession({
    required this.cashierId,
    required this.cashierName,
    required this.role,
    this.cashierContactId,
    this.cashRegisterId,
    required this.loggedInAt,
    required this.lastActivityAt,
  });

  bool get isLoggedIn => cashierId.isNotEmpty;

  PosSession copyWith({
    String? cashierId,
    String? cashierName,
    CashierRole? role,
    int? cashierContactId,
    String? cashRegisterId,
    DateTime? loggedInAt,
    DateTime? lastActivityAt,
    bool clearCashRegister = false,
    bool clearContactId = false,
  }) =>
      PosSession(
        cashierId: cashierId ?? this.cashierId,
        cashierName: cashierName ?? this.cashierName,
        role: role ?? this.role,
        cashierContactId:
            clearContactId ? null : (cashierContactId ?? this.cashierContactId),
        cashRegisterId: clearCashRegister ? null : (cashRegisterId ?? this.cashRegisterId),
        loggedInAt: loggedInAt ?? this.loggedInAt,
        lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      );
}

class PosSessionNotifier extends StateNotifier<PosSession?> {
  PosSessionNotifier() : super(null);

  void login(Cashier cashier, {int? cashierContactId}) {
    state = PosSession(
      cashierId: cashier.localId,
      cashierName: cashier.name,
      role: cashier.role,
      cashierContactId: cashierContactId,
      loggedInAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
    );
  }

  void setCashRegister(String registerId) {
    if (state == null) return;
    state = state!.copyWith(cashRegisterId: registerId, lastActivityAt: DateTime.now());
  }

  void clearCashRegister() {
    if (state == null) return;
    state = state!.copyWith(clearCashRegister: true, lastActivityAt: DateTime.now());
  }

  void touch() {
    if (state == null) return;
    state = state!.copyWith(lastActivityAt: DateTime.now());
  }

  /// Bloquear pantalla: limpia cajero, mantiene caja abierta en BD.
  void lock() => state = null;

  void logout() => state = null;
}

final posSessionProvider = StateNotifierProvider<PosSessionNotifier, PosSession?>((ref) {
  return PosSessionNotifier();
});
