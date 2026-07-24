import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eposone/src/features/commercial_engine/commercial_engine.dart';
import 'package:eposone/src/features/orders/domain/en1_tender_methods.dart';

/// Diálogo de cobro mixto (flujo cajero: solo métodos usados).
Future<TenderSettlement?> showMultiTenderPaymentDialog({
  required BuildContext context,
  required double balanceDue,
  required String title,
  required CommercialEngineFacade engine,
  String currencySymbol = 'B/.',
  double? orderTotal,
  double alreadyPaid = 0,
  String? orderLabel,
}) {
  return showDialog<TenderSettlement>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: MultiTenderPaymentPanel(
          balanceDue: balanceDue,
          engine: engine,
          currencySymbol: currencySymbol,
          orderTotal: orderTotal ?? (balanceDue + alreadyPaid),
          alreadyPaid: alreadyPaid,
          orderLabel: orderLabel ?? title,
          dialogTitle: title,
          onCancel: () => Navigator.pop(ctx),
          onConfirm: (s) => Navigator.pop(ctx, s),
        ),
      ),
    ),
  );
}

/// Panel reutilizable (dialog Pedidos EN1 + pantalla Cobrar POS).
class MultiTenderPaymentPanel extends StatefulWidget {
  const MultiTenderPaymentPanel({
    super.key,
    required this.balanceDue,
    required this.engine,
    required this.currencySymbol,
    required this.orderTotal,
    this.alreadyPaid = 0,
    this.orderLabel,
    this.dialogTitle,
    this.embedded = false,
    this.confirmLabel = 'Confirmar Cobro',
    this.onCancel,
    this.onConfirm,
    this.onSettlementChanged,
  });

  final double balanceDue;
  final CommercialEngineFacade engine;
  final String currencySymbol;
  final double orderTotal;
  final double alreadyPaid;
  final String? orderLabel;
  final String? dialogTitle;

  /// Si true, no dibuja botones Cancelar/Confirmar (el host los pone).
  final bool embedded;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final ValueChanged<TenderSettlement>? onConfirm;
  final ValueChanged<TenderLiveStatus>? onSettlementChanged;

  @override
  State<MultiTenderPaymentPanel> createState() =>
      MultiTenderPaymentPanelState();
}

class MultiTenderPaymentPanelState extends State<MultiTenderPaymentPanel> {
  final List<_TenderLine> _lines = [];

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  List<TenderAmount> _entered() {
    final out = <TenderAmount>[];
    for (final line in _lines) {
      final raw = line.amountCtrl.text.trim().replaceAll(',', '');
      if (raw.isEmpty) continue;
      final v = double.tryParse(raw);
      if (v == null || v <= 0) continue;
      final ref = line.refCtrl?.text.trim();
      out.add(
        TenderAmount(
          code: line.method.code,
          amount: v,
          reference: (ref != null && ref.isNotEmpty) ? ref : null,
        ),
      );
    }
    return out;
  }

  TenderLiveStatus get status => widget.engine.evaluatePayment(
        balanceDue: widget.balanceDue,
        entered: _entered(),
      );

  void _notify() {
    widget.onSettlementChanged?.call(status);
    setState(() {});
  }

  double get _remainingAfterTyped {
    return widget.engine
        .evaluatePayment(balanceDue: widget.balanceDue, entered: _entered())
        .remaining;
  }

  Future<void> _pickMethod() async {
    final used = {for (final l in _lines) l.method.code};
    final available =
        kEn1TenderMethods.where((m) => !used.contains(m.code)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya agregó todas las formas de pago')),
      );
      return;
    }

    final chosen = await showModalBottomSheet<En1TenderMethod>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Agregar método de pago',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            for (final m in available)
              ListTile(
                leading: Icon(
                  m.code == 'cash'
                      ? Icons.payments_outlined
                      : Icons.credit_card,
                ),
                title: Text(m.label),
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    final remaining = _remainingAfterTyped.clamp(0.0, double.infinity);
    final amountCtrl = TextEditingController(
      text: remaining > 0.009 ? remaining.toStringAsFixed(2) : '',
    );
    final refCtrl = chosen.showsReference ? TextEditingController() : null;
    amountCtrl.addListener(_notify);
    refCtrl?.addListener(_notify);

    setState(() {
      _lines.add(_TenderLine(
          method: chosen, amountCtrl: amountCtrl, refCtrl: refCtrl));
    });
    _notify();
  }

  void _removeLine(int index) {
    final line = _lines.removeAt(index);
    line.dispose();
    _notify();
  }

  void _fillFullBalanceCash() {
    final cashIdx = _lines.indexWhere((l) => l.method.code == 'cash');
    final nonCash = _entered().where((t) => t.code != 'cash').toList();
    final remainingWithoutCash = widget.engine
        .evaluatePayment(balanceDue: widget.balanceDue, entered: nonCash)
        .remaining
        .clamp(0.0, double.infinity);

    if (cashIdx >= 0) {
      _lines[cashIdx].amountCtrl.text = remainingWithoutCash.toStringAsFixed(2);
      _notify();
      return;
    }

    final amountCtrl =
        TextEditingController(text: remainingWithoutCash.toStringAsFixed(2));
    amountCtrl.addListener(_notify);
    setState(() {
      _lines.add(
        _TenderLine(
          method: kEn1TenderMethods.firstWhere((m) => m.code == 'cash'),
          amountCtrl: amountCtrl,
        ),
      );
    });
    _notify();
  }

  /// API pública para host embebido (pantalla Cobrar).
  TenderSettlement? tryConfirm() {
    final s = status;
    if (!s.canConfirm) return null;
    return s.settlement;
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.currencySymbol;
    final live = status;
    final remainingColor = live.remaining.abs() <= 0.009
        ? Colors.green.shade700
        : Colors.red.shade700;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.dialogTitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.dialogTitle!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (widget.onCancel != null)
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryCard(
                  symbol: symbol,
                  orderLabel: widget.orderLabel,
                  orderTotal: widget.orderTotal,
                  alreadyPaid: widget.alreadyPaid,
                  balanceDue: widget.balanceDue,
                  remainingAfterTyped: live.remaining,
                  remainingColor: remainingColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Métodos seleccionados',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (_lines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Ningún método aún. Use «Agregar método» o «Cobrar saldo completo».',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                for (var i = 0; i < _lines.length; i++) ...[
                  _TenderLineCard(
                    line: _lines[i],
                    symbol: symbol,
                    onRemove: () => _removeLine(i),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _pickMethod,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar método de pago'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _fillFullBalanceCash,
                  icon: const Icon(Icons.payments),
                  label: const Text('Cobrar saldo completo'),
                ),
                const SizedBox(height: 16),
                const Divider(),
                _kv('Total ingresado',
                    '$symbol${live.typedSum.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                _kv(
                  live.remaining > 0.009
                      ? 'Saldo restante'
                      : live.remaining < -0.009
                          ? 'Exceso / vuelto'
                          : 'Saldo restante',
                  '$symbol${live.remaining.abs().toStringAsFixed(2)}',
                  valueColor: remainingColor,
                  bold: true,
                ),
                if (live.exceedsBy > 0.009) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Excede el saldo por $symbol${live.exceedsBy.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (live.missingReference) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Complete la referencia en los métodos que la requieren.',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ],
                if (live.settlement != null &&
                    live.settlement!.change > 0.009) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.change_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Vuelto'),
                        const Spacer(),
                        Text(
                          '$symbol${live.settlement!.change.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancelar'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: live.canConfirm && widget.onConfirm != null
                      ? () => widget.onConfirm!(live.settlement!)
                      : null,
                  child: Text(widget.confirmLabel),
                ),
              ],
            ),
          ),
      ],
    );

    if (widget.embedded) return body;
    return Material(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(height: 560, child: body),
    );
  }

  Widget _kv(String k, String v, {Color? valueColor, bool bold = false}) {
    return Row(
      children: [
        Text(k),
        const Spacer(),
        Text(
          v,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _TenderLine {
  _TenderLine({
    required this.method,
    required this.amountCtrl,
    this.refCtrl,
  });

  final En1TenderMethod method;
  final TextEditingController amountCtrl;
  final TextEditingController? refCtrl;

  void dispose() {
    amountCtrl.dispose();
    refCtrl?.dispose();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.symbol,
    required this.orderTotal,
    required this.alreadyPaid,
    required this.balanceDue,
    required this.remainingAfterTyped,
    required this.remainingColor,
    this.orderLabel,
  });

  final String symbol;
  final String? orderLabel;
  final double orderTotal;
  final double alreadyPaid;
  final double balanceDue;
  final double remainingAfterTyped;
  final Color remainingColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (orderLabel != null && orderLabel!.isNotEmpty)
            Text(
              'Pedido: $orderLabel',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          if (orderLabel != null) const SizedBox(height: 8),
          _row('Total pedido', '$symbol${orderTotal.toStringAsFixed(2)}'),
          _row('Pagado', '$symbol${alreadyPaid.toStringAsFixed(2)}'),
          const Divider(height: 16),
          _row(
            'Saldo pendiente',
            '$symbol${balanceDue.toStringAsFixed(2)}',
            bold: true,
          ),
          const SizedBox(height: 6),
          _row(
            'Saldo restante',
            '$symbol${remainingAfterTyped.abs().toStringAsFixed(2)}',
            bold: true,
            color: remainingColor,
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(k, style: TextStyle(fontWeight: bold ? FontWeight.w600 : null)),
          const Spacer(),
          Text(
            v,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenderLineCard extends StatelessWidget {
  const _TenderLineCard({
    required this.line,
    required this.symbol,
    required this.onRemove,
  });

  final _TenderLine line;
  final String symbol;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.method.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            TextField(
              controller: line.amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '$symbol ',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            if (line.refCtrl != null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: line.refCtrl,
                decoration: InputDecoration(
                  labelText:
                      line.method.referenceMode == TenderReferenceMode.required
                          ? 'Referencia *'
                          : 'Referencia (opcional)',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: 'Autorización / voucher',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
