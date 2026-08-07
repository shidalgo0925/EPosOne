import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/database/istmo_seed_data.dart';
import 'package:eposone/src/core/startup/app_startup.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/utils/pin_hash.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/features/platform/data/activation_claims_store.dart';
import 'package:eposone/src/features/platform/data/standalone_assistant_draft_store.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';

/// ADR-033 — Asistente Standalone hasta READY_TO_SELL (sin Bootstrap Connected).
class StandaloneAssistantScreen extends ConsumerStatefulWidget {
  const StandaloneAssistantScreen({super.key});

  @override
  ConsumerState<StandaloneAssistantScreen> createState() =>
      _StandaloneAssistantScreenState();
}

class _StandaloneAssistantScreenState
    extends ConsumerState<StandaloneAssistantScreen> {
  static const _titles = [
    'Empresa',
    'Impuestos y moneda',
    'Menú Itsmo',
    'Caja local',
    'Cajero administrador',
    'Impresora',
    'Listo para vender',
  ];

  final _page = PageController();
  final _businessName = TextEditingController(text: 'Café Amor');
  final _ruc = TextEditingController();
  final _address = TextEditingController();
  final _taxRate = TextEditingController(text: '7');
  final _cashLabel = TextEditingController(text: 'Caja 1');
  final _cashierName = TextEditingController(text: 'Administrador');
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();
  final _openingAmount = TextEditingController(text: '0');

  int _step = 0;
  String _currency = 'PAB';
  String _currencySymbol = 'B/.';
  String _taxName = 'ITBMS';
  bool _skipPrinter = true;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_boot);
  }

  Future<void> _boot() async {
    final ok = await ActivationClaimsStore.hasValidStandalone();
    if (!ok) {
      if (!mounted) return;
      context.go('/platform/activate');
      return;
    }
    if (await StandaloneAssistantDraftStore.isReadyToSell()) {
      if (!mounted) return;
      context.go('/pin');
      return;
    }
    final draft = await StandaloneAssistantDraftStore.load();
    if (draft != null) {
      _applyDraft(draft);
    } else if (_businessName.text.trim().isEmpty) {
      _businessName.text = 'Café Amor';
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (draft != null && draft.step > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_page.hasClients) {
          _page.jumpToPage(draft.step.clamp(0, _titles.length - 1));
        }
      });
    }
  }

  void _applyDraft(StandaloneAssistantDraft d) {
    _step = d.step.clamp(0, _titles.length - 1);
    _businessName.text = d.businessName;
    _ruc.text = d.ruc;
    _address.text = d.address;
    _currency = d.currency;
    _currencySymbol = d.currencySymbol;
    _taxName = d.taxName;
    _taxRate.text = d.taxRate.toStringAsFixed(
      d.taxRate == d.taxRate.roundToDouble() ? 0 : 1,
    );
    if (_businessName.text.trim().isEmpty) {
      _businessName.text = 'Café Amor';
    }
    _cashLabel.text = d.cashLabel;
    _cashierName.text = d.cashierName;
    _openingAmount.text = d.openingAmount.toStringAsFixed(2);
    _skipPrinter = d.skipPrinter;
  }

  StandaloneAssistantDraft _captureDraft({int? step}) =>
      StandaloneAssistantDraft(
        step: step ?? _step,
        businessName: _businessName.text.trim(),
        ruc: _ruc.text.trim(),
        address: _address.text.trim(),
        currency: _currency,
        currencySymbol: _currencySymbol,
        taxName: _taxName,
        taxRate: double.tryParse(_taxRate.text) ?? 7,
        categoryName: 'Itsmo Brew',
        productName: 'Menú Itsmo (~110)',
        productPrice: 0,
        cashLabel: _cashLabel.text.trim().isEmpty
            ? 'Caja 1'
            : _cashLabel.text.trim(),
        cashierName: _cashierName.text.trim().isEmpty
            ? 'Administrador'
            : _cashierName.text.trim(),
        openingAmount: double.tryParse(_openingAmount.text) ?? 0,
        skipPrinter: _skipPrinter,
      );

  Future<void> _persistDraft({int? step}) async {
    await StandaloneAssistantDraftStore.save(_captureDraft(step: step));
  }

  @override
  void dispose() {
    _page.dispose();
    _businessName.dispose();
    _ruc.dispose();
    _address.dispose();
    _taxRate.dispose();
    _cashLabel.dispose();
    _cashierName.dispose();
    _pin.dispose();
    _pinConfirm.dispose();
    _openingAmount.dispose();
    super.dispose();
  }

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (_businessName.text.trim().isEmpty) {
          return 'Ingrese el nombre del negocio.';
        }
      case 1:
        if ((double.tryParse(_taxRate.text) ?? -1) < 0) {
          return 'Indique un impuesto válido (0 o más).';
        }
      case 2:
        break; // Menú Itsmo precargado
      case 3:
        if (_cashLabel.text.trim().isEmpty) return 'Nombre de caja requerido.';
      case 4:
        if (_pin.text.length < 4 || _pin.text.length > 6) {
          return 'El PIN debe tener entre 4 y 6 dígitos.';
        }
        if (_pin.text != _pinConfirm.text) return 'Los PIN no coinciden.';
        if (RegExp(r'^(.)\1+$').hasMatch(_pin.text) ||
            _pin.text == '1234' ||
            _pin.text == '0000') {
          return 'Elija un PIN menos predecible.';
        }
      case 5:
      case 6:
        break;
    }
    return null;
  }

  Future<void> _next() async {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);
    if (_step >= _titles.length - 1) {
      await _finish();
      return;
    }
    final next = _step + 1;
    await _persistDraft(step: next);
    setState(() => _step = next);
    await _page.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _back() async {
    if (_step == 0) return;
    final prev = _step - 1;
    await _persistDraft(step: prev);
    setState(() {
      _step = prev;
      _error = null;
    });
    await _page.animateToPage(
      prev,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    for (var i = 0; i < 5; i++) {
      final e = _validateStep(i);
      if (e != null) {
        setState(() {
          _error = e;
          _step = i;
        });
        _page.jumpToPage(i);
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final isar = await ref.read(databaseProvider.future);
      final configRepo = BusinessConfigRepository(isar);
      final cashierRepo = CashierRepository(isar);
      final cashRepo = CashRegisterRepository(isar);

      // Menú Itsmo Brew (~110 productos + páginas Comida/Bar) en este dispositivo.
      await seedIstmoCatalog(isar);

      final tax = double.tryParse(_taxRate.text) ?? 7;
      final afterSeed = await configRepo.getConfig();
      await configRepo.saveConfig(
        afterSeed
            .copyWith(
              businessName: _businessName.text.trim().isEmpty
                  ? 'Café Amor'
                  : _businessName.text.trim(),
              ruc: _ruc.text.trim().isEmpty ? null : _ruc.text.trim(),
              address:
                  _address.text.trim().isEmpty ? null : _address.text.trim(),
              taxRate: tax,
              taxName: _taxName,
              taxIncluded: true,
              currency: _currency,
              currencySymbol: _currencySymbol,
              trackInventory: false,
              openTicketsEnabled: true,
              defaultOrderType: OrderType.dineIn,
              isSetupComplete: true,
              en1SyncEnabled: false,
              updatedAt: DateTime.now(),
            )
            .markAsModified(),
      );

      if (await cashierRepo.countCashiers() == 0) {
        await cashierRepo.saveCashier(
          Cashier.create(
            name: _cashierName.text.trim().isEmpty
                ? 'Administrador'
                : _cashierName.text.trim(),
            pinHash: hashPin(_pin.text),
            role: CashierRole.admin,
          ),
        );
      }

      final openAmount = double.tryParse(_openingAmount.text) ?? 0;
      if (await cashRepo.getOpenRegister() == null) {
        final cashiers = await cashierRepo.getActiveCashiers();
        final opener = cashiers.isNotEmpty ? cashiers.first : null;
        await cashRepo.openRegister(
          openAmount,
          openedBy: opener?.name ?? _cashierName.text.trim(),
          cashierId: opener?.localId,
        );
      }

      await StandaloneAssistantDraftStore.markReadyToSell();
      ref.invalidate(appStartupProvider);

      if (!mounted) return;
      context.go('/pin');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo guardar la configuración. Intente de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: EposBrand.background,
      appBar: AppBar(
        title: Text('Asistente · ${_titles[_step]}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saving
              ? null
              : () {
                  if (_step == 0) {
                    context.go('/platform/welcome');
                  } else {
                    _back();
                  }
                },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: LinearProgressIndicator(
                value: (_step + 1) / _titles.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
                color: EposBrand.orange,
                backgroundColor: EposBrand.divider,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _stepEmpresa(),
                  _stepImpuestos(),
                  _stepMenuItsmo(),
                  _stepCaja(),
                  _stepCajero(),
                  _stepImpresora(),
                  _stepFinal(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: _saving ? null : _back,
                      child: const Text('Atrás'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _next,
                    child: Text(
                      _step == _titles.length - 1
                          ? 'Empezar a vender'
                          : 'Continuar',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pad(List<Widget> children) => ListView(
        padding: const EdgeInsets.all(24),
        children: children,
      );

  Widget _stepEmpresa() => _pad([
        const Text(
          'Datos de su negocio (quedan en este dispositivo).',
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _businessName,
          decoration: const InputDecoration(labelText: 'Nombre comercial *'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ruc,
          decoration: const InputDecoration(labelText: 'RUC (opcional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
        ),
      ]);

  Widget _stepImpuestos() => _pad([
        const Text(
          'Moneda e impuesto por defecto.',
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _currency,
          decoration: const InputDecoration(labelText: 'Moneda'),
          items: const [
            DropdownMenuItem(value: 'PAB', child: Text('PAB · B/.')),
            DropdownMenuItem(value: 'USD', child: Text('USD · \$')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _currency = v;
              _currencySymbol = v == 'USD' ? '\$' : 'B/.';
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _taxRate,
          decoration: InputDecoration(labelText: '$_taxName %'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
      ]);

  Widget _stepMenuItsmo() => _pad([
        const Icon(Icons.restaurant_menu, size: 56, color: EposBrand.orange),
        const SizedBox(height: 16),
        Text(
          'Menú Itsmo Brew',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: EposBrand.navy,
              ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Al terminar el asistente se cargará en este dispositivo el '
          'catálogo demo Itsmo Brew (~110 productos, páginas Comida y Bar, '
          'precios con ITBMS incluido).\n\n'
          'El negocio (p. ej. Café Amor) queda local; el menú no viene de EN1.',
          textAlign: TextAlign.center,
          style: TextStyle(color: EposBrand.textSecondary, height: 1.4),
        ),
      ]);

  Widget _stepCaja() => _pad([
        const Text(
          'Caja local en este dispositivo (no es una caja EN1).',
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cashLabel,
          decoration: const InputDecoration(labelText: 'Nombre de caja *'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _openingAmount,
          decoration: InputDecoration(
            labelText: 'Monto de apertura ($_currencySymbol)',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ]);

  Widget _stepCajero() => _pad([
        const Text(
          'Cajero administrador con PIN.',
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cashierName,
          decoration: const InputDecoration(labelText: 'Nombre *'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pin,
          decoration: const InputDecoration(labelText: 'PIN (4–6 dígitos) *'),
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        TextField(
          controller: _pinConfirm,
          decoration: const InputDecoration(labelText: 'Confirmar PIN *'),
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
      ]);

  Widget _stepImpresora() => _pad([
        const Text(
          'Puede configurar la impresora después.',
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Configurar impresora más tarde'),
          value: _skipPrinter,
          onChanged: (v) => setState(() => _skipPrinter = v),
        ),
        if (!_skipPrinter)
          const Text(
            'Use Configuración → Impresora después de entrar al POS.',
            style: TextStyle(color: EposBrand.textSecondary),
          ),
      ]);

  Widget _stepFinal() => _pad([
        const Icon(Icons.check_circle_outline, size: 72, color: EposBrand.orange),
        const SizedBox(height: 16),
        Text(
          'EPOSOne está listo',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: EposBrand.navy,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_businessName.text.trim().isEmpty ? 'Café Amor' : _businessName.text.trim()}\n'
          'Menú: Itsmo Brew (~110 productos)\n'
          'Caja: ${_cashLabel.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: EposBrand.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 16),
        const Text(
          'Al continuar se carga el menú, se guarda la configuración local '
          'y podrá ingresar con su PIN para vender.',
          textAlign: TextAlign.center,
          style: TextStyle(color: EposBrand.textSecondary),
        ),
        if (_saving) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
      ]);
}
