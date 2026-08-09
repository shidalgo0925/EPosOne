import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/cash_register/data/en1_cash_shift_api.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';

/// Push apertura/cierre de turno — contrato Cash Shift HTTP v1.0.
class CashShiftSyncService {
  CashShiftSyncService({
    required Isar isar,
    required SyncRepository syncRepository,
    En1CashShiftApi? api,
  })  : _repo = CashRegisterRepository(isar),
        _sync = syncRepository,
        _api = api ?? En1CashShiftApi();

  final CashRegisterRepository _repo;
  final SyncRepository _sync;
  final En1CashShiftApi _api;

  /// Encola push si EN1 sync está listo. No falla la operación local.
  ///
  /// Si falta `cashier_contact_id` se registra en log y **no** se encola
  /// (el HTTP fallaría); hay que reintentar tras login EN1 (PIN Hito 2.5).
  Future<bool> enqueueIfReady(
    String registerLocalId,
    BusinessConfig config,
  ) async {
    if (!config.isEn1SyncReady) {
      debugPrint(
        '[CashShift] skip enqueue: isEn1SyncReady=false '
        '(register=$registerLocalId)',
      );
      return false;
    }
    final register = await _repo.getRegisterById(registerLocalId);
    if (register == null) {
      debugPrint(
        '[CashShift] skip enqueue: register not found ($registerLocalId)',
      );
      return false;
    }
    final contactId =
        register.currentCashierContactId ?? register.openedByCashierContactId;
    if (contactId == null) {
      debugPrint(
        '[CashShift] skip enqueue: cashier_contact_id missing '
        '(register=$registerLocalId status=${register.status.name} '
        'serverId=${register.serverId}). Use cajero EN1 (Hito 2.5).',
      );
      return false;
    }
    await _sync.enqueuePush(SyncEntityKind.cashRegister, registerLocalId);
    debugPrint(
      '[CashShift] enqueued client_shift_id=$registerLocalId '
      'contact=$contactId status=${register.status.name} '
      'serverId=${register.serverId}',
    );
    return true;
  }

  /// Encola (si listo) e intenta un `runSyncCycle` inmediato.
  /// Errores de red/sync no fallan la operación local (reintento auto 30s).
  Future<bool> enqueueAndKickSync(
    String registerLocalId,
    BusinessConfig config,
  ) async {
    final enqueued = await enqueueIfReady(registerLocalId, config);
    if (!enqueued) return false;
    try {
      await _sync.runSyncCycle();
    } catch (e) {
      debugPrint('[CashShift] runSyncCycle deferred: $e');
    }
    return true;
  }

  /// Procesa un turno pendiente: abre y/o cierra según estado local.
  Future<void> syncRegisterToEn1(
    String registerLocalId, {
    required BusinessConfig config,
  }) async {
    final register = await _repo.getRegisterById(registerLocalId);
    if (register == null) {
      throw StateError('Turno local no encontrado: $registerLocalId');
    }

    var current = register;
    if (current.serverId == null || current.serverId!.trim().isEmpty) {
      current = await _pushOpen(current, config: config);
    }

    if (current.status == CashRegisterStatus.closed) {
      await _pushClose(current, config: config);
    }
  }

  Future<CashRegister> _pushOpen(
    CashRegister register, {
    required BusinessConfig config,
  }) async {
    final contactId = register.openedByCashierContactId ??
        register.currentCashierContactId;
    if (contactId == null) {
      throw En1CashShiftException(
        code: 'cashier_contact_id_required',
        message: 'Abrir turno EN1 requiere cashier_contact_id (login cajero Hito 2.5).',
        statusCode: 400,
      );
    }

    final body = <String, dynamic>{
      'client_shift_id': register.localId,
      'cashier_contact_id': contactId,
      if ((register.openedBy ?? register.currentCashierName)?.trim().isNotEmpty == true)
        'cashier_name': (register.openedBy ?? register.currentCashierName)!.trim(),
      'opening_float': register.openingAmount,
      'opened_at': En1DateTimeService.toUtcIso(register.openDate),
    };

    Map<String, dynamic> shift;
    try {
      shift = await _api.openShift(
        body,
        idempotencyKey: register.localId,
        config: config,
      );
    } on En1CashShiftException catch (e) {
      if (e.code == 'shift_already_open' || e.statusCode == 409) {
        final remote = await _api.getCurrent(config: config);
        if (remote != null &&
            remote['client_shift_id']?.toString() == register.localId) {
          shift = remote;
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final shiftId = shift['shift_id'];
    if (shiftId == null) {
      throw En1CashShiftException(
        code: 'validation',
        message: 'Apertura EN1 sin shift_id.',
        technicalDetail: shift.toString(),
      );
    }

    final synced = register.markAsSynced(shiftId.toString());
    await _repo.saveRegister(synced);
    debugPrint(
      '[CashShift] OPEN OK client_shift_id=${register.localId} '
      'shift_id=$shiftId contact=$contactId',
    );
    return synced;
  }

  Future<void> _pushClose(
    CashRegister register, {
    required BusinessConfig config,
  }) async {
    final shiftId = int.tryParse(register.serverId?.trim() ?? '');
    if (shiftId == null) {
      throw En1CashShiftException(
        code: 'shift_not_found',
        message: 'Cierre EN1 sin shift_id local. Reintentar sync de apertura.',
        statusCode: 404,
      );
    }

    final contactId = register.currentCashierContactId ??
        register.openedByCashierContactId;
    if (contactId == null) {
      throw En1CashShiftException(
        code: 'cashier_contact_id_required',
        message: 'Cerrar turno EN1 requiere cashier_contact_id.',
        statusCode: 400,
      );
    }

    final counted = register.closingAmount;
    if (counted == null) {
      throw En1CashShiftException(
        code: 'counted_amount_required',
        message: 'Cierre EN1 requiere efectivo contado.',
        statusCode: 400,
      );
    }

    final body = <String, dynamic>{
      'cashier_contact_id': contactId,
      'counted_amount': counted,
      if (register.notes != null && register.notes!.trim().isNotEmpty)
        'notes': register.notes!.trim(),
      if (register.closeDate != null)
        'closed_at': En1DateTimeService.toUtcIso(register.closeDate!),
    };

    await _api.closeShift(shiftId, body, config: config);
    await _repo.saveRegister(register.markAsSynced(register.serverId!));
    debugPrint(
      '[CashShift] CLOSE OK client_shift_id=${register.localId} '
      'shift_id=$shiftId counted=$counted contact=$contactId '
      'closed_at=${register.closeDate}',
    );
  }
}
