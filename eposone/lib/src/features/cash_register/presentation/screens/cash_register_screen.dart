import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

/// Hub del turno — resumen L4.3 + acceso a tesorería y cierre.
class CashRegisterScreen extends ConsumerWidget {
  const CashRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(currentCashRegisterProvider);
    final symbol = ref.watch(businessConfigProvider)?.currencySymbol ?? 'B/.';

    ref.listen(cashRegisterNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ref.invalidate(currentCashRegisterProvider);
          ref.invalidate(cashRegisterHistoryProvider);
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Turno / Caja')),
      body: currentAsync.when(
        data: (current) {
          if (current == null) {
            return _OpenRegisterPanel(symbol: symbol);
          }
          return _ShiftHub(register: current, symbol: symbol);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OpenRegisterPanel extends ConsumerStatefulWidget {
  final String symbol;
  const _OpenRegisterPanel({required this.symbol});

  @override
  ConsumerState<_OpenRegisterPanel> createState() => _OpenRegisterPanelState();
}

class _OpenRegisterPanelState extends ConsumerState<_OpenRegisterPanel> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: EposBrand.orange),
          const SizedBox(height: 16),
          const Text(
            'No hay turno abierto',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: EposBrand.navy),
          ),
          const SizedBox(height: 8),
          const Text(
            'Abre la caja para comenzar a vender',
            textAlign: TextAlign.center,
            style: TextStyle(color: EposBrand.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto inicial en caja',
              prefixText: '${widget.symbol} ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              final amount = double.tryParse(_amountCtrl.text) ?? -1;
              if (amount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Indica un monto válido')),
                );
                return;
              }
              ref.read(cashRegisterNotifierProvider.notifier).open(
                    amount,
                    openedBy: ref.read(posSessionProvider)?.cashierName,
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                  );
            },
            icon: const Icon(Icons.lock_open),
            label: const Text('Abrir turno'),
          ),
        ],
      ),
    );
  }
}

class _ShiftHub extends ConsumerWidget {
  final CashRegister register;
  final String symbol;

  const _ShiftHub({required this.register, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(shiftSummaryProvider(register.localId));
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return summaryAsync.when(
      data: (summary) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade400),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_open, color: Colors.green, size: 40),
                  const SizedBox(height: 8),
                  const Text('Turno abierto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Desde ${dateFmt.format(register.openDate)}', style: const TextStyle(color: EposBrand.textSecondary)),
                  if (register.openedBy != null)
                    Text('Por ${register.openedBy}', style: const TextStyle(color: EposBrand.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Resumen del turno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EposBrand.navy)),
            const SizedBox(height: 8),
            _SummaryTile(label: 'Ventas brutas', value: '$symbol${summary.grossSales.toStringAsFixed(2)}'),
            _SummaryTile(label: 'Reembolsos', value: '-$symbol${summary.totalRefunds.toStringAsFixed(2)}', valueColor: Colors.red),
            _SummaryTile(label: 'Ventas netas', value: '$symbol${summary.netSales.toStringAsFixed(2)}', bold: true),
            _SummaryTile(label: 'Descuentos', value: '$symbol${summary.totalDiscount.toStringAsFixed(2)}'),
            _SummaryTile(label: 'ITBMS', value: '$symbol${summary.totalTax.toStringAsFixed(2)}'),
            _SummaryTile(label: 'Transacciones', value: '${summary.saleCount} ventas · ${summary.refundCount} reembolsos'),
            const Divider(height: 24),
            const Text('Por método de pago', style: TextStyle(fontWeight: FontWeight.w600, color: EposBrand.navy)),
            const SizedBox(height: 8),
            for (final method in PaymentMethod.values)
              if (summary.paymentTotal(method) > 0)
                _SummaryTile(
                  label: paymentMethodLabel(method),
                  value: '$symbol${summary.paymentTotal(method).toStringAsFixed(2)}',
                ),
            const Divider(height: 24),
            _SummaryTile(label: 'Apertura', value: '$symbol${summary.openingAmount.toStringAsFixed(2)}'),
            _SummaryTile(label: 'Efectivo ventas (neto)', value: '$symbol${summary.cashFromSales.toStringAsFixed(2)}'),
            _SummaryTile(label: 'Movimientos +', value: '+$symbol${summary.cashMovementIn.toStringAsFixed(2)}', valueColor: Colors.green),
            _SummaryTile(label: 'Movimientos −', value: '-$symbol${summary.cashMovementOut.toStringAsFixed(2)}', valueColor: Colors.red),
            _SummaryTile(
              label: 'Efectivo esperado',
              value: '$symbol${summary.expectedCash.toStringAsFixed(2)}',
              bold: true,
              valueColor: EposBrand.orange,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/cash-register/treasury'),
              icon: const Icon(Icons.swap_vert),
              label: const Text('Tesorería'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push('/cash-register/close'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              icon: const Icon(Icons.lock),
              label: const Text('Cerrar turno'),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryTile({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? EposBrand.navy,
            ),
          ),
        ],
      ),
    );
  }
}
