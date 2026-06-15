import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/fiscal/data/adapters/pac_adapter.dart';
import 'package:eposone/src/features/fiscal/domain/entities/fiscal_document.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

part 'fiscal_repository.g.dart';

@riverpod
FiscalRepository fiscalRepository(FiscalRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return FiscalRepository(db);
}

class FiscalRepository {
  final Isar _isar;
  FiscalRepository(this._isar);

  Future<List<FiscalDocument>> getRecent({int limit = 100}) async {
    final docs = await _isar.fiscalDocuments.filter().isDeletedEqualTo(false).findAll();
    docs.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return docs.take(limit).toList();
  }

  Future<FiscalDocument?> getBySaleId(String saleId, {FiscalDocumentType? type}) async {
    var query = _isar.fiscalDocuments.filter().saleIdEqualTo(saleId).isDeletedEqualTo(false);
    if (type != null) {
      query = query.documentTypeEqualTo(type);
    }
    final docs = await query.findAll();
    docs.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return docs.isEmpty ? null : docs.first;
  }

  Future<FiscalDocument?> getById(String localId) async {
    return _isar.fiscalDocuments.filter().localIdEqualTo(localId).findFirst();
  }

  Future<FiscalDocument?> emitInvoiceForSale({
    required Sale sale,
    required List<SaleItem> items,
    required BusinessConfig config,
  }) async {
    if (!config.isFiscalReady) return null;

    final existing = await getBySaleId(sale.localId, type: FiscalDocumentType.invoice);
    if (existing != null && existing.status == FiscalDocumentStatus.accepted) {
      return existing;
    }

    return _emit(
      config: config,
      sale: sale,
      items: items,
      documentType: FiscalDocumentType.invoice,
      existing: existing,
    );
  }

  Future<FiscalDocument?> emitCreditNoteForRefund({
    required String saleId,
    required BusinessConfig config,
  }) async {
    if (!config.isFiscalReady) return null;

    final sale = await _isar.sales.filter().localIdEqualTo(saleId).findFirst();
    if (sale == null) {
      throw StateError('Venta no encontrada');
    }

    final existingCredit = await getBySaleId(saleId, type: FiscalDocumentType.creditNote);
    if (existingCredit != null && existingCredit.status == FiscalDocumentStatus.accepted) {
      return existingCredit;
    }

    final invoice = await getBySaleId(saleId, type: FiscalDocumentType.invoice);
    final items = await _isar.saleItems.filter().saleIdEqualTo(saleId).findAll();

    return _emit(
      config: config,
      sale: sale,
      items: items,
      documentType: FiscalDocumentType.creditNote,
      existing: existingCredit,
      relatedDocumentId: invoice?.localId,
      relatedCufe: invoice?.cufe,
    );
  }

  Future<FiscalDocument?> retryEmission(String fiscalDocumentId) async {
    final doc = await getById(fiscalDocumentId);
    if (doc == null) {
      throw StateError('Comprobante no encontrado');
    }
    if (doc.status == FiscalDocumentStatus.accepted) {
      return doc;
    }

    final configRepo = BusinessConfigRepository(_isar);
    final config = await configRepo.getConfig();
    if (!config.isFiscalReady) {
      throw StateError('Facturación electrónica no configurada');
    }

    final sale = await _isar.sales.filter().localIdEqualTo(doc.saleId).findFirst();
    if (sale == null) {
      throw StateError('Venta no encontrada');
    }

    final items = await _isar.saleItems.filter().saleIdEqualTo(doc.saleId).findAll();
    String? relatedCufe;
    if (doc.documentType == FiscalDocumentType.creditNote && doc.relatedDocumentId != null) {
      final related = await getById(doc.relatedDocumentId!);
      relatedCufe = related?.cufe;
    }

    return _emit(
      config: config,
      sale: sale,
      items: items,
      documentType: doc.documentType,
      existing: doc,
      relatedDocumentId: doc.relatedDocumentId,
      relatedCufe: relatedCufe,
      reuseFiscalNumber: doc.fiscalNumber,
    );
  }

  Future<FiscalDocument?> _emit({
    required BusinessConfig config,
    required Sale sale,
    required List<SaleItem> items,
    required FiscalDocumentType documentType,
    FiscalDocument? existing,
    String? relatedDocumentId,
    String? relatedCufe,
    String? reuseFiscalNumber,
  }) async {
    final configRepo = BusinessConfigRepository(_isar);
    final freshConfig = await configRepo.getConfig();

    final fiscalNumber = reuseFiscalNumber ?? freshConfig.nextFiscalNumber;
    final customer = sale.customerId != null
        ? await _isar.customers.filter().localIdEqualTo(sale.customerId!).findFirst()
        : null;

    var doc = existing ??
        FiscalDocument.create(
          saleId: sale.localId,
          relatedDocumentId: relatedDocumentId,
          documentType: documentType,
          fiscalNumber: fiscalNumber,
          customerName: customer?.name,
          customerDocument: customer?.document,
          subtotal: sale.subtotal,
          taxAmount: sale.taxAmount,
          total: sale.total,
        );

    doc = doc.copyWith(
      status: FiscalDocumentStatus.pending,
      errorMessage: null,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.fiscalDocuments.put(doc);
      if (reuseFiscalNumber == null) {
        await _isar.businessConfigs.put(freshConfig.incrementFiscalNumber().markAsModified());
      }
    });

    try {
      final adapter = createPacAdapter(freshConfig.pacProvider);
      final result = await adapter.emit(
        PacEmissionRequest(
          config: freshConfig,
          sale: sale,
          items: items,
          fiscalNumber: fiscalNumber,
          documentType: documentType,
          relatedCufe: relatedCufe,
        ),
      );

      doc = doc.copyWith(
        status: result.status,
        cufe: result.cufe,
        authorizationNumber: result.authorizationNumber,
        errorMessage: result.errorMessage,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      doc = doc.copyWith(
        status: FiscalDocumentStatus.error,
        errorMessage: e.toString(),
        updatedAt: DateTime.now(),
      );
    }

    await _isar.writeTxn(() => _isar.fiscalDocuments.put(doc));
    return doc;
  }
}
