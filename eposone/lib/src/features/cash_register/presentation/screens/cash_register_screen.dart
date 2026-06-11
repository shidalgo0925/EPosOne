import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/cash_register/presentation/providers/cash_register_provider.dart';

class CashRegisterScreen extends ConsumerStatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  ConsumerState<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends ConsumerState<CashRegisterScreen> {
  final _amountController = TextEditingController();
  final _closingController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _closingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAsync = ref.watch(currentCashRegisterProvider);

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
      appBar: AppBar(
        title: const Text('Caja'),
      ),
      body: currentAsync.when(
        data: (current) {
          if (current == null) {
            return _OpenRegisterForm(
              amountController: _amountController,
              notesController: _notesController,
              onOpen: _openRegister,
            );
          }
          return _CurrentRegisterView(
            register: current,
            closingController: _closingController,
            notesController: _notesController,
            onClose: _closeRegister,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _openRegister() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser positivo')),
      );
      return;
    }
    ref.read(cashRegisterNotifierProvider.notifier).open(
      amount,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    _amountController.clear();
    _notesController.clear();
  }

  void _closeRegister(String registerId, double expectedAmount) {
    final closing = double.tryParse(_closingController.text) ?? 0;
    if (closing < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto de cierre debe ser positivo')),
      );
      return;
    }
    ref.read(cashRegisterNotifierProvider.notifier).close(
      registerId: registerId,
      closingAmount: closing,
      expectedAmount: expectedAmount,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    _closingController.clear();
    _notesController.clear();
  }
}

class _OpenRegisterForm extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController notesController;
  final VoidCallback onOpen;

  const _OpenRegisterForm({
    required this.amountController,
    required this.notesController,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.orange.shade400,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Caja Cerrada',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Abre la caja para comenzar a vender',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto inicial en caja *',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.attach_money),
              prefixText: '\$ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            decoration: InputDecoration(
              labelText: 'Notas (opcional)',
              hintText: 'Observaciones...',
              prefixIcon: const Icon(Icons.notes),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.lock_open),
              label: const Text('Abrir Caja'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentRegisterView extends ConsumerStatefulWidget {
  final CashRegister register;
  final TextEditingController closingController;
  final TextEditingController notesController;
  final Function(String, double) onClose;

  const _CurrentRegisterView({
    required this.register,
    required this.closingController,
    required this.notesController,
    required this.onClose,
  });

  @override
  ConsumerState<_CurrentRegisterView> createState() => _CurrentRegisterViewState();
}

class _CurrentRegisterViewState extends ConsumerState<_CurrentRegisterView> {
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(cashRegisterSalesSummaryProvider(widget.register.localId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade900.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade700),
            ),
            child: Column(
              children: [
                Icon(Icons.lock_open, size: 48, color: Colors.green.shade400),
                const SizedBox(height: 12),
                Text(
                  'Caja Abierta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade400,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Abierta: ${_formatDate(widget.register.openDate)}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Summary
          Text('Resumen del turno', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _SummaryCard(
            label: 'Monto inicial',
            value: '\$${widget.register.openingAmount.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
          ),
          summaryAsync.when(
            data: (summary) => Column(
              children: [
                _SummaryCard(
                  label: 'Ventas realizadas',
                  value: '${summary['count']} ventas',
                  icon: Icons.receipt_long,
                  color: Colors.green,
                ),
                _SummaryCard(
                  label: 'Total vendido',
                  value: '\$${(summary['total'] as double).toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                _SummaryCard(
                  label: 'Efectivo esperado',
                  value: '\$${(widget.register.openingAmount + (summary['total'] as double)).toStringAsFixed(2)}',
                  icon: Icons.calculate,
                  color: Colors.orange,
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Close register
          Text('Cerrar caja', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: widget.closingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto final en caja *',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.attach_money),
              prefixText: '\$ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.notesController,
            decoration: InputDecoration(
              labelText: 'Notas (opcional)',
              prefixIcon: const Icon(Icons.notes),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                final expected = widget.register.openingAmount +
                    (summaryAsync.valueOrNull?['total'] as double? ?? 0);
                widget.onClose(widget.register.localId, expected);
              },
              icon: const Icon(Icons.lock),
              label: const Text('Cerrar Caja'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
