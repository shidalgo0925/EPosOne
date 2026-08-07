import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Borrador del asistente Standalone (ADR-033 §5.4).
class StandaloneAssistantDraft {
  const StandaloneAssistantDraft({
    this.step = 0,
    this.businessName = '',
    this.ruc = '',
    this.address = '',
    this.currency = 'PAB',
    this.currencySymbol = 'B/.',
    this.taxName = 'ITBMS',
    this.taxRate = 7,
    this.categoryName = 'General',
    this.productName = '',
    this.productPrice = 0,
    this.cashLabel = 'Caja 1',
    this.cashierName = 'Administrador',
    this.openingAmount = 0,
    this.skipPrinter = true,
  });

  final int step;
  final String businessName;
  final String ruc;
  final String address;
  final String currency;
  final String currencySymbol;
  final String taxName;
  final double taxRate;
  final String categoryName;
  final String productName;
  final double productPrice;
  final String cashLabel;
  final String cashierName;
  final double openingAmount;
  final bool skipPrinter;

  StandaloneAssistantDraft copyWith({
    int? step,
    String? businessName,
    String? ruc,
    String? address,
    String? currency,
    String? currencySymbol,
    String? taxName,
    double? taxRate,
    String? categoryName,
    String? productName,
    double? productPrice,
    String? cashLabel,
    String? cashierName,
    double? openingAmount,
    bool? skipPrinter,
  }) =>
      StandaloneAssistantDraft(
        step: step ?? this.step,
        businessName: businessName ?? this.businessName,
        ruc: ruc ?? this.ruc,
        address: address ?? this.address,
        currency: currency ?? this.currency,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        taxName: taxName ?? this.taxName,
        taxRate: taxRate ?? this.taxRate,
        categoryName: categoryName ?? this.categoryName,
        productName: productName ?? this.productName,
        productPrice: productPrice ?? this.productPrice,
        cashLabel: cashLabel ?? this.cashLabel,
        cashierName: cashierName ?? this.cashierName,
        openingAmount: openingAmount ?? this.openingAmount,
        skipPrinter: skipPrinter ?? this.skipPrinter,
      );

  Map<String, dynamic> toJson() => {
        'step': step,
        'businessName': businessName,
        'ruc': ruc,
        'address': address,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'taxName': taxName,
        'taxRate': taxRate,
        'categoryName': categoryName,
        'productName': productName,
        'productPrice': productPrice,
        'cashLabel': cashLabel,
        'cashierName': cashierName,
        'openingAmount': openingAmount,
        'skipPrinter': skipPrinter,
      };

  factory StandaloneAssistantDraft.fromJson(Map<String, dynamic> json) =>
      StandaloneAssistantDraft(
        step: (json['step'] as num?)?.toInt() ?? 0,
        businessName: json['businessName']?.toString() ?? '',
        ruc: json['ruc']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        currency: json['currency']?.toString() ?? 'PAB',
        currencySymbol: json['currencySymbol']?.toString() ?? 'B/.',
        taxName: json['taxName']?.toString() ?? 'ITBMS',
        taxRate: (json['taxRate'] as num?)?.toDouble() ?? 7,
        categoryName: json['categoryName']?.toString() ?? 'General',
        productName: json['productName']?.toString() ?? '',
        productPrice: (json['productPrice'] as num?)?.toDouble() ?? 0,
        cashLabel: json['cashLabel']?.toString() ?? 'Caja 1',
        cashierName: json['cashierName']?.toString() ?? 'Administrador',
        openingAmount: (json['openingAmount'] as num?)?.toDouble() ?? 0,
        skipPrinter: json['skipPrinter'] != false,
      );
}

class StandaloneAssistantDraftStore {
  static const _key = 'standalone_assistant_draft_v1';
  static const _readyKey = 'standalone_ready_to_sell_v1';

  static Future<void> save(StandaloneAssistantDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  static Future<StandaloneAssistantDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      return StandaloneAssistantDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> markReadyToSell() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readyKey, true);
    await clear();
  }

  static Future<bool> isReadyToSell() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_readyKey) == true;
  }

  static Future<void> clearReadyFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readyKey);
  }
}
