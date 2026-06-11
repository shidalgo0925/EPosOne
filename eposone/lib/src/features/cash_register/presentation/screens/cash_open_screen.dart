import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';

class CashOpenScreen extends ConsumerStatefulWidget {
  const CashOpenScreen({super.key});

  @override
  ConsumerState<CashOpenScreen> createState() => _CashOpenScreenState();
}

class _CashOpenScreenState extends ConsumerState<CashOpenScreen> {
  final _amountController = TextEditingController(text: '0');
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 0) return;

    setState(() => _loading = true);
    try {
      final session = ref.read(posSessionProvider);
      final repo = ref.read(cashRegisterRepositoryProvider);
      final existing = await repo.getOpenRegister();
      final register = existing ??
          await () async {
            await repo.openRegister(amount, openedBy: session?.cashierName);
            return repo.getOpenRegister();
          }();

      if (register != null) {
        ref.read(posSessionProvider.notifier).setCashRegister(register.localId);
      }
      if (mounted) context.go('/pos');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(posSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Abrir caja')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Hola${session != null ? ', ${session.cashierName}' : ''}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa el monto inicial en caja para comenzar a vender.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Monto inicial',
                prefixText: 'B/. ',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _loading ? null : _open,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_open),
                label: const Text('Abrir caja'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
