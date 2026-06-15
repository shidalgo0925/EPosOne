import 'dart:convert';

import 'package:eposone/src/features/products/domain/entities/selected_modifier.dart';

abstract final class ModifierCodec {
  static String encode(List<SelectedModifier> modifiers) {
    if (modifiers.isEmpty) return '';
    return jsonEncode(modifiers.map((m) => m.toJson()).toList());
  }

  static List<SelectedModifier> decode(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => SelectedModifier.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  static String modifiersLabel(List<SelectedModifier> modifiers) {
    if (modifiers.isEmpty) return '';
    return modifiers.map((m) => m.name).join(', ');
  }
}
