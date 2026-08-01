import 'dart:convert';

/// Contexto de auditoría embebido en `payload` del OrderEvent (offline-first).
///
/// Evita migración Isar; el contrato HTTP ya admite `payload` libre.
class OrderEventAudit {
  const OrderEventAudit({
    this.reason,
    this.origin = OrderEventOriginCode.eposone,
    this.organizationId,
    this.registerId,
    this.deviceId,
    this.shiftId,
    this.createdBy,
    this.extra = const {},
  });

  final String? reason;
  final String origin;
  final String? organizationId;
  final String? registerId;
  final String? deviceId;
  final String? shiftId;
  final String? createdBy;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toPayloadMap() => {
        ...extra,
        if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
        'origin': origin,
        if (organizationId != null) 'organization_id': organizationId,
        if (registerId != null) 'register_id': registerId,
        if (deviceId != null) 'device_id': deviceId,
        if (shiftId != null) 'shift_id': shiftId,
        if (createdBy != null) 'created_by': createdBy,
      };

  String toPayloadJson() => jsonEncode(toPayloadMap());

  static String? reasonFromPayload(String? payloadJson) {
    if (payloadJson == null || payloadJson.isEmpty) return null;
    try {
      final m = jsonDecode(payloadJson);
      if (m is Map && m['reason'] != null) {
        final r = m['reason'].toString().trim();
        return r.isEmpty ? null : r;
      }
    } catch (_) {}
    return null;
  }

  static String? createdByFromPayload(String? payloadJson) {
    if (payloadJson == null || payloadJson.isEmpty) return null;
    try {
      final m = jsonDecode(payloadJson);
      if (m is Map && m['created_by'] != null) {
        final r = m['created_by'].toString().trim();
        return r.isEmpty ? null : r;
      }
    } catch (_) {}
    return null;
  }
}

abstract final class OrderEventOriginCode {
  static const eposone = 'EPOSONE';
  static const en1 = 'EN1';
  static const system = 'SYSTEM';
}
