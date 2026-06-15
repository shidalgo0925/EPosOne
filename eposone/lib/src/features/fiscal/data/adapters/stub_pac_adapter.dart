import 'dart:math';

import 'package:eposone/src/features/fiscal/data/adapters/pac_adapter.dart';
import 'package:eposone/src/features/fiscal/domain/entities/fiscal_document.dart';

/// Simula emisión FE para desarrollo sin certificado DGI ni API real.
class StubPacAdapter implements PacAdapter {
  static final _random = Random();

  @override
  Future<PacEmissionResult> emit(PacEmissionRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (request.config.ruc == null || request.config.ruc!.trim().isEmpty) {
      return const PacEmissionResult(
        status: FiscalDocumentStatus.error,
        errorMessage: 'Configure el RUC del negocio antes de emitir FE',
      );
    }

    if (request.config.fiscalBranchCode == null ||
        request.config.fiscalPointOfSale == null ||
        request.config.fiscalBranchCode!.trim().isEmpty ||
        request.config.fiscalPointOfSale!.trim().isEmpty) {
      return const PacEmissionResult(
        status: FiscalDocumentStatus.error,
        errorMessage: 'Configure sucursal y punto de emisión DGI',
      );
    }

    final cufe = List.generate(64, (_) => _random.nextInt(16).toRadixString(16)).join().toUpperCase();

    return PacEmissionResult(
      status: FiscalDocumentStatus.accepted,
      cufe: cufe,
      authorizationNumber: 'STUB-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
