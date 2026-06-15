import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/fiscal/data/repositories/fiscal_repository.dart';
import 'package:eposone/src/features/fiscal/domain/entities/fiscal_document.dart';

final fiscalDocumentsProvider = FutureProvider<List<FiscalDocument>>((ref) async {
  return ref.watch(fiscalRepositoryProvider).getRecent();
});

final fiscalDocumentForSaleProvider = FutureProvider.family<FiscalDocument?, String>((ref, saleId) async {
  return ref.watch(fiscalRepositoryProvider).getBySaleId(saleId, type: FiscalDocumentType.invoice);
});

final fiscalCreditNoteForSaleProvider = FutureProvider.family<FiscalDocument?, String>((ref, saleId) async {
  return ref.watch(fiscalRepositoryProvider).getBySaleId(saleId, type: FiscalDocumentType.creditNote);
});
