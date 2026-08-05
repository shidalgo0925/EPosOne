import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/core/utils/pin_hash.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/easyai_ops/domain/ops_auth_result.dart';
import 'package:eposone/src/features/easyai_ops/domain/ops_tool_definition.dart';
import 'package:eposone/src/features/platform/data/en1_cashier_catalog_store.dart';

/// Autorización operacional para verbos de escritura (ADR-017 Fase 2).
///
/// No desarrolla IA. Solo valida PIN / sesión POS y emite [OpsInvokeSession].
class OpsAuth {
  OpsAuth({CashierRepository? cashiers}) : _cashiers = cashiers;

  final CashierRepository? _cashiers;

  /// Marca sesión autorizada a partir de [PosSession] ya logueada (host gate).
  OpsAuthResult fromPosSession(
    PosSession? pos, {
    String channel = 'easyai',
  }) {
    if (pos == null || !pos.isLoggedIn) {
      return OpsAuthResult.failure(
        code: 'session_required',
        message: 'No hay cajero en sesión POS',
      );
    }
    return OpsAuthResult.success(
      OpsInvokeSession(
        actorId: pos.cashierId,
        actorName: pos.cashierName,
        role: pos.role.name,
        cashierContactId: pos.cashierContactId,
        channel: channel,
        authorized: true,
        authMethod: 'session',
      ),
    );
  }

  /// Verifica PIN de cajero local o EN1 y emite sesión autorizada.
  Future<OpsAuthResult> authorizeWithPin({
    required String pin,
    String? cashierId,
    int? cashierContactId,
    String channel = 'easyai',
  }) async {
    final trimmed = pin.trim();
    if (trimmed.length < 4) {
      return OpsAuthResult.failure(
        code: 'pin_incomplete',
        message: 'PIN incompleto',
      );
    }

    if (cashierContactId != null) {
      final ok = await En1CashierCatalogStore.verifyPin(
        cashierContactId: cashierContactId,
        pin: trimmed,
      );
      if (!ok) {
        return OpsAuthResult.failure(
          code: 'pin_invalid',
          message: 'PIN incorrecto',
        );
      }
      final meta = await En1CashierCatalogStore.getWithVerifier(cashierContactId);
      return OpsAuthResult.success(
        OpsInvokeSession(
          actorId: 'en1_$cashierContactId',
          actorName: meta?.cashierName ?? 'EN1 $cashierContactId',
          role: 'cashier',
          cashierContactId: cashierContactId,
          channel: channel,
          authorized: true,
          authMethod: 'pin',
        ),
      );
    }

    if (cashierId == null || cashierId.isEmpty) {
      return OpsAuthResult.failure(
        code: 'actor_required',
        message: 'Indique cashier_id o cashier_contact_id',
      );
    }

    if (cashierId.startsWith('en1_')) {
      final raw = int.tryParse(cashierId.substring(4));
      if (raw == null) {
        return OpsAuthResult.failure(
          code: 'actor_invalid',
          message: 'cashier_id EN1 inválido',
        );
      }
      return authorizeWithPin(
        pin: trimmed,
        cashierContactId: raw,
        channel: channel,
      );
    }

    final repo = _cashiers;
    if (repo == null) {
      return OpsAuthResult.failure(
        code: 'auth_unavailable',
        message: 'Repositorio de cajeros no inyectado',
      );
    }
    final cashier = await repo.getById(cashierId);
    if (cashier == null || !cashier.active) {
      return OpsAuthResult.failure(
        code: 'actor_not_found',
        message: 'Cajero no encontrado o inactivo',
      );
    }
    final ok = await PinVerifier.verify(trimmed, cashier.pinHash);
    if (!ok) {
      return OpsAuthResult.failure(
        code: 'pin_invalid',
        message: 'PIN incorrecto',
      );
    }
    return OpsAuthResult.success(
      OpsInvokeSession(
        actorId: cashier.localId,
        actorName: cashier.name,
        role: cashier.role == CashierRole.admin ? 'admin' : 'cashier',
        channel: channel,
        authorized: true,
        authMethod: 'pin',
      ),
    );
  }
}
