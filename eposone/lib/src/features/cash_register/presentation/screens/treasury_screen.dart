import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_movement.dart';
import 'package:eposone/src/features/cash_register/presentation/providers/cash_register_provider.dart';

/// L4.1 — Movimientos de caja (entradas, retiros, depósitos, ajustes).
class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerAsync = ref.watch(currentCashRegisterProvider);
    final symbol = ref.watch(businessConfigProvider)?.currencySymbol ?? 'B/.';
    final dateFmt = DateFormat('dd/MM HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Tesorería')),
      floatingActionButton: registerAsync.maybeWhen(
        data: (reg) => reg == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showAddMovement(context, ref, reg.localId),
                icon: const Icon(Icons.add),
                label: const Text('Movimiento'),
              ),
        orElse: () => null,
      ),
      body: registerAsync.when(
        data: (register) {
          if (register == null) {
            return const Center(child: Text('No hay turno abierto'));
          }
          final movementsAsync = ref.watch(cashMovementsProvider(register.localId));
          return movementsAsync.when(
            data: (movements) {
              if (movements.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Sin movimientos en este turno'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _showAddMovement(context, ref, register.localId),
                        child: const Text('Registrar entrada o retiro'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: movements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final m = movements[i];
                  final out = m.isOutflow;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (out ? Colors.red : Colors.green).withValues(alpha: 0.15),
                        child: Icon(out ? Icons.remove : Icons.add, color: out ? Colors.red : Colors.green),
                      ),
                      title: Text(m.reason, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${cashMovementTypeLabel(m.type)} · ${dateFmt.format(m.movementDate)}'
                        '${m.cashierName != null ? ' · ${m.cashierName}' : ''}',
                      ),
                      trailing: Text(
                        '${out ? '−' : '+'}$symbol${m.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: out ? Colors.red : Colors.green.shade700,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showAddMovement(BuildContext context, WidgetRef ref, String registerId) async {
    var type = CashMovementType.income;
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nuevo movimiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CashMovementType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: CashMovementType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(cashMovementTypeLabel(t))))
                      .toList(),
                  onChanged: (v) => setState(() => type = v ?? CashMovementType.income),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Motivo *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Observación', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(cashMovementActionsProvider).addMovement(
            cashRegisterId: registerId,
            type: type,
            amount: double.tryParse(amountCtrl.text) ?? 0,
            reason: reasonCtrl.text,
            notes: notesCtrl.text,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movimiento registrado')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
