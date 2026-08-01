import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/printing/receipt_document_service.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/cash_register/data/cash_shift_sync_service.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/platform/presentation/utils/installation_gate.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';

class CashOpenScreen extends ConsumerStatefulWidget {
  const CashOpenScreen({super.key});

  @override
  ConsumerState<CashOpenScreen> createState() => _CashOpenScreenState();
}

class _CashOpenScreenState extends ConsumerState<CashOpenScreen> {
  final _amountController = TextEditingController(text: '0');
  bool _loading = false;
  bool _printOpen = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      await ensureInstallationReadyForPos(ref, context);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _enqueueEn1(String registerLocalId) async {
    final isar = await ref.read(databaseProvider.future);
    final config = await BusinessConfigRepository(isar).getConfig();
    if (!config.isEn1SyncReady) return;
    final sync = SyncRepository(isar);
    await CashShiftSyncService(isar: isar, syncRepository: sync)
        .enqueueIfReady(registerLocalId, config);
    try {
      await sync.runSyncCycle();
    } catch (_) {}
  }

  Future<void> _open() async {
    if (!await ensureInstallationReadyForPos(ref, context)) return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 0) return;

    setState(() => _loading = true);
    try {
      final session = ref.read(posSessionProvider);
      final repo = ref.read(cashRegisterRepositoryProvider);
      final existing = await repo.getOpenRegister();
      final createdNew = existing == null;
      final register = existing ??
          await repo.openRegister(
            amount,
            openedBy: session?.cashierName,
            cashierId: session?.cashierId,
            cashierContactId: session?.cashierContactId,
          );

      if (existing != null && session != null) {
        await repo.assignCurrentCashier(
          cashierId: session.cashierId,
          cashierName: session.cashierName,
          cashierContactId: session.cashierContactId,
        );
      }

      if (createdNew) {
        await _enqueueEn1(register.localId);
      }

      ref.read(posSessionProvider.notifier).setCashRegister(register.localId);
      if (createdNew && _printOpen && mounted) {
        final config = ref.read(businessConfigProvider);
        final symbol = config?.currencySymbol ?? 'B/.';
        await ReceiptDocumentService.printCashOpen(
          context: context,
          config: config,
          register: register,
          symbol: symbol,
        );
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
            Icon(Icons.account_balance_wallet,
                size: 64, color: Theme.of(context).colorScheme.primary),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Monto inicial',
                prefixText: 'B/. ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Imprimir apertura'),
              value: _printOpen,
              onChanged: (v) => setState(() => _printOpen = v),
            ),
            const Spacer(),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _loading ? null : _open,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
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
