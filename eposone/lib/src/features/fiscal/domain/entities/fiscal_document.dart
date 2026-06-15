import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';

part 'fiscal_document.g.dart';

enum FiscalDocumentType {
  invoice,
  creditNote,
}

enum FiscalDocumentStatus {
  pending,
  submitted,
  accepted,
  rejected,
  error,
}

String fiscalDocumentTypeLabel(FiscalDocumentType type) => switch (type) {
      FiscalDocumentType.invoice => 'Factura electrónica',
      FiscalDocumentType.creditNote => 'Nota de crédito',
    };

String fiscalDocumentStatusLabel(FiscalDocumentStatus status) => switch (status) {
      FiscalDocumentStatus.pending => 'Pendiente',
      FiscalDocumentStatus.submitted => 'Enviado',
      FiscalDocumentStatus.accepted => 'Aceptado DGI',
      FiscalDocumentStatus.rejected => 'Rechazado',
      FiscalDocumentStatus.error => 'Error',
    };

@collection
class FiscalDocument extends SyncEntity {
  Id get isarId => localId.hashCode;

  final String saleId;
  final String? relatedDocumentId;
  @enumerated
  final FiscalDocumentType documentType;
  final String fiscalNumber;
  final String? cufe;
  final String? authorizationNumber;
  @enumerated
  final FiscalDocumentStatus status;
  final String? errorMessage;
  final DateTime issuedAt;
  final String? customerName;
  final String? customerDocument;
  final double subtotal;
  final double taxAmount;
  final double total;

  const FiscalDocument({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.saleId,
    this.relatedDocumentId,
    required this.documentType,
    required this.fiscalNumber,
    this.cufe,
    this.authorizationNumber,
    this.status = FiscalDocumentStatus.pending,
    this.errorMessage,
    required this.issuedAt,
    this.customerName,
    this.customerDocument,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
  });

  @override
  FiscalDocument markAsModified() =>
      copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  FiscalDocument markAsSynced(String serverId) =>
      copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  FiscalDocument markAsDeleted() =>
      copyWith(deletedAt: DateTime.now(), syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  FiscalDocument copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? saleId,
    String? relatedDocumentId,
    FiscalDocumentType? documentType,
    String? fiscalNumber,
    String? cufe,
    String? authorizationNumber,
    FiscalDocumentStatus? status,
    String? errorMessage,
    DateTime? issuedAt,
    String? customerName,
    String? customerDocument,
    double? subtotal,
    double? taxAmount,
    double? total,
  }) =>
      FiscalDocument(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        saleId: saleId ?? this.saleId,
        relatedDocumentId: relatedDocumentId ?? this.relatedDocumentId,
        documentType: documentType ?? this.documentType,
        fiscalNumber: fiscalNumber ?? this.fiscalNumber,
        cufe: cufe ?? this.cufe,
        authorizationNumber: authorizationNumber ?? this.authorizationNumber,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        issuedAt: issuedAt ?? this.issuedAt,
        customerName: customerName ?? this.customerName,
        customerDocument: customerDocument ?? this.customerDocument,
        subtotal: subtotal ?? this.subtotal,
        taxAmount: taxAmount ?? this.taxAmount,
        total: total ?? this.total,
      );

  factory FiscalDocument.create({
    required String saleId,
    String? relatedDocumentId,
    required FiscalDocumentType documentType,
    required String fiscalNumber,
    String? customerName,
    String? customerDocument,
    required double subtotal,
    required double taxAmount,
    required double total,
  }) {
    final now = DateTime.now();
    return FiscalDocument(
      localId: now.microsecondsSinceEpoch.toString(),
      saleId: saleId,
      relatedDocumentId: relatedDocumentId,
      documentType: documentType,
      fiscalNumber: fiscalNumber,
      customerName: customerName,
      customerDocument: customerDocument,
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
      issuedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }
}
