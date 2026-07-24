/// Métodos de cobro operativos (UI POS / Pedidos EN1).
///
/// `code` se envía en `POST /payments` como `method` (contrato congelado).
enum TenderReferenceMode { none, optional, required }

class En1TenderMethod {
  const En1TenderMethod({
    required this.code,
    required this.label,
    this.allowsChange = false,
    this.referenceMode = TenderReferenceMode.none,
  });

  final String code;
  final String label;
  final bool allowsChange;
  final TenderReferenceMode referenceMode;

  bool get showsReference => referenceMode != TenderReferenceMode.none;
}

/// Catálogo fijo de caja (pago mixto).
const kEn1TenderMethods = <En1TenderMethod>[
  En1TenderMethod(code: 'cash', label: 'Efectivo', allowsChange: true),
  En1TenderMethod(
    code: 'visa',
    label: 'Visa',
    referenceMode: TenderReferenceMode.required,
  ),
  En1TenderMethod(
    code: 'mastercard',
    label: 'Mastercard',
    referenceMode: TenderReferenceMode.required,
  ),
  En1TenderMethod(
    code: 'clave',
    label: 'Clave',
    referenceMode: TenderReferenceMode.required,
  ),
  En1TenderMethod(
    code: 'yappy',
    label: 'Yappy',
    referenceMode: TenderReferenceMode.required,
  ),
  En1TenderMethod(
    code: 'ach',
    label: 'ACH',
    referenceMode: TenderReferenceMode.required,
  ),
  En1TenderMethod(
    code: 'voucher',
    label: 'Vale',
    referenceMode: TenderReferenceMode.optional,
  ),
  En1TenderMethod(code: 'customer_credit', label: 'Crédito Cliente'),
  En1TenderMethod(
    code: 'gift_card',
    label: 'Gift Card',
    referenceMode: TenderReferenceMode.required,
  ),
  En1TenderMethod(
    code: 'other',
    label: 'Otros',
    referenceMode: TenderReferenceMode.optional,
  ),
];

En1TenderMethod? tenderMethodByCode(String code) {
  for (final m in kEn1TenderMethods) {
    if (m.code == code) return m;
  }
  return null;
}

/// Línea de tender capturada en UI (monto digitado > 0).
class TenderAmount {
  const TenderAmount({
    required this.code,
    required this.amount,
    this.reference,
  });

  final String code;
  final double amount;
  /// Ref. de autorización / voucher (va a `OrderPayment.notes`).
  final String? reference;
}

/// Resultado de repartir montos contra un saldo (sin inventar payload HTTP).
class TenderSettlement {
  const TenderSettlement({
    required this.paymentsToPost,
    required this.change,
    required this.amountReceived,
  });

  /// Montos exactos a persistir / POST `/payments` (cubren el saldo, sin vuelto).
  final List<TenderAmount> paymentsToPost;

  /// Vuelto (solo efectivo).
  final double change;

  /// Suma digitada por el cajero (puede incluir vuelto).
  final double amountReceived;
}

/// Snapshot de validación en tiempo real (UI cajero).
class TenderLiveStatus {
  const TenderLiveStatus({
    required this.typedSum,
    required this.remaining,
    required this.exceedsBy,
    required this.settlement,
    required this.missingReference,
  });

  final double typedSum;
  final double remaining;
  final double exceedsBy;
  final TenderSettlement? settlement;
  final bool missingReference;

  bool get canConfirm => settlement != null && !missingReference && exceedsBy <= 0.009;
}

TenderLiveStatus evaluateTenders({
  required double balanceDue,
  required List<TenderAmount> entered,
}) {
  final positive = entered.where((t) => t.amount > 0.00001).toList();
  final typed = double.parse(
    positive.fold<double>(0, (s, t) => s + t.amount).toStringAsFixed(2),
  );
  final remaining = double.parse((balanceDue - typed).toStringAsFixed(2));

  final nonCashSum = positive
      .where((t) => t.code != 'cash')
      .fold<double>(0, (s, t) => s + t.amount);
  final exceedsBy = nonCashSum - balanceDue > 0.009
      ? double.parse((nonCashSum - balanceDue).toStringAsFixed(2))
      : (typed - balanceDue > 0.009 &&
              !positive.any((t) => t.code == 'cash')
          ? double.parse((typed - balanceDue).toStringAsFixed(2))
          : 0.0);

  var missingRef = false;
  for (final t in positive) {
    final m = tenderMethodByCode(t.code);
    if (m?.referenceMode == TenderReferenceMode.required &&
        (t.reference == null || t.reference!.trim().isEmpty)) {
      missingRef = true;
      break;
    }
  }

  final settlement = settleTenders(balanceDue: balanceDue, entered: positive);
  return TenderLiveStatus(
    typedSum: typed,
    remaining: remaining,
    exceedsBy: exceedsBy > 0 ? exceedsBy : 0,
    settlement: settlement,
    missingReference: missingRef,
  );
}

/// Valida y reparte: no-efectivo primero (exacto), efectivo cubre resto + vuelto.
TenderSettlement? settleTenders({
  required double balanceDue,
  required List<TenderAmount> entered,
}) {
  if (balanceDue <= 0) return null;
  final positive = entered.where((t) => t.amount > 0.00001).toList();
  if (positive.isEmpty) return null;

  final cashLines = positive.where((t) => t.code == 'cash').toList();
  final cash = cashLines.fold<double>(0, (s, t) => s + t.amount);
  final nonCash = positive.where((t) => t.code != 'cash').toList();
  final nonCashSum = nonCash.fold<double>(0, (s, t) => s + t.amount);

  if (nonCashSum - balanceDue > 0.009) {
    return null;
  }

  final remainingAfterCards =
      double.parse((balanceDue - nonCashSum).toStringAsFixed(2));
  if (remainingAfterCards > 0.009 && cash + 0.001 < remainingAfterCards) {
    return null;
  }

  final posts = <TenderAmount>[
    for (final t in nonCash)
      TenderAmount(
        code: t.code,
        amount: double.parse(t.amount.toStringAsFixed(2)),
        reference: t.reference,
      ),
  ];

  var change = 0.0;
  if (remainingAfterCards > 0.009) {
    posts.add(
      TenderAmount(
        code: 'cash',
        amount: remainingAfterCards,
        reference: cashLines.isNotEmpty ? cashLines.first.reference : null,
      ),
    );
    change = double.parse((cash - remainingAfterCards).toStringAsFixed(2));
  } else if (cash > 0.009) {
    return null;
  }

  final received = positive.fold<double>(0, (s, t) => s + t.amount);
  return TenderSettlement(
    paymentsToPost: posts,
    change: change < 0 ? 0 : change,
    amountReceived: double.parse(received.toStringAsFixed(2)),
  );
}
