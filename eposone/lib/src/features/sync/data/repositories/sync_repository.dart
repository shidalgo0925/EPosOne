import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/orders/data/order_repository.dart';
import 'package:eposone/src/features/orders/data/order_service.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_repository.dart';
import 'package:eposone/src/features/platform/domain/en1_bootstrap_models.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/data/adapters/en1_api_adapter.dart';
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
    final items = await _isar.syncOperations.filter().isDeletedEqualTo(false).findAll();
    // Hito 3: push Sale no aplica — no ensuciar historial.
    items.removeWhere((o) => o.entityKind == SyncEntityKind.sale);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  Future<void> enqueuePush(SyncEntityKind kind, String entityLocalId) async {
    // Hito 3C: Order Domain (/api/v1/orders*), no Sale push.
    if (kind == SyncEntityKind.sale) return;

    final existing = await _isar.syncOperations
        .filter()
        .entityKindEqualTo(kind)
        .entityLocalIdEqualTo(entityLocalId)
        .operationStatusEqualTo(SyncOperationStatus.pending)
        .isDeletedEqualTo(false)
        .findFirst();
    if (existing != null) return;

    final op = SyncOperation.enqueuePush(entityKind: kind, entityLocalId: entityLocalId);
    await _isar.writeTxn(() => _isar.syncOperations.put(op));
  }

  /// Quita ops Sale legacy (pendientes o “Error diferido”) del historial/cola.
  Future<void> discardSalePushOps() async {
    final sales = await _isar.syncOperations
        .filter()
        .entityKindEqualTo(SyncEntityKind.sale)
        .isDeletedEqualTo(false)
        .findAll();
    if (sales.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final op in sales) {
        await _isar.syncOperations.put(op.markAsDeleted());
      }
    });
  }

  Future<void> enqueueCatalogPull() async {
    final existing = await _isar.syncOperations
        .filter()
        .entityKindEqualTo(SyncEntityKind.catalogPull)
        .operationStatusEqualTo(SyncOperationStatus.pending)
        .isDeletedEqualTo(false)
        .findFirst();
    if (existing != null) return;

    await _isar.writeTxn(() => _isar.syncOperations.put(SyncOperation.enqueueCatalogPull()));
  }

  /// [ensureCatalogPull]: si la cola está vacía, encola un pull de catálogo
  /// (evita «Sync: 0 ok, 0 error» sin hacer nada).
  Future<SyncRunResult> runSyncCycle({
    bool ensureCatalogPull = true,
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

    final adapter = createEn1Adapter(config.en1SyncMode);
    final pending = await _pendingOperations();
    var succeeded = 0;
    var failed = 0;

    for (final op in pending) {
      if (op.entityKind == SyncEntityKind.sale) continue;

      final processing = op.copyWith(
        operationStatus: SyncOperationStatus.processing,
        attemptCount: op.attemptCount + 1,
        updatedAt: DateTime.now(),
      );
      await _isar.writeTxn(() => _isar.syncOperations.put(processing));

      try {
        await _processOperation(adapter, config, processing, onProgress: onProgress);
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
    }

    return SyncRunResult(processed: pending.length, succeeded: succeeded, failed: failed);
  }

  Future<List<SyncOperation>> _pendingOperations() async {
    final ops = await _isar.syncOperations
        .filter()
        .operationStatusEqualTo(SyncOperationStatus.pending)
        .isDeletedEqualTo(false)
        .findAll();
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<void> _processOperation(
    En1ApiAdapter adapter,
    BusinessConfig config,
    SyncOperation op, {
    En1BootstrapProgressCallback? onProgress,
  }) async {
    switch (op.entityKind) {
      case SyncEntityKind.sale:
        await _pushSale(adapter, config, op);
      case SyncEntityKind.customer:
        await _pushCustomer(adapter, config, op);
      case SyncEntityKind.catalogPull:
        await _pullCatalog(config, onProgress: onProgress);
      case SyncEntityKind.order:
        final orderId = op.entityLocalId;
        if (orderId == null || orderId.isEmpty) {
          throw StateError('Pedido sin localId en SyncOperation');
        }
        await OrderService(
          repository: OrderRepository(_isar),
          syncRepository: this,
        ).syncOrderToEn1(orderId, config: config);
      case SyncEntityKind.cashMovement:
      case SyncEntityKind.cashRegister:
        throw UnimplementedError('${syncEntityKindLabel(op.entityKind)} pendiente L9.1');
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

  Future<void> _pushSale(En1ApiAdapter adapter, BusinessConfig config, SyncOperation op) async {
    final saleId = op.entityLocalId;
    if (saleId == null) throw StateError('Venta sin ID local');

    final sale = await _isar.sales.filter().localIdEqualTo(saleId).findFirst();
    if (sale == null) throw StateError('Venta no encontrada');

    if (sale.isSynced) return;

    final items = await _isar.saleItems.filter().saleIdEqualTo(saleId).findAll();
    final result = await adapter.pushSale(config: config, sale: sale, items: items);

    await _isar.writeTxn(() async {
      await _isar.sales.put(sale.markAsSynced(result.serverId));
      for (final item in items) {
        await _isar.saleItems.put(item.markAsSynced('${result.serverId}-item-${item.localId}'));
      }
    });
  }

  Future<void> _pushCustomer(En1ApiAdapter adapter, BusinessConfig config, SyncOperation op) async {
    final customerId = op.entityLocalId;
    if (customerId == null) throw StateError('Cliente sin ID local');

    final customer = await _isar.customers.filter().localIdEqualTo(customerId).findFirst();
    if (customer == null) throw StateError('Cliente no encontrado');

    if (customer.isSynced && !customer.isPendingSync) return;

    final result = await adapter.pushCustomer(config: config, customer: customer);
    await _isar.writeTxn(() => _isar.customers.put(customer.markAsSynced(result.serverId)));
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
