import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/printing/receipt_document_service.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/utils/view_insets.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/cash_register/domain/shift_summary.dart';
import 'package:eposone/src/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_provider.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

/// Cierre de turno + documento Z (auto-print).
class CashCloseScreen extends ConsumerStatefulWidget {
  const CashCloseScreen({super.key});

  @override
  ConsumerState<CashCloseScreen> createState() => _CashCloseScreenState();
}

class _CashCloseScreenState extends ConsumerState<CashCloseScreen> {
  final _countedCashCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _closing = false;
  CashRegister? _zRegister;
  ShiftSummary? _zSummary;
  double? _zCounted;
  double? _zDiff;

  @override
  void dispose() {
    _countedCashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerAsync = ref.watch(currentCashRegisterProvider);
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';

    ref.listen(cashRegisterNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) async {
          if (!_closing) return;
          final reg = _zRegister;
          final sum = _zSummary;
          if (reg != null && sum != null && mounted) {
            await ReceiptDocumentService.printShiftReport(
              context: context,
              config: config,
              register: reg,
              summary: sum,
              symbol: symbol,
              isClosing: true,
              countedCash: _zCounted,
              difference: _zDiff,
            );
          }
          ref.invalidate(currentCashRegisterProvider);
          ref.read(posSessionProvider.notifier).clearCashRegister();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Turno cerrado')),
            );
            context.go('/cash/open');
          }
        },
        error: (e, _) {
          _closing = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e}'), backgroundColor: Colors.red),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Cerrar turno')),
      body: registerAsync.when(
        data: (register) {
          if (register == null) {
            return const Center(child: Text('No hay turno abierto'));
          }
          final summaryAsync = ref.watch(shiftSummaryProvider(register.localId));
          return summaryAsync.when(
            data: (summary) {
              final counted = double.tryParse(_countedCashCtrl.text);
              final difference =
                  counted != null ? counted - summary.expectedCash : null;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, ViewInsets.bottom(context) + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Arqueo de caja',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: EposBrand.navy),
                    ),
                    const SizedBox(height: 16),
                    _ArqueoCard(
                      label: 'Efectivo esperado',
                      value:
                          '${symbol}${summary.expectedCash.toStringAsFixed(2)}',
                      icon: Icons.calculate,
                      color: EposBrand.orange,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _countedCashCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Efectivo contado en caja',
                        prefixText: '${symbol} ',
                        border: const OutlineInputBorder(),
                        filled: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (difference != null) ...[
                      const SizedBox(height: 12),
                      _ArqueoCard(
                        label: 'Diferencia',
                        value:
                            '${difference >= 0 ? '+' : ''}${symbol}${difference.toStringAsFixed(2)}',
                        icon: difference == 0
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        color: difference == 0
                            ? Colors.green
                            : (difference > 0 ? Colors.blue : Colors.red),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text('Otros metodos (informativo)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (final method in PaymentMethod.values)
                      if (method != PaymentMethod.cash &&
                          summary.paymentTotal(method) > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(paymentMethodLabel(method))),
                              Text(
                                  '${symbol}${summary.paymentTotal(method).toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notas de cierre',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _closing || counted == null || counted < 0
                          ? null
                          : () => _confirmClose(register, summary, counted),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          minimumSize: const Size.fromHeight(52)),
                      icon: _closing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.lock),
                      label: const Text('Confirmar cierre de turno'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: ${e}')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ${e}')),
      ),
    );
  }

  Future<void> _confirmClose(
    CashRegister register,
    ShiftSummary summary,
    double counted,
  ) async {
    final expected = summary.expectedCash;
    final diff = counted - expected;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cierre'),
        content: Text(
          diff == 0
              ? 'Cerrar el turno? Se imprimira el cierre (Z).'
              : 'Hay una diferencia de ${diff.toStringAsFixed(2)}. Cerrar e imprimir Z?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar turno')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _closing = true;
      _zRegister = register;
      _zSummary = summary;
      _zCounted = counted;
      _zDiff = diff;
    });
    final session = ref.read(posSessionProvider);
    await ref.read(cashRegisterNotifierProvider.notifier).close(
          registerId: register.localId,
          closingAmount: counted,
          expectedAmount: expected,
          closedBy: session?.cashierName,
          notes:
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
  }
}

class _ArqueoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ArqueoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
