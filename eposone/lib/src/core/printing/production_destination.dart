import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Canal de un destino de producción.
enum ProductionChannel {
  bluetooth,
  network,
  /// Reservado para KDS — se aprovisiona, no imprime en Prog2.
  screen,
}

/// Área lógica (etiqueta); varios "Bar" = varios destinos con area bar.
enum ProductionArea {
  kitchen,
  bar,
  other,
}

/// Destino de producción: Cocina / Bar / … → impresora o pantalla.
class ProductionDestination {
  final String id;
  final String name;
  final ProductionArea area;
  final ProductionChannel channel;
  final String? btMac;
  final String? btName;
  final String? host;
  final int port;
  final bool active;

  const ProductionDestination({
    required this.id,
    required this.name,
    required this.area,
    required this.channel,
    this.btMac,
    this.btName,
    this.host,
    this.port = 9100,
    this.active = true,
  });

  bool get canPrintNow =>
      active &&
      ((channel == ProductionChannel.bluetooth &&
              btMac != null &&
              btMac!.isNotEmpty) ||
          (channel == ProductionChannel.network &&
              host != null &&
              host!.trim().isNotEmpty));

  bool get isScreen => channel == ProductionChannel.screen;

  String get areaLabel {
    switch (area) {
      case ProductionArea.kitchen:
        return 'Cocina';
      case ProductionArea.bar:
        return 'Bar';
      case ProductionArea.other:
        return 'Otro';
    }
  }

  String get channelLabel {
    switch (channel) {
      case ProductionChannel.bluetooth:
        return 'Bluetooth';
      case ProductionChannel.network:
        return 'Red';
      case ProductionChannel.screen:
        return 'Pantalla';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'area': area.name,
        'channel': channel.name,
        'btMac': btMac,
        'btName': btName,
        'host': host,
        'port': port,
        'active': active,
      };

  factory ProductionDestination.fromJson(Map<String, dynamic> json) {
    return ProductionDestination(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Destino',
      area: ProductionArea.values.firstWhere(
        (e) => e.name == json['area'],
        orElse: () => ProductionArea.other,
      ),
      channel: ProductionChannel.values.firstWhere(
        (e) => e.name == json['channel'],
        orElse: () => ProductionChannel.network,
      ),
      btMac: json['btMac'] as String?,
      btName: json['btName'] as String?,
      host: json['host'] as String?,
      port: (json['port'] as num?)?.toInt() ?? 9100,
      active: json['active'] as bool? ?? true,
    );
  }

  ProductionDestination copyWith({
    String? name,
    ProductionArea? area,
    ProductionChannel? channel,
    String? btMac,
    String? btName,
    String? host,
    int? port,
    bool? active,
    bool clearBt = false,
    bool clearHost = false,
  }) =>
      ProductionDestination(
        id: id,
        name: name ?? this.name,
        area: area ?? this.area,
        channel: channel ?? this.channel,
        btMac: clearBt ? null : (btMac ?? this.btMac),
        btName: clearBt ? null : (btName ?? this.btName),
        host: clearHost ? null : (host ?? this.host),
        port: port ?? this.port,
        active: active ?? this.active,
      );

  static ProductionDestination create({
    required String name,
    required ProductionArea area,
    required ProductionChannel channel,
  }) =>
      ProductionDestination(
        id: const Uuid().v4(),
        name: name,
        area: area,
        channel: channel,
      );
}

/// Persistencia local de destinos de producción (no caja).
class ProductionDestinationStore {
  static const _key = 'production_destinations_v1';

  static Future<List<ProductionDestination>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              ProductionDestination.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<ProductionDestination> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<ProductionDestination?> getById(String id) async {
    final all = await list();
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  static Future<void> upsert(ProductionDestination dest) async {
    final all = await list();
    final i = all.indexWhere((e) => e.id == dest.id);
    if (i >= 0) {
      all[i] = dest;
    } else {
      all.add(dest);
    }
    await saveAll(all);
  }

  static Future<void> delete(String id) async {
    final all = await list();
    all.removeWhere((e) => e.id == id);
    await saveAll(all);
  }
}
