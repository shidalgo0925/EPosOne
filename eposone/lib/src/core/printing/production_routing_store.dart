import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Routing: categoría (default) y producto (override) → destino de producción.
class ProductionRoutingStore {
  static const _catKey = 'production_route_category_v1';
  static const _prodKey = 'production_route_product_v1';

  static Future<Map<String, String>> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(String key, Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<Map<String, String>> categoryRoutes() => _load(_catKey);
  static Future<Map<String, String>> productRoutes() => _load(_prodKey);

  static Future<void> setCategoryDestination(
      String categoryId, String? destinationId) async {
    final map = await categoryRoutes();
    if (destinationId == null || destinationId.isEmpty) {
      map.remove(categoryId);
    } else {
      map[categoryId] = destinationId;
    }
    await _save(_catKey, map);
  }

  static Future<void> setProductDestination(
      String productId, String? destinationId) async {
    final map = await productRoutes();
    if (destinationId == null || destinationId.isEmpty) {
      map.remove(productId);
    } else {
      map[productId] = destinationId;
    }
    await _save(_prodKey, map);
  }

  /// Producto override → categoría → null (sin producción).
  static Future<String?> resolveDestinationId({
    required String productId,
    String? categoryId,
  }) async {
    final products = await productRoutes();
    final fromProduct = products[productId];
    if (fromProduct != null && fromProduct.isNotEmpty) return fromProduct;
    if (categoryId == null || categoryId.isEmpty) return null;
    final cats = await categoryRoutes();
    final fromCat = cats[categoryId];
    if (fromCat != null && fromCat.isNotEmpty) return fromCat;
    return null;
  }
}
