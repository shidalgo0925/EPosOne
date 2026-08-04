/// Ciclo de vida operativo del Pedido (Local) alineado a EN1 Event Driven.
///
/// Tipos HTTP de evento siguen el contrato congelado
/// (`pedido.anulado`, `pedido.devuelto`, …) — no se inventan alias EN.
///
/// Regla P0 (Ana / Local, ago 2026):
/// - Pre-cocina → **Cancelar** (`cancelled` + `pedido.anulado`)
/// - Post-cocina → **Anular** (`voided` + mismo `pedido.anulado`)
/// - Cobrado → **Reembolsar** (`refunded` + `pedido.devuelto`)
/// - Nunca DELETE físico de Order confirmado.
abstract final class OrderLifecycle {
  static const draft = 'draft';
  static const open = 'open';
  static const confirmed = 'confirmed';
  static const sent = 'sent';
  static const preparing = 'preparing';
  static const ready = 'ready';
  static const delivered = 'delivered';
  static const paid = 'paid';
  static const completed = 'completed';
  static const closed = 'closed';
  static const cancelled = 'cancelled';
  static const voided = 'voided';
  static const refunded = 'refunded';
  static const returned = 'returned';

  static String normalize(String? raw) =>
      (raw ?? open).trim().toLowerCase();

  /// Pedido aún descartable físicamente (solo borrador local).
  static bool canDiscardPhysically(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    return s.isEmpty || s == draft;
  }

  /// Ya salió de borrador → inmutable respecto a eliminación física.
  static bool isConfirmedOrBeyond(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    if (s.isEmpty || s == draft) return false;
    return true;
  }

  /// Enviado a cocina o posterior (sin contar cobrado/terminal).
  static bool wasSentToKitchen(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    return s == sent ||
        s == preparing ||
        s == ready ||
        s == delivered;
  }

  static bool isCancelledLike(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    return s == cancelled || s == voided;
  }

  static bool isPaidLike(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    return s == paid || s == completed || s == closed;
  }

  static bool isTerminal(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    return s == cancelled ||
        s == voided ||
        s == paid ||
        s == completed ||
        s == closed ||
        s == refunded ||
        s == returned;
  }

  /// Cancelar: confirmado y **aún no** enviado a cocina.
  static bool canCancel(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    if (canDiscardPhysically(s)) return false;
    if (isCancelledLike(s) || isPaidLike(s) || s == refunded || s == returned) {
      return false;
    }
    if (wasSentToKitchen(s)) return false;
    return s == open || s == confirmed;
  }

  /// Anular: ya enviado a cocina (o en prep/listo/entregado), aún no cobrado.
  static bool canVoid(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    if (isCancelledLike(s) || isPaidLike(s) || s == refunded || s == returned) {
      return false;
    }
    return wasSentToKitchen(s);
  }

  /// Reembolsar: cobrado / cerrado.
  static bool canRefund(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    return isPaidLike(s);
  }

  /// Acción primaria de aborto comercial para la UI.
  static OrderAbortAction abortAction(String? lifecycleStatus) {
    if (canRefund(lifecycleStatus)) return OrderAbortAction.refund;
    if (canVoid(lifecycleStatus)) return OrderAbortAction.voidOrder;
    if (canCancel(lifecycleStatus)) return OrderAbortAction.cancel;
    return OrderAbortAction.none;
  }

  static String label(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    return switch (s) {
      draft => 'BORRADOR',
      open || confirmed => 'CONFIRMADO',
      sent || preparing => 'EN PREPARACIÓN',
      ready => 'LISTO',
      delivered => 'ENTREGADO',
      paid || completed || closed => 'COMPLETADO',
      cancelled => 'CANCELADO',
      voided => 'ANULADO',
      refunded || returned => 'REEMBOLSADO',
      _ => s.toUpperCase(),
    };
  }
}

enum OrderAbortAction { none, cancel, voidOrder, refund }

/// Origen de auditoría del evento.
abstract final class OrderEventOrigin {
  static const eposone = 'EPOSONE';
  static const en1 = 'EN1';
  static const system = 'SYSTEM';
}

/// Política de acciones (roles completos = EN1/Portal; local = motivo obligatorio).
abstract final class OrderActionPolicy {
  static bool cashierMayCancelConfirmed({required bool hasReason}) =>
      hasReason;

  static bool cashierMayVoid({required bool hasReason}) => hasReason;

  static bool cashierMayDiscardDraft() => true;

  static bool mayRefund({required bool hasReason}) => hasReason;
}
