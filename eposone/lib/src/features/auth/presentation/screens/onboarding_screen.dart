import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/database/seed_data.dart';
import 'package:eposone/src/core/startup/app_startup.dart';
import 'package:eposone/src/core/utils/pin_hash.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  final _businessName = TextEditingController();
  final _ruc = TextEditingController();
  final _address = TextEditingController();
  final _taxRate = TextEditingController(text: '7');
  final _cashierName = TextEditingController(text: 'Cajero Principal');
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();
  final _openingAmount = TextEditingController(text: '100');
  bool _loadingDemo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final isar = await ref.read(databaseProvider.future);
    final config = await BusinessConfigRepository(isar).getConfig();
    if (mounted) {
      _businessName.text = config.businessName == 'Mi Negocio' ? 'Istmo' : config.businessName;
      _ruc.text = config.ruc ?? '';
      _address.text = config.address ?? '';
      _taxRate.text = config.taxRate.toStringAsFixed(0);
      setState(() => _loadingDemo = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _businessName.dispose();
    _ruc.dispose();
    _address.dispose();
    _taxRate.dispose();
    _cashierName.dispose();
    _pin.dispose();
    _pinConfirm.dispose();
    _openingAmount.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_pin.text.length < 4) {
      _showError('El PIN debe tener al menos 4 dígitos');
      return;
    }
    if (_pin.text != _pinConfirm.text) {
      _showError('Los PIN no coinciden');
      return;
    }
    if (_businessName.text.trim().isEmpty) {
      _showError('Ingresa el nombre del negocio');
      return;
    }

    setState(() => _saving = true);
    try {
      final isar = await ref.read(databaseProvider.future);
      final configRepo = BusinessConfigRepository(isar);
      final cashierRepo = CashierRepository(isar);
      final cashRepo = CashRegisterRepository(isar);

      final tax = double.tryParse(_taxRate.text) ?? 7;
      final existing = await configRepo.getConfig();
      final config = existing.copyWith(
        businessName: _businessName.text.trim(),
        ruc: _ruc.text.trim().isEmpty ? null : _ruc.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        taxRate: tax,
        taxName: 'ITBMS',
        taxIncluded: true,
        currency: 'PAB',
        currencySymbol: 'B/.',
        trackInventory: false,
        openTicketsEnabled: true,
        defaultOrderType: OrderType.dineIn,
        isSetupComplete: true,
        updatedAt: DateTime.now(),
      );
      await configRepo.saveConfig(config);

      if (await cashierRepo.countCashiers() == 0) {
        await cashierRepo.saveCashier(
          Cashier.create(
            name: _cashierName.text.trim(),
            pinHash: hashPin(_pin.text),
            role: CashierRole.admin,
          ),
        );
      }

      await seedClientCatalog(isar);

      final openAmount = double.tryParse(_openingAmount.text) ?? 0;
      if (await cashRepo.getOpenRegister() == null) {
        await cashRepo.openRegister(openAmount, openedBy: _cashierName.text.trim());
      }

      ref.invalidate(appStartupProvider);
      if (mounted) context.go('/pin');
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _next() {
    if (_step == 0 && _businessName.text.trim().isEmpty) {
      _showError('Ingresa el nombre del negocio');
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDemo) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración inicial')),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / 3),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBusinessStep(),
                _buildCashierStep(),
                _buildCashStep(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _next,
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_step < 2 ? 'Continuar' : 'Finalizar'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Tu negocio', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        TextField(controller: _businessName, decoration: const InputDecoration(labelText: 'Nombre del negocio *', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _ruc, decoration: const InputDecoration(labelText: 'RUC (opcional)', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'Dirección (opcional)', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(
          controller: _taxRate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'ITBMS %', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildCashierStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Cajero principal', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        TextField(controller: _cashierName, decoration: const InputDecoration(labelText: 'Nombre del cajero', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(
          controller: _pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN (4-6 dígitos)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinConfirm,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Confirmar PIN', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildCashStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Caja inicial', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Monto con el que abres la caja hoy.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        TextField(
          controller: _openingAmount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Monto inicial (B/.)', prefixText: 'B/. ', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
