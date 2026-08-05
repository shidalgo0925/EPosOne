import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/cash_register/data/cash_shift_sync_service.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/caja_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/dispositivos_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/licencias_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/occ_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/pedidos_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/reportes_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/telemetria_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/turnos_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/handlers/ventas_tool_handlers.dart';
import 'package:eposone/src/features/easyai_ops/application/operations_connector.dart';
import 'package:eposone/src/features/easyai_ops/application/ops_auth.dart';
import 'package:eposone/src/features/easyai_ops/domain/ops_auth_result.dart';
import 'package:eposone/src/features/easyai_ops/domain/ops_tool_definition.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/licensing/domain/license_enums.dart';
import 'package:eposone/src/features/licensing/domain/license_service.dart';
import 'package:eposone/src/features/operations_control/application/occ_pulse_provider.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_repository.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_repository.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/pos/data/repositories/open_ticket_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/open_ticket.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_operation.dart';
import 'package:eposone/src/features/sync/presentation/providers/en1_connection_status.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';

/// Connector cableado al dominio (Fase 1–2). EasyAI solo ve Maps estructurados.
final operationsConnectorProvider = Provider<OperationsConnector>((ref) {
  return OperationsConnector(
    occ: OccToolHandlers(
      loadPulse: () => _loadPulseMap(ref),
      loadAlertas: () => _loadAlertasMap(ref),
    ),
    turnos: TurnosToolHandlers(
      loadCurrentShift: () => _loadTurnoActual(ref),
      loadHistorial: (input) => _loadTurnosHistorial(ref, input),
      openTurno: (input, session) => _abrirCaja(ref, input, session),
      closeTurno: (input, session) => _cerrarCaja(ref, input, session),
    ),
    caja: CajaToolHandlers(
      loadEstado: () => _loadCajaEstado(ref),
      loadExpectedCash: () => _loadCajaExpected(ref),
      openCaja: (input, session) => _abrirCaja(ref, input, session),
      closeCaja: (input, session) => _cerrarCaja(ref, input, session),
    ),
    dispositivos: DispositivosToolHandlers(
      loadEste: () => _loadDispositivoEste(ref),
      loadSalud: () => _loadDispositivoSalud(ref),
    ),
    telemetria: TelemetriaToolHandlers(
      loadCola: () => _loadTelemetriaCola(ref),
      loadErrores: () => _loadTelemetriaErrores(ref),
    ),
    licencias: LicenciasToolHandlers(
      loadSnapshot: () => _loadLicencia(ref),
      loadVencimiento: () => _loadLicenciaVencimiento(ref),
    ),
    pedidos: PedidosToolHandlers(
      loadAbiertos: () => _loadPedidosAbiertos(ref),
      loadPorId: (input) => _loadPedidoPorId(ref, input),
      cancelar: (input, session) => _cancelarPedido(ref, input, session),
    ),
    ventas: VentasToolHandlers(
      loadResumenHoy: () => _loadVentasHoy(ref),
    ),
    reportes: ReportesToolHandlers(),
  );
});

/// Auth operacional (PIN / sesión POS) — sin IA.
final opsAuthProvider = Provider<OpsAuth>((ref) {
  final isarAsync = ref.watch(databaseProvider);
  return isarAsync.when(
    data: (isar) => OpsAuth(cashiers: CashierRepository(isar)),
    loading: () => OpsAuth(),
    error: (_, __) => OpsAuth(),
  );
});

/// Autoriza escritura con PIN. Devuelve sesión lista para [OperationsConnector.invoke].
Future<OpsAuthResult> authorizeOpsWithPin(
  Ref ref, {
  required String pin,
  String? cashierId,
  int? cashierContactId,
}) {
  return ref.read(opsAuthProvider).authorizeWithPin(
        pin: pin,
        cashierId: cashierId,
        cashierContactId: cashierContactId,
      );
}

/// Autoriza usando la sesión POS ya logueada (host gate).
OpsAuthResult authorizeOpsFromPosSession(Ref ref) {
  return ref.read(opsAuthProvider).fromPosSession(ref.read(posSessionProvider));
}

Future<Map<String, Object?>> _abrirCaja(
  Ref ref,
  Map<String, Object?> input,
  OpsInvokeSession session,
) async {
  final amount = (input['opening_amount'] as num?)?.toDouble();
  if (amount == null || amount < 0) {
    throw ArgumentError('opening_amount requerido (>= 0)');
  }
  final isar = await ref.read(databaseProvider.future);
  final repo = CashRegisterRepository(isar);
  final register = await repo.openRegister(
    amount,
    openedBy: session.actorName ?? session.actorId,
    cashierId: session.actorId,
    cashierContactId: session.cashierContactId,
  );
  await _enqueueCashShiftSync(ref, isar, register.localId);
  ref.invalidate(currentCashRegisterProvider);
  ref.read(posSessionProvider.notifier).setCashRegister(register.localId);
  return {
    'wired': true,
    'open': true,
    'register_id': register.localId,
    'opening_amount': register.openingAmount,
    'opened_at': register.openDate.toUtc().toIso8601String(),
    'actor_id': session.actorId,
    'actor_name': session.actorName,
  };
}

Future<Map<String, Object?>> _cerrarCaja(
  Ref ref,
  Map<String, Object?> input,
  OpsInvokeSession session,
) async {
  final counted = (input['counted_amount'] as num?)?.toDouble();
  if (counted == null) {
    throw ArgumentError('counted_amount requerido');
  }
  final notes = input['notes'] as String?;
  final isar = await ref.read(databaseProvider.future);
  final repo = CashRegisterRepository(isar);
  final open = await repo.getOpenRegister();
  if (open == null) {
    throw StateError('No hay caja abierta');
  }
  final summary = await ref.read(shiftSummaryProvider(open.localId).future);
  await repo.closeRegister(
    registerId: open.localId,
    closingAmount: counted,
    expectedAmount: summary.expectedCash,
    closedBy: session.actorName ?? session.actorId,
    notes: notes,
  );
  await _enqueueCashShiftSync(ref, isar, open.localId);
  ref.invalidate(currentCashRegisterProvider);
  ref.invalidate(shiftSummaryProvider(open.localId));
  ref.read(posSessionProvider.notifier).clearCashRegister();
  final diff = counted - summary.expectedCash;
  return {
    'wired': true,
    'closed': true,
    'register_id': open.localId,
    'counted_amount': counted,
    'expected_cash': summary.expectedCash,
    'difference': diff,
    'has_descuadre': diff.abs() > 0.009,
    'actor_id': session.actorId,
    'actor_name': session.actorName,
  };
}

Future<void> _enqueueCashShiftSync(
  Ref ref,
  Isar isar,
  String registerLocalId,
) async {
  final config = await BusinessConfigRepository(isar).getConfig();
  if (!config.isEn1SyncReady) return;
  final sync = SyncRepository(isar);
  final shiftSync = CashShiftSyncService(isar: isar, syncRepository: sync);
  await shiftSync.enqueueIfReady(registerLocalId, config);
  try {
    await sync.runSyncCycle();
  } catch (_) {}
}

Future<Map<String, Object?>> _cancelarPedido(
  Ref ref,
  Map<String, Object?> input,
  OpsInvokeSession session,
) async {
  final ticketId = (input['ticket_id'] as String?)?.trim();
  if (ticketId == null || ticketId.isEmpty) {
    throw ArgumentError('ticket_id requerido');
  }
  final reason = input['reason'] as String?;
  final isar = await ref.read(databaseProvider.future);
  final repo = OpenTicketRepository(isar);
  final ticket = await repo.getById(ticketId);
  if (ticket == null) {
    throw StateError('Ticket no encontrado');
  }
  if (ticket.status != OpenTicketStatus.open) {
    throw StateError('Ticket no está abierto');
  }
  final comment = reason == null || reason.trim().isEmpty
      ? ticket.comment
      : 'Cancelado EasyAI: ${reason.trim()}'
          '${ticket.comment != null ? ' · ${ticket.comment}' : ''}';
  await repo.markTicketCancelled(ticketId, comment: comment);
  return {
    'wired': true,
    'cancelled': true,
    'ticket_id': ticketId,
    'actor_id': session.actorId,
    'actor_name': session.actorName,
  };
}

Future<Map<String, Object?>> _loadPedidoPorId(
  Ref ref,
  Map<String, Object?> input,
) async {
  final ticketId = (input['ticket_id'] as String?)?.trim();
  if (ticketId == null || ticketId.isEmpty) {
    throw ArgumentError('ticket_id requerido');
  }
  final isar = await ref.read(databaseProvider.future);
  final ticket = await OpenTicketRepository(isar).getById(ticketId);
  if (ticket == null) {
    return {'wired': true, 'found': false, 'ticket_id': ticketId};
  }
  return {
    'wired': true,
    'found': true,
    'ticket': {
      'id': ticket.localId,
      'label': ticket.label,
      'status': ticket.status.name,
      'order_type': ticket.orderType.name,
      'saved_at': ticket.savedAt.toUtc().toIso8601String(),
      'customer_id': ticket.customerId,
      'linked_order_id': ticket.linkedOrderLocalId,
      'comment': ticket.comment,
    },
  };
}

Future<Map<String, Object?>> _loadTurnosHistorial(
  Ref ref,
  Map<String, Object?> input,
) async {
  final limitRaw = input['limit'];
  final limit = limitRaw is int
      ? limitRaw.clamp(1, 50)
      : (limitRaw is num ? limitRaw.toInt().clamp(1, 50) : 10);
  final isar = await ref.read(databaseProvider.future);
  final items = await CashRegisterRepository(isar).getAllRegisters(limit: limit);
  return {
    'wired': true,
    'count': items.length,
    'items': [
      for (final r in items)
        {
          'register_id': r.localId,
          'status': r.status.name,
          'open': r.isOpen,
          'opened_at': r.openDate.toUtc().toIso8601String(),
          'closed_at': r.closeDate?.toUtc().toIso8601String(),
          'opening_amount': r.openingAmount,
          'closing_amount': r.closingAmount,
          'expected_amount': r.expectedAmount,
          'difference': r.difference,
          'cashier_name': r.currentCashierName ?? r.openedBy,
        },
    ],
  };
}

Future<Map<String, Object?>> _loadPulseMap(Ref ref) async {
  final p = await ref.read(occPulseProvider.future);
  return {
    'wired': true,
    'shift_open': p.shiftOpen,
    'shift_label': p.shiftLabel,
    'open_tickets': p.openTickets,
    'pending_sync': p.pendingSync,
    'failed_sync': p.failedSync,
    'link_label': p.linkLabel,
    'license_label': p.licenseLabel,
    'attention_count': p.attentionCount,
    'bootstrap_error': p.bootstrapError,
    'sync_error': p.syncError,
    'provisioning_error': p.provisioningError,
    'cashier_name': p.cashierName,
    'generated_at': p.generatedAt?.toUtc().toIso8601String(),
  };
}

Future<Map<String, Object?>> _loadAlertasMap(Ref ref) async {
  final p = await ref.read(occPulseProvider.future);
  final alerts = <Map<String, Object?>>[];
  if (p.pendingSync > 0) {
    alerts.add({'code': 'sync_pending', 'detail': '${p.pendingSync} pendientes'});
  }
  if (p.failedSync > 0) {
    alerts.add({'code': 'sync_failed', 'detail': '${p.failedSync} fallidos'});
  }
  if (p.bootstrapError != null && p.bootstrapError!.isNotEmpty) {
    alerts.add({'code': 'bootstrap', 'detail': p.bootstrapError});
  }
  if (p.provisioningError != null && p.provisioningError!.isNotEmpty) {
    alerts.add({'code': 'provisioning', 'detail': p.provisioningError});
  }
  if (p.syncError != null && p.syncError!.isNotEmpty) {
    alerts.add({'code': 'sync', 'detail': p.syncError});
  }
  if (p.linkLabel.toLowerCase().contains('offline')) {
    alerts.add({'code': 'en1_offline', 'detail': p.linkLabel});
  }
  final lic = p.licenseLabel.toLowerCase();
  if (lic.contains('gracia') || lic.contains('expir') || lic.contains('suspend')) {
    alerts.add({'code': 'license', 'detail': p.licenseLabel});
  }
  return {
    'wired': true,
    'count': alerts.length,
    'alerts': alerts,
    'attention_count': p.attentionCount,
  };
}

Future<Map<String, Object?>> _loadTurnoActual(Ref ref) async {
  final isar = await ref.read(databaseProvider.future);
  final open = await CashRegisterRepository(isar).getOpenRegister();
  if (open == null) {
    return {'wired': true, 'open': false};
  }
  return {
    'wired': true,
    'open': open.isOpen,
    'register_id': open.localId,
    'opened_at': open.openDate.toUtc().toIso8601String(),
    'opening_amount': open.openingAmount,
    'cashier_name': open.currentCashierName ?? open.openedBy,
    'cashier_id': open.currentCashierId ?? open.openedByCashierId,
  };
}

Future<Map<String, Object?>> _loadCajaEstado(Ref ref) async {
  final turno = await _loadTurnoActual(ref);
  if (turno['open'] != true) {
    return {...turno, 'expected_cash': null, 'sale_count': 0};
  }
  final registerId = turno['register_id']! as String;
  final summary = await ref.read(shiftSummaryProvider(registerId).future);
  return {
    ...turno,
    'expected_cash': summary.expectedCash,
    'gross_sales': summary.grossSales,
    'sale_count': summary.saleCount,
    'cash_from_sales': summary.cashFromSales,
    'cash_in': summary.cashMovementIn,
    'cash_out': summary.cashMovementOut,
  };
}

Future<Map<String, Object?>> _loadCajaExpected(Ref ref) async {
  final estado = await _loadCajaEstado(ref);
  return {
    'wired': true,
    'open': estado['open'] == true,
    'register_id': estado['register_id'],
    'expected_cash': estado['expected_cash'],
    'opening_amount': estado['opening_amount'],
  };
}

Future<Map<String, Object?>> _loadDispositivoEste(Ref ref) async {
  final pkg = await PackageInfo.fromPlatform();
  final appVersion = '${pkg.version}+${pkg.buildNumber}';
  final device = await DeviceRegistry.snapshot(appVersion: appVersion);
  final mode = await PlatformPrefs.getMode();
  final repo = En1ProvisioningRepository();
  final status = await repo.getStatus();
  final config = await repo.getConfig();
  return {
    'wired': true,
    'uuid': device.uuid,
    'device_name': device.deviceName,
    'app_version': device.appVersion,
    'platform': device.platform,
    'os': device.os,
    'mode': mode.name,
    'connection_status': status.name,
    'organization_id': config?.organizationId,
    'branch_id': config?.branchRef,
    'pos_id': config?.posId,
    'timezone': config?.timezone ?? En1DateTimeService.en1TimezoneId,
  };
}

Future<Map<String, Object?>> _loadDispositivoSalud(Ref ref) async {
  final isar = await ref.read(databaseProvider.future);
  final boot = En1BootstrapRepository(isar: isar);
  final bootstrapDone = await boot.isBootstrapDone();
  final bootstrapError = await boot.lastBootstrapError();
  final provisioningError = await En1ProvisioningRepository().getLastError();
  final cola = await _loadTelemetriaCola(ref);
  En1StatusSnapshot? en1;
  try {
    en1 = await ref.read(en1StatusSnapshotProvider.future);
  } catch (_) {}
  final issues = <String>[];
  if (bootstrapError != null && bootstrapError.isNotEmpty) {
    issues.add('bootstrap: $bootstrapError');
  }
  if (provisioningError != null && provisioningError.isNotEmpty) {
    issues.add('provisioning: $provisioningError');
  }
  if ((cola['failed'] as int? ?? 0) > 0) {
    issues.add('sync_failed: ${cola['failed']}');
  }
  if (en1?.link == En1LinkState.offline) {
    issues.add('en1_offline');
  }
  if (!bootstrapDone && en1?.link != En1LinkState.unknown) {
    issues.add('bootstrap_pending');
  }
  return {
    'wired': true,
    'healthy': issues.isEmpty,
    'bootstrap_done': bootstrapDone,
    'link': en1?.link.name,
    'pending_sync': cola['pending'],
    'failed_sync': cola['failed'],
    'issues': issues,
    'issue_count': issues.length,
  };
}

Future<Map<String, Object?>> _loadTelemetriaCola(Ref ref) async {
  final isar = await ref.read(databaseProvider.future);
  final pendingCount = await ref.read(syncPendingCountProvider.future);
  final pendingList = await isar.syncOperations
      .filter()
      .operationStatusEqualTo(SyncOperationStatus.pending)
      .findAll();
  final failedList = await isar.syncOperations
      .filter()
      .operationStatusEqualTo(SyncOperationStatus.failed)
      .findAll();
  final byKind = <String, int>{};
  for (final op in pendingList) {
    final label = syncEntityKindLabel(op.entityKind);
    byKind[label] = (byKind[label] ?? 0) + 1;
  }
  En1StatusSnapshot? en1;
  try {
    en1 = await ref.read(en1StatusSnapshotProvider.future);
  } catch (_) {}
  return {
    'wired': true,
    'pending': en1?.pendingOrders ?? pendingCount,
    'failed': failedList.length,
    'by_kind': byKind,
    'last_sync_at': en1?.lastSyncAt?.toUtc().toIso8601String(),
    'link': en1?.link.name,
  };
}

Future<Map<String, Object?>> _loadTelemetriaErrores(Ref ref) async {
  final isar = await ref.read(databaseProvider.future);
  final boot = En1BootstrapRepository(isar: isar);
  final bootstrapError = await boot.lastBootstrapError();
  final provisioningError = await En1ProvisioningRepository().getLastError();
  final failedList = await isar.syncOperations
      .filter()
      .operationStatusEqualTo(SyncOperationStatus.failed)
      .sortByUpdatedAtDesc()
      .limit(10)
      .findAll();
  final errors = <Map<String, Object?>>[
    if (bootstrapError != null && bootstrapError.isNotEmpty)
      {'source': 'bootstrap', 'message': bootstrapError},
    if (provisioningError != null && provisioningError.isNotEmpty)
      {'source': 'provisioning', 'message': provisioningError},
    for (final op in failedList)
      {
        'source': 'sync',
        'entity_kind': syncEntityKindLabel(op.entityKind),
        'message': op.errorMessage ?? 'error',
        'updated_at': op.updatedAt.toUtc().toIso8601String(),
      },
  ];
  return {
    'wired': true,
    'count': errors.length,
    'errors': errors,
  };
}

Future<Map<String, Object?>> _loadLicencia(Ref ref) async {
  final snap = await LicenseService().load();
  final val = await LicenseService().validate();
  if (snap == null) {
    return {
      'wired': true,
      'present': false,
      'effective_status': val.effectiveStatus.code,
      'message': 'Sin snapshot de licencia',
    };
  }
  return {
    'wired': true,
    'present': true,
    'license_type': snap.licenseType.code,
    'plan_code': snap.planCode,
    'status': snap.status.code,
    'effective_status': val.effectiveStatus.code,
    'expires_at': snap.expiresAt?.toUtc().toIso8601String(),
    'grace_until': snap.graceUntil?.toUtc().toIso8601String(),
    'last_validation': snap.lastValidation?.toUtc().toIso8601String(),
    'organization_id': snap.organizationId,
    'branch_id': snap.branchId,
    'source': snap.source,
  };
}

Future<Map<String, Object?>> _loadLicenciaVencimiento(Ref ref) async {
  final snap = await LicenseService().load();
  final val = await LicenseService().validate();
  final status = val.effectiveStatus;
  final risk = switch (status) {
    LicenseStatus.expired ||
    LicenseStatus.revoked ||
    LicenseStatus.suspended =>
      'high',
    LicenseStatus.grace => 'medium',
    LicenseStatus.active || LicenseStatus.pending => 'low',
    LicenseStatus.unknown => 'unknown',
  };
  int? daysToExpiry;
  if (snap?.expiresAt != null) {
    daysToExpiry =
        snap!.expiresAt!.toUtc().difference(En1DateTimeService.nowUtc()).inDays;
  }
  return {
    'wired': true,
    'present': snap != null,
    'effective_status': status.code,
    'risk': risk,
    'at_risk': risk == 'medium' || risk == 'high',
    'days_to_expiry': daysToExpiry,
    'expires_at': snap?.expiresAt?.toUtc().toIso8601String(),
    'grace_until': snap?.graceUntil?.toUtc().toIso8601String(),
    'can_operate': val.canOperatePos,
  };
}

Future<Map<String, Object?>> _loadPedidosAbiertos(Ref ref) async {
  final isar = await ref.read(databaseProvider.future);
  final tickets = await OpenTicketRepository(isar).getAllOpenTickets();
  return {
    'wired': true,
    'count': tickets.length,
    'tickets': [
      for (final t in tickets)
        {
          'id': t.localId,
          'label': t.label,
          'order_type': t.orderType.name,
          'saved_at': t.savedAt.toUtc().toIso8601String(),
          'customer_id': t.customerId,
          'linked_order_id': t.linkedOrderLocalId,
        },
    ],
  };
}

Future<Map<String, Object?>> _loadVentasHoy(Ref ref) async {
  final isar = await ref.read(databaseProvider.future);
  En1DateTimeService.ensureInitialized();
  final nowLocal = En1DateTimeService.toBusinessLocal(En1DateTimeService.nowUtc());
  final loc = nowLocal.location;
  final startLocal = tz.TZDateTime(loc, nowLocal.year, nowLocal.month, nowLocal.day);
  final endLocal = startLocal.add(const Duration(days: 1));
  final sales = await SaleRepository(isar).getAllSales(
    from: startLocal.toUtc(),
    to: endLocal.toUtc(),
  );
  final completed =
      sales.where((s) => s.status == SaleStatus.completed).toList();
  final refunded =
      sales.where((s) => s.status == SaleStatus.refunded).toList();
  var gross = 0.0;
  var tips = 0.0;
  for (final s in completed) {
    gross += s.total;
    tips += s.tipAmount;
  }
  var refundTotal = 0.0;
  for (final s in refunded) {
    refundTotal += s.total;
  }
  return {
    'wired': true,
    'business_date':
        '${nowLocal.year.toString().padLeft(4, '0')}-'
        '${nowLocal.month.toString().padLeft(2, '0')}-'
        '${nowLocal.day.toString().padLeft(2, '0')}',
    'timezone': En1DateTimeService.en1TimezoneId,
    'sale_count': completed.length,
    'refund_count': refunded.length,
    'gross_total': gross,
    'refund_total': refundTotal,
    'net_total': gross - refundTotal,
    'tips_total': tips,
  };
}
