import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/licensing/domain/license_enums.dart';
import 'package:eposone/src/features/licensing/domain/license_service.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_repository.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_repository.dart';
import 'package:eposone/src/features/pos/data/repositories/open_ticket_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_operation.dart';
import 'package:eposone/src/features/sync/presentation/providers/en1_connection_status.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';
import 'package:isar/isar.dart';

/// Snapshot operacional for OCC Fase A (ADR-016). Not a report.
class OccPulse {
  const OccPulse({
    required this.shiftOpen,
    required this.shiftLabel,
    required this.openTickets,
    required this.pendingSync,
    required this.failedSync,
    required this.linkLabel,
    required this.licenseLabel,
    required this.attentionCount,
    this.bootstrapError,
    this.syncError,
    this.provisioningError,
    this.cashierName,
    this.generatedAt,
  });

  final bool shiftOpen;
  final String shiftLabel;
  final int openTickets;
  final int pendingSync;
  final int failedSync;
  final String linkLabel;
  final String licenseLabel;
  final int attentionCount;
  final String? bootstrapError;
  final String? syncError;
  final String? provisioningError;
  final String? cashierName;
  final DateTime? generatedAt;
}

final occPulseProvider = FutureProvider.autoDispose<OccPulse>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  final session = ref.watch(posSessionProvider);
  final openReg = await CashRegisterRepository(isar).getOpenRegister();
  final openTickets = await OpenTicketRepository(isar).countOpenTickets();
  final pending = await ref.watch(syncPendingCountProvider.future);

  final failedList = await isar.syncOperations
      .filter()
      .operationStatusEqualTo(SyncOperationStatus.failed)
      .sortByUpdatedAtDesc()
      .findAll();

  En1StatusSnapshot? en1;
  try {
    en1 = await ref.watch(en1StatusSnapshotProvider.future);
  } catch (_) {}

  final boot = En1BootstrapRepository(isar: isar);
  final bootstrapError = await boot.lastBootstrapError();
  final provisioningError = await En1ProvisioningRepository().getLastError();
  final syncError = failedList.isEmpty
      ? null
      : '${syncEntityKindLabel(failedList.first.entityKind)}: '
          '${failedList.first.errorMessage ?? 'error'}';

  final licenseVal = await LicenseService().validate();
  final licenseSnap = await LicenseService().load();
  final licenseLabel = licenseSnap == null
      ? 'Sin snapshot'
      : '${licenseSnap.licenseType.label} · ${licenseVal.effectiveStatus.label}';

  final link = en1?.link ?? En1LinkState.unknown;
  final linkLabel = switch (link) {
    En1LinkState.connected => 'EN1 conectado',
    En1LinkState.offline => 'EN1 offline',
    En1LinkState.syncing => 'EN1 sincronizando',
    En1LinkState.unknown => 'EN1 desconocido',
  };

  var attention = 0;
  if (failedList.isNotEmpty) attention++;
  if (bootstrapError != null && bootstrapError.isNotEmpty) attention++;
  if (provisioningError != null && provisioningError.isNotEmpty) attention++;
  if (pending > 0) attention++;
  if (link == En1LinkState.offline) attention++;
  if (licenseVal.effectiveStatus == LicenseStatus.expired ||
      licenseVal.effectiveStatus == LicenseStatus.grace ||
      licenseVal.effectiveStatus == LicenseStatus.suspended) {
    attention++;
  }

  final shiftOpen = openReg != null && openReg.isOpen;
  final shiftLabel = !shiftOpen
      ? 'Sin turno abierto'
      : 'Turno abierto · ${En1DateTimeService.formatLocal(openReg.openDate)}';

  return OccPulse(
    shiftOpen: shiftOpen,
    shiftLabel: shiftLabel,
    openTickets: openTickets,
    pendingSync: en1?.pendingOrders ?? pending,
    failedSync: failedList.length,
    linkLabel: linkLabel,
    licenseLabel: licenseLabel,
    attentionCount: attention,
    bootstrapError: bootstrapError,
    syncError: syncError,
    provisioningError: provisioningError,
    cashierName: session?.cashierName,
    generatedAt: En1DateTimeService.nowUtc(),
  );
});
