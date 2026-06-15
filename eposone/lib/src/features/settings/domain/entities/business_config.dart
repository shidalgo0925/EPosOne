import 'package:isar/isar.dart';
import 'package:eposone/src/core/entities/sync_entity.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';

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
  });

  String get nextReceiptNumber => '$receiptPrefix-${receiptNextNumber.toString().padLeft(6, '0')}';

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
}