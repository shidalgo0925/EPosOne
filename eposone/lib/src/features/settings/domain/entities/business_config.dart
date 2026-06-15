import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/fiscal/domain/entities/pac_provider_type.dart';
import 'package:eposone/src/features/sync/domain/entities/en1_sync_mode.dart';

part 'business_config.g.dart';

@collection
class BusinessConfig extends SyncEntity {
  Id get isarId => 1; // Singleton, solo una configuración

  final String businessName;
  final String? logoPath;
  final String? address;
  final String? phone;
  final String? email;
  final String currency; // USD, PAB, etc.
  final String? currencySymbol;
  final double taxRate; // ej: 7.0 para 7%
  final String? taxName;
  final bool taxIncluded;
  final String receiptHeader;
  final String receiptFooter;
  final String? receiptPrefix; // prefijo para número de recibo
  final int receiptNextNumber;
  final bool allowDecimalQty;
  final bool trackInventory;
  final String? ruc;
  final bool isSetupComplete;
  final bool openTicketsEnabled;
  final bool usePredefinedTickets;
  @enumerated
  final OrderType defaultOrderType;
  final bool fiscalInvoicingEnabled;
  @enumerated
  final PacProviderType pacProvider;
  final String? pacApiUrl;
  final String? pacApiToken;
  final String? fiscalBranchCode;
  final String? fiscalPointOfSale;
  final int fiscalNextNumber;
  final bool en1SyncEnabled;
  @enumerated
  final En1SyncMode en1SyncMode;
  final String? en1ApiUrl;
  final String? en1ApiToken;
  final String? en1BranchId;
  final DateTime? en1LastSyncAt;
  final bool loyaltyEnabled;
  final double loyaltyPointsPerUnit;

  const BusinessConfig({
    required super.localId,
    super.serverId,
    super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.businessName,
    this.logoPath,
    this.address,
    this.phone,
    this.email,
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.taxRate = 0,
    this.taxName,
    this.taxIncluded = false,
    this.receiptHeader = 'Gracias por su compra',
    this.receiptFooter = 'Vuelva pronto',
    this.receiptPrefix = 'R',
    this.receiptNextNumber = 1,
    this.allowDecimalQty = false,
    this.trackInventory = true,
    this.ruc,
    this.isSetupComplete = false,
    this.openTicketsEnabled = true,
    this.usePredefinedTickets = false,
    this.defaultOrderType = OrderType.generic,
    this.fiscalInvoicingEnabled = false,
    this.pacProvider = PacProviderType.none,
    this.pacApiUrl,
    this.pacApiToken,
    this.fiscalBranchCode,
    this.fiscalPointOfSale,
    this.fiscalNextNumber = 1,
    this.en1SyncEnabled = false,
    this.en1SyncMode = En1SyncMode.none,
    this.en1ApiUrl,
    this.en1ApiToken,
    this.en1BranchId,
    this.en1LastSyncAt,
    this.loyaltyEnabled = false,
    this.loyaltyPointsPerUnit = 1,
  });

  String get nextReceiptNumber => '$receiptPrefix-${receiptNextNumber.toString().padLeft(6, '0')}';

  String get nextFiscalNumber {
    final branch = (fiscalBranchCode ?? '000').padLeft(3, '0');
    final point = (fiscalPointOfSale ?? '000').padLeft(3, '0');
    final seq = fiscalNextNumber.toString().padLeft(10, '0');
    return '$branch-$point-$seq';
  }

  bool get isFiscalReady =>
      fiscalInvoicingEnabled &&
      pacProvider != PacProviderType.none &&
      ruc != null &&
      ruc!.trim().isNotEmpty &&
      fiscalBranchCode != null &&
      fiscalPointOfSale != null;

  bool get isEn1SyncReady =>
      en1SyncEnabled &&
      en1SyncMode != En1SyncMode.none &&
      en1BranchId != null &&
      en1BranchId!.trim().isNotEmpty &&
      (en1SyncMode == En1SyncMode.stub ||
          (en1ApiUrl != null && en1ApiUrl!.trim().isNotEmpty));

  @override
  BusinessConfig markAsModified() => copyWith(syncStatus: SyncStatus.modified, updatedAt: DateTime.now());

  @override
  BusinessConfig markAsSynced(String serverId) => copyWith(serverId: serverId, syncStatus: SyncStatus.synced, updatedAt: DateTime.now());

  @override
  BusinessConfig markAsDeleted() => this; // No se elimina la configuración

  BusinessConfig copyWith({
    String? localId,
    String? serverId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? businessName,
    String? logoPath,
    String? address,
    String? phone,
    String? email,
    String? currency,
    String? currencySymbol,
    double? taxRate,
    String? taxName,
    bool? taxIncluded,
    String? receiptHeader,
    String? receiptFooter,
    String? receiptPrefix,
    int? receiptNextNumber,
    bool? allowDecimalQty,
    bool? trackInventory,
    String? ruc,
    bool? isSetupComplete,
    bool? openTicketsEnabled,
    bool? usePredefinedTickets,
    OrderType? defaultOrderType,
    bool? fiscalInvoicingEnabled,
    PacProviderType? pacProvider,
    String? pacApiUrl,
    String? pacApiToken,
    String? fiscalBranchCode,
    String? fiscalPointOfSale,
    int? fiscalNextNumber,
    bool? en1SyncEnabled,
    En1SyncMode? en1SyncMode,
    String? en1ApiUrl,
    String? en1ApiToken,
    String? en1BranchId,
    DateTime? en1LastSyncAt,
    bool? loyaltyEnabled,
    double? loyaltyPointsPerUnit,
  }) =>
      BusinessConfig(
        localId: localId ?? this.localId,
        serverId: serverId ?? this.serverId,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        businessName: businessName ?? this.businessName,
        logoPath: logoPath ?? this.logoPath,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        currency: currency ?? this.currency,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        taxRate: taxRate ?? this.taxRate,
        taxName: taxName ?? this.taxName,
        taxIncluded: taxIncluded ?? this.taxIncluded,
        receiptHeader: receiptHeader ?? this.receiptHeader,
        receiptFooter: receiptFooter ?? this.receiptFooter,
        receiptPrefix: receiptPrefix ?? this.receiptPrefix,
        receiptNextNumber: receiptNextNumber ?? this.receiptNextNumber,
        allowDecimalQty: allowDecimalQty ?? this.allowDecimalQty,
        trackInventory: trackInventory ?? this.trackInventory,
        ruc: ruc ?? this.ruc,
        isSetupComplete: isSetupComplete ?? this.isSetupComplete,
        openTicketsEnabled: openTicketsEnabled ?? this.openTicketsEnabled,
        usePredefinedTickets: usePredefinedTickets ?? this.usePredefinedTickets,
        defaultOrderType: defaultOrderType ?? this.defaultOrderType,
        fiscalInvoicingEnabled: fiscalInvoicingEnabled ?? this.fiscalInvoicingEnabled,
        pacProvider: pacProvider ?? this.pacProvider,
        pacApiUrl: pacApiUrl ?? this.pacApiUrl,
        pacApiToken: pacApiToken ?? this.pacApiToken,
        fiscalBranchCode: fiscalBranchCode ?? this.fiscalBranchCode,
        fiscalPointOfSale: fiscalPointOfSale ?? this.fiscalPointOfSale,
        fiscalNextNumber: fiscalNextNumber ?? this.fiscalNextNumber,
        en1SyncEnabled: en1SyncEnabled ?? this.en1SyncEnabled,
        en1SyncMode: en1SyncMode ?? this.en1SyncMode,
        en1ApiUrl: en1ApiUrl ?? this.en1ApiUrl,
        en1ApiToken: en1ApiToken ?? this.en1ApiToken,
        en1BranchId: en1BranchId ?? this.en1BranchId,
        en1LastSyncAt: en1LastSyncAt ?? this.en1LastSyncAt,
        loyaltyEnabled: loyaltyEnabled ?? this.loyaltyEnabled,
        loyaltyPointsPerUnit: loyaltyPointsPerUnit ?? this.loyaltyPointsPerUnit,
      );

  factory BusinessConfig.defaultConfig() => BusinessConfig(
        localId: 'business_config_default',
        businessName: 'Mi Negocio',
        currency: 'USD',
        currencySymbol: '\$',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  BusinessConfig incrementReceiptNumber() => copyWith(receiptNextNumber: receiptNextNumber + 1);

  BusinessConfig incrementFiscalNumber() => copyWith(fiscalNextNumber: fiscalNextNumber + 1);
}