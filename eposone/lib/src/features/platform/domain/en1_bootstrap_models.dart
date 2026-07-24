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
    final s = (status ?? '').toLowerCase().trim();
    if (s.isEmpty) return true;
    // EN1 BO (ES/EN) — solo marcar inactivo si es explícito.
    const inactive = {
      'inactive',
      'inactivo',
      'disabled',
      'deshabilitado',
      'deleted',
      'eliminado',
      'archived',
      'archivado',
      'off',
      '0',
      'false',
      'no',
      'draft',
      'borrador',
    };
    if (inactive.contains(s)) return false;
    // Cualquier otro status (Activo, published, etc.) → vendible en POS.
    return true;
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
      warehouseRef:
          s(json['warehouse_ref'] ?? json['warehouse'] ?? json['bodega']),
    );
  }
}

/// Cajero remoto Hito 2.5 — bloque `cashiers` del bootstrap.
class En1RemoteCashier {
  final int cashierContactId;
  final String cashierName;
  final String? cashierCode;
  final bool isActive;
  final String? pinVerifier;
  final int pinVersion;
  final DateTime updatedAt;

  const En1RemoteCashier({
    required this.cashierContactId,
    required this.cashierName,
    this.cashierCode,
    required this.isActive,
    this.pinVerifier,
    required this.pinVersion,
    required this.updatedAt,
  });

  factory En1RemoteCashier.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    String? s(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    final contact = json['contact'];
    final contactMap = contact is Map
        ? Map<String, dynamic>.from(contact)
        : const <String, dynamic>{};
    final id = asInt(
          json['cashier_contact_id'] ??
              json['contact_id'] ??
              contactMap['id'] ??
              json['id'],
        ) ??
        0;
    final name = s(
          json['cashier_name'] ??
              json['name'] ??
              json['display_name'] ??
              json['full_name'] ??
              contactMap['name'] ??
              contactMap['display_name'],
        );
    // Prog2: no persistir UUID/vacío como nombre; fallback estable.
    final safeName = (name == null ||
            name.isEmpty ||
            RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(name) ||
            name.startsWith('en1_cashier_'))
        ? 'Cajero $id'
        : name;
    final updated = DateTime.tryParse(s(json['updated_at']) ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final activeRaw = json['is_active'];
    final isActive = activeRaw != false &&
        activeRaw != 0 &&
        '$activeRaw'.toLowerCase() != 'false';

    return En1RemoteCashier(
      cashierContactId: id,
      cashierName: safeName,
      cashierCode: s(json['cashier_code'] ?? json['code']),
      isActive: isActive,
      pinVerifier: s(json['pin_verifier']),
      pinVersion: asInt(json['pin_version']) ?? 0,
      updatedAt: updated,
    );
  }
}

/// Payload único de `GET /api/v1/devices/bootstrap`.
class En1BootstrapPayload {
  final Map<String, dynamic>? config;
  final List<En1RemoteProduct> products;
  final List<En1RemoteStockBalance> stockBalances;
  final int? cashiersVersion;
  final List<En1RemoteCashier> cashiers;
  /// Bloque opcional `license` (License Engine V1.0). Null si EN1 aún no lo envía.
  final Map<String, dynamic>? license;
  final Map<String, dynamic> raw;

  const En1BootstrapPayload({
    this.config,
    required this.products,
    required this.stockBalances,
    this.cashiersVersion,
    this.cashiers = const [],
    this.license,
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

/// Progreso observable durante Device Bootstrap (UI / sync).
class En1BootstrapProgress {
  final String phase;
  final String label;
  final int current;
  final int total;

  const En1BootstrapProgress({
    required this.phase,
    required this.label,
    this.current = 0,
    this.total = 0,
  });

  double? get fraction {
    if (total <= 0) return null;
    return (current / total).clamp(0.0, 1.0);
  }
}

typedef En1BootstrapProgressCallback = void Function(
    En1BootstrapProgress progress);
