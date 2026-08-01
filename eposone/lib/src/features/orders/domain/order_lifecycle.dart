/// Ciclo de vida operativo del Pedido (Local) alineado a EN1 Event Driven.
///
/// Tipos HTTP de evento siguen el contrato congelado
/// (`pedido.anulado`, `pedido.devuelto`, …) — no se inventan alias EN.
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

  static bool isCancelledLike(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    return s == cancelled || s == voided;
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

  static bool canCancel(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    if (isCancelledLike(s)) return false;
    if (s == paid || s == completed || s == closed || s == refunded) {
      return false;
    }
    return isConfirmedOrBeyond(s);
  }

  static bool canRefund(String? lifecycleStatus) {
    final s = normalize(lifecycleStatus);
    return s == paid ||
        s == completed ||
        s == closed ||
        s == delivered ||
        s == refunded;
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
      cancelled || voided => 'CANCELADO',
      refunded || returned => 'REEMBOLSADO',
      _ => s.toUpperCase(),
    };
  }
}

/// Origen de auditoría del evento.
abstract final class OrderEventOrigin {
  static const eposone = 'EPOSONE';
  static const en1 = 'EN1';
  static const system = 'SYSTEM';
}

/// Política de acciones (roles completos = EN1/Portal; local = motivo obligatorio).
abstract final class OrderActionPolicy {
  /// Cancelar pedido confirmado: requiere motivo; rol supervisor = futuro EN1.
  static bool cashierMayCancelConfirmed({required bool hasReason}) =>
      hasReason;

  static bool cashierMayDiscardDraft() => true;

  /// Reembolso: motivo obligatorio (supervisor en BO).
  static bool mayRefund({required bool hasReason}) => hasReason;
}
