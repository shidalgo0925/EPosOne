/// DTOs Device Bootstrap Hito 2 — `GET /api/v1/devices/bootstrap`.
class En1RemoteProduct {
  final String productRef;
  final String name;
  final String? description;
  final String? productType;
  final String? status;
  final double unitPrice;
  final String? currency;
  final double? costPrice;
  final String? barcode;
  final String? category;
  final String? imageUrl;
  final bool tracksInventory;
  final double? minStock;
  final double? maxStock;
  final String? uom;
  final String? purchaseUom;
  final double? packFactor;
  /// Stock embebido en el ítem (si bootstrap lo incluye por producto).
  final double? stockAvailable;

  const En1RemoteProduct({
    required this.productRef,
    required this.name,
    this.description,
    this.productType,
    this.status,
    required this.unitPrice,
    this.currency,
    this.costPrice,
    this.barcode,
    this.category,
    this.imageUrl,
    this.tracksInventory = false,
    this.minStock,
    this.maxStock,
    this.uom,
    this.purchaseUom,
    this.packFactor,
    this.stockAvailable,
  });

  bool get isActive {
    final s = (status ?? 'active').toLowerCase();
    return s == 'active' || s == 'enabled' || s == 'ok' || s == '1' || s == 'true';
  }

  factory En1RemoteProduct.fromJson(Map<String, dynamic> json) {
    double? n(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    String? s(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    final ref = s(json['product_ref'] ?? json['sku'] ?? json['ref']) ?? '';
    final name = s(json['name']) ?? ref;
    final price = n(json['unit_price'] ?? json['price']) ?? 0;

    String? category;
    final catRaw = json['category'];
    if (catRaw is String) {
      category = s(catRaw);
    } else if (catRaw is Map) {
      category = s(catRaw['name'] ?? catRaw['ref'] ?? catRaw['category_name']);
    } else {
      category = s(json['category_name']);
    }

    return En1RemoteProduct(
      productRef: ref,
      name: name,
      description: s(json['description']),
      productType: s(json['product_type']),
      status: s(json['status']),
      unitPrice: price,
      currency: s(json['currency']),
      costPrice: n(json['cost_price'] ?? json['cost']),
      barcode: s(json['barcode']),
      category: category,
      imageUrl: s(json['image_url'] ?? json['imageUrl']),
      tracksInventory: json['tracks_inventory'] == true ||
          json['tracks_inventory'] == 1 ||
          '${json['tracks_inventory']}'.toLowerCase() == 'true',
      minStock: n(json['min_stock']),
      maxStock: n(json['max_stock']),
      uom: s(json['uom']),
      purchaseUom: s(json['purchase_uom']),
      packFactor: n(json['pack_factor']),
      stockAvailable: n(json['available'] ?? json['on_hand'] ?? json['stock']),
    );
  }
}

class En1RemoteStockBalance {
  final String productRef;
  final double onHand;
  final double reserved;
  final double available;
  final String? warehouseRef;

  const En1RemoteStockBalance({
    required this.productRef,
    this.onHand = 0,
    this.reserved = 0,
    required this.available,
    this.warehouseRef,
  });

  factory En1RemoteStockBalance.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    String? s(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    final ref = s(json['product_ref'] ?? json['sku'] ?? json['ref']) ?? '';
    final available = n(json['available'] ?? json['on_hand']);
    return En1RemoteStockBalance(
      productRef: ref,
      onHand: n(json['on_hand']),
      reserved: n(json['reserved']),
      available: available,
      warehouseRef: s(json['warehouse_ref'] ?? json['warehouse'] ?? json['bodega']),
    );
  }
}

/// Payload único de `GET /api/v1/devices/bootstrap`.
class En1BootstrapPayload {
  final Map<String, dynamic>? config;
  final List<En1RemoteProduct> products;
  final List<En1RemoteStockBalance> stockBalances;
  final Map<String, dynamic> raw;

  const En1BootstrapPayload({
    this.config,
    required this.products,
    required this.stockBalances,
    this.raw = const {},
  });
}

class En1BootstrapResult {
  final int productsUpserted;
  final int categoriesUpserted;
  final int imagesDownloaded;
  final int stockUpdated;
  final int imageFailures;
  final DateTime completedAt;
  final String message;

  const En1BootstrapResult({
    required this.productsUpserted,
    required this.categoriesUpserted,
    required this.imagesDownloaded,
    required this.stockUpdated,
    this.imageFailures = 0,
    required this.completedAt,
    required this.message,
  });
}
