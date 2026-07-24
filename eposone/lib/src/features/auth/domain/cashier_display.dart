import 'package:eposone/src/features/platform/data/en1_cashier_catalog_store.dart';

/// Display de cajero en tablet (Hito 2.5 §7).
///
/// Ownership Integrado: el **nombre** lo define EN1.
/// Prog2: nunca mostrar UUID / refs técnicas si falta o llega basura.
class CashierDisplay {
  CashierDisplay._();

  static final _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// True si el string no sirve como nombre humano.
  static bool looksLikeIdNotName(String? value) {
    if (value == null) return true;
    final t = value.trim();
    if (t.isEmpty) return true;
    if (_uuidRe.hasMatch(t)) return true;
    if (t.startsWith('en1_cashier_')) return true;
    if (RegExp(r'^\d+$').hasMatch(t)) return true;
    return false;
  }

  /// Nombre seguro para UI / recib / cabecera (síncrono).
  static String displayName({
    String? name,
    int? contactId,
    String? code,
  }) {
    if (!looksLikeIdNotName(name)) return name!.trim();
    final c = code?.trim();
    if (c != null && c.isNotEmpty && !looksLikeIdNotName(c)) return c;
    if (contactId != null && contactId > 0) return 'Cajero #$contactId';
    return 'Cajero';
  }

  /// Resuelve desde catálogo EN1 local si el nombre llegó vacío/UUID.
  static Future<String> resolve({
    String? name,
    int? contactId,
    String? code,
  }) async {
    if (!looksLikeIdNotName(name)) return name!.trim();
    if (contactId != null && contactId > 0) {
      final all = await En1CashierCatalogStore.listMetaOnly();
      for (final c in all) {
        if (c.cashierContactId == contactId) {
          return displayName(
            name: c.cashierName,
            contactId: contactId,
            code: c.cashierCode ?? code,
          );
        }
      }
    }
    return displayName(name: name, contactId: contactId, code: code);
  }
}
