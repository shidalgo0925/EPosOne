import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/cash_register/data/cash_shift_sync_service.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';
import 'package:eposone/src/features/licensing/domain/license_service.dart';
import 'package:eposone/src/features/orders/data/order_repository.dart';
import 'package:eposone/src/features/orders/data/order_service.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_repository.dart';
import 'package:eposone/src/features/platform/domain/en1_bootstrap_models.dart';
import 'package:eposone/src/features/pos/data/repositories/open_ticket_repository.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_operation.dart';

part 'sync_repository.g.dart';

class SyncRunResult {
  final int processed;
  final int succeeded;
  final int failed;

  const SyncRunResult({
    required this.processed,
    required this.succeeded,
    required this.failed,
  });
}

@riverpod
SyncRepository syncRepository(SyncRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return SyncRepository(db);
}

class SyncRepository {
  final Isar _isar;
  SyncRepository(this._isar);

  static const maxAttempts = 5;

  Future<int> countPending() async {
    final ops = await _pendingOperations();
    return ops.length;
  }

  Future<List<SyncOperation>> getRecent({int limit = 50}) async {
    final items =
        await _isar.syncOperations.filter().isDeletedEqualTo(false).findAll();
    // Sin contrato activo: no ensuciar historial.
    items.removeWhere((o) => _isUnsupportedPushKind(o.entityKind));
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  Future<void> enqueuePush(SyncEntityKind kind, String entityLocalId) async {
    // Push activo: Order Domain + Cash Shift HTTP v1.0.
    if (!_isActivePushKind(kind)) return;

    final existing = await _isar.syncOperations
        .filter()
        .entityKindEqualTo(kind)
        .entityLocalIdEqualTo(entityLocalId)
        .operationStatusEqualTo(SyncOperationStatus.pending)
        .isDeletedEqualTo(false)
        .findFirst();
    if (existing != null) return;

    final op = SyncOperation.enqueuePush(
        entityKind: kind, entityLocalId: entityLocalId);
    await _isar.writeTxn(() => _isar.syncOperations.put(op));
  }

  static bool _isActivePushKind(SyncEntityKind kind) =>
      kind == SyncEntityKind.order || kind == SyncEntityKind.cashRegister;

  static bool _isUnsupportedPushKind(SyncEntityKind kind) =>
      kind == SyncEntityKind.sale ||
      kind == SyncEntityKind.customer ||
      kind == SyncEntityKind.cashMovement;

  /// Quita pushes sin contrato activo (Sale legacy, Cliente, Caja) de la cola.
  Future<void> discardSalePushOps() async {
    final all = await _isar.syncOperations
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    final junk = all.where((o) => _isUnsupportedPushKind(o.entityKind)).toList();
    if (junk.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final op in junk) {
        await _isar.syncOperations.put(op.markAsDeleted());
      }
    });
  }

  /// Último error de cola (para UI EN1 Cloud).
  Future<String?> latestQueueError() async {
    final items =
        await _isar.syncOperations.filter().isDeletedEqualTo(false).findAll();
    items.removeWhere((o) => _isUnsupportedPushKind(o.entityKind));
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    for (final op in items) {
      final msg = op.errorMessage?.trim();
      if (msg != null && msg.isNotEmpty) {
        return '${syncEntityKindLabel(op.entityKind)}: $msg';
      }
    }
    return null;
  }

  Future<void> enqueueCatalogPull() async {
    final existing = await _isar.syncOperations
        .filter()
        .entityKindEqualTo(SyncEntityKind.catalogPull)
        .operationStatusEqualTo(SyncOperationStatus.pending)
        .isDeletedEqualTo(false)
        .findFirst();
    if (existing != null) return;

    await _isar.writeTxn(
        () => _isar.syncOperations.put(SyncOperation.enqueueCatalogPull()));
  }

  /// [ensureCatalogPull]: solo si se pide explícitamente (no en sync de pedidos).
  /// El menú Comida/Bar se reconstruye en bootstrap; no mezclar con cola de Orders.
  Future<SyncRunResult> runSyncCycle({
    bool ensureCatalogPull = false,
    En1BootstrapProgressCallback? onProgress,
  }) async {
    final configRepo = BusinessConfigRepository(_isar);
    final config = await configRepo.getConfig();
    if (!config.isEn1SyncReady) {
      throw StateError('Sincronización EN1 no configurada');
    }

    await discardSalePushOps();

    if (ensureCatalogPull) {
      final pendingNow = await _pendingOperations();
      if (pendingNow.isEmpty) {
        await enqueueCatalogPull();
      }
    }

    final pending = await _pendingOperations();
    var succeeded = 0;
    var failed = 0;

    for (final op in pending) {
      if (_isUnsupportedPushKind(op.entityKind)) continue;

      final processing = op.copyWith(
        operationStatus: SyncOperationStatus.processing,
        attemptCount: op.attemptCount + 1,
        updatedAt: DateTime.now(),
      );
      await _isar.writeTxn(() => _isar.syncOperations.put(processing));

      try {
        await _processOperation(config, processing, onProgress: onProgress);
        succeeded++;
      } catch (e) {
        failed++;
        final status = processing.attemptCount >= maxAttempts
            ? SyncOperationStatus.failed
            : SyncOperationStatus.pending;
        await _isar.writeTxn(
          () => _isar.syncOperations.put(
            processing.copyWith(
              operationStatus: status,
              errorMessage: e.toString(),
              processedAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );
      }
    }

    if (succeeded > 0) {
      await configRepo.saveConfig(
        config.copyWith(en1LastSyncAt: DateTime.now()).markAsModified(),
      );
      try {
        await LicenseService().markValidatedFromEn1();
      } catch (_) {}
    }

    // Cobro en EN1 BO: sacar tickets locales (Juanito/Pedrito) de abiertos.
    final commercialEngine = buildCommercialEngine(
      config,
      origin: CommercialDataOrigin.en1,
    );
    await OrderService(
      repository: OrderRepository(
        _isar,
        commercialEngine: commercialEngine,
      ),
      syncRepository: this,
      commercialEngine: commercialEngine,
      openTicketRepository: OpenTicketRepository(_isar),
    ).reconcileOpenTicketsFromEn1(config: config);

    return SyncRunResult(
        processed: pending.length, succeeded: succeeded, failed: failed);
  }

  Future<List<SyncOperation>> _pendingOperations() async {
    final ops = await _isar.syncOperations
        .filter()
        .operationStatusEqualTo(SyncOperationStatus.pending)
        .isDeletedEqualTo(false)
        .findAll();
    ops.removeWhere((o) => _isUnsupportedPushKind(o.entityKind));
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<void> _processOperation(
    BusinessConfig config,
    SyncOperation op, {
    En1BootstrapProgressCallback? onProgress,
  }) async {
    switch (op.entityKind) {
      case SyncEntityKind.sale:
      case SyncEntityKind.customer:
      case SyncEntityKind.cashMovement:
        // Sin contrato: descartados en discardSalePushOps / continue del ciclo.
        return;
      case SyncEntityKind.cashRegister:
        final registerId = op.entityLocalId;
        if (registerId == null || registerId.isEmpty) {
          throw StateError('Turno sin localId en SyncOperation');
        }
        await CashShiftSyncService(
          isar: _isar,
          syncRepository: this,
        ).syncRegisterToEn1(registerId, config: config);
        break;
      case SyncEntityKind.catalogPull:
        await _pullCatalog(config, onProgress: onProgress);
        break;
      case SyncEntityKind.order:
        final orderId = op.entityLocalId;
        if (orderId == null || orderId.isEmpty) {
          throw StateError('Pedido sin localId en SyncOperation');
        }
        final commercialEngine = buildCommercialEngine(
          config,
          origin: CommercialDataOrigin.en1,
        );
        await OrderService(
          repository: OrderRepository(
            _isar,
            commercialEngine: commercialEngine,
          ),
          syncRepository: this,
          commercialEngine: commercialEngine,
          openTicketRepository: OpenTicketRepository(_isar),
        ).syncOrderToEn1(orderId, config: config);
        break;
    }

    await _isar.writeTxn(
      () => _isar.syncOperations.put(
        op.copyWith(
          operationStatus: SyncOperationStatus.completed,
          errorMessage: null,
          processedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  /// Device Bootstrap completo (productos, imágenes, stock, menú POS).
  /// La [SyncOperation] la marca [runSyncCycle]; no duplicar historial aquí.
  Future<void> _pullCatalog(
    BusinessConfig config, {
    En1BootstrapProgressCallback? onProgress,
  }) async {
    await En1BootstrapRepository(isar: _isar).runBootstrap(
      apiBaseUrl: config.en1ApiUrl,
      accessToken: config.en1ApiToken,
      onProgress: onProgress,
      recordInSyncHistory: false,
    );
  }
}
