import 'package:eposone/src/features/fiscal/domain/entities/fiscal_document.dart';
import 'package:eposone/src/features/fiscal/domain/entities/pac_provider_type.dart';
import 'package:eposone/src/features/fiscal/data/adapters/stub_pac_adapter.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';
import 'package:eposone/src/features/sales/domain/entities/sale_item.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

class PacEmissionRequest {
  final BusinessConfig config;
  final Sale sale;
  final List<SaleItem> items;
  final String fiscalNumber;
  final FiscalDocumentType documentType;
  final String? relatedCufe;

  const PacEmissionRequest({
    required this.config,
    required this.sale,
    required this.items,
    required this.fiscalNumber,
    required this.documentType,
    this.relatedCufe,
  });
}

class PacEmissionResult {
  final FiscalDocumentStatus status;
  final String? cufe;
  final String? authorizationNumber;
  final String? errorMessage;

  const PacEmissionResult({
    required this.status,
    this.cufe,
    this.authorizationNumber,
    this.errorMessage,
  });
}

abstract class PacAdapter {
  Future<PacEmissionResult> emit(PacEmissionRequest request);
}

PacAdapter createPacAdapter(PacProviderType type) {
  switch (type) {
    case PacProviderType.stub:
      return StubPacAdapter();
    case PacProviderType.none:
      throw StateError('PAC no configurado');
  }
}
