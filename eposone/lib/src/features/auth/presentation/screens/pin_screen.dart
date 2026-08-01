import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/core/time/en1_clock_guard.dart';
import 'package:eposone/src/core/utils/pin_hash.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/auth/domain/cashier_display.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/en1_cashier_catalog_store.dart';
import 'package:eposone/src/features/platform/presentation/utils/installation_gate.dart';
import 'package:eposone/src/features/pos/presentation/utils/pos_layout.dart';

/// Cajero seleccionable: EN1 o local.
class _LoginCashierOption {
  final String key;
  final String name;
  final String? code;
  final int? contactId;
  final Cashier? local;
  final bool hasPin;

  const _LoginCashierOption({
    required this.key,
    required this.name,
    this.code,
    this.contactId,
    this.local,
    this.hasPin = true,
  });
}

final loginCashiersProvider =
    FutureProvider<List<_LoginCashierOption>>((ref) async {
  final en1 = await En1CashierCatalogStore.listActiveWithVerifiers();
  if (en1.isNotEmpty) {
    return [
      for (final c in en1)
        _LoginCashierOption(
          key: c.localId,
          name: CashierDisplay.displayName(
            name: c.cashierName,
            contactId: c.cashierContactId,
            code: c.cashierCode,
          ),
          code: c.cashierCode,
          contactId: c.cashierContactId,
          hasPin: (c.pinVerifier ?? '').isNotEmpty,
        ),
    ];
  }

  // Modo local solo cuando EN1 aún no entregó catálogo de cajeros.
  final locals = await ref.watch(cashierRepositoryProvider).getActiveCashiers();
  return [
    for (final c in locals)
      _LoginCashierOption(
        key: c.localId,
        name: CashierDisplay.displayName(name: c.name),
        local: c,
        hasPin: c.pinHash.isNotEmpty,
      ),
  ];
});

class PinScreen extends ConsumerStatefulWidget {
  /// Cambio de cajero: turno permanece abierto en BD.
  final bool switchCashier;

  const PinScreen({super.key, this.switchCashier = false});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _error;
  bool _loading = false;
  String? _selectedKey;
  int _failCount = 0;
  DateTime? _lockedUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PosLayout.unlockOrientations();
    });
    Future.microtask(() async {
      if (!mounted) return;
      await ensureInstallationReadyForPos(ref, context);
    });
  }

  Future<void> _submit() async {
    if (!await ensureInstallationReadyForPos(ref, context)) return;
    if (_lockedUntil != null && DateTime.now().isBefore(_lockedUntil!)) {
      final sec = _lockedUntil!.difference(DateTime.now()).inSeconds;
      setState(() => _error = 'Demasiados intentos. Espera ${sec}s');
      return;
    }

    final options = ref.read(loginCashiersProvider).valueOrNull ?? const [];
    if (options.isEmpty) {
      setState(() => _error =
          'Sin cajeros. Descarga catálogo EN1 o crea uno en onboarding.');
      return;
    }

    _LoginCashierOption? selected;
    for (final option in options) {
      if (option.key == _selectedKey) {
        selected = option;
        break;
      }
    }
    selected ??= options.length == 1 ? options.first : null;
    if (selected == null) {
      setState(() => _error = 'Selecciona un cajero');
      return;
    }

    if (_pin.length < 4) {
      setState(() => _error = 'PIN incompleto');
      return;
    }

    if (!selected.hasPin) {
      setState(() {
        _error =
            'Este cajero no tiene PIN. Asígnalo en EN1 → Cajeros → Editar.';
        _pin = '';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Cashier? cashier;
      final contactId = selected.contactId;

      if (selected.contactId != null) {
        try {
          final ok = await En1CashierCatalogStore.verifyPin(
            cashierContactId: selected.contactId!,
            pin: _pin,
          );
          if (!ok) {
            _onFail();
            return;
          }
        } on CashierPinNotSetException catch (e) {
          setState(() {
            _error = e.toString();
            _pin = '';
          });
          return;
        } on UnsupportedPinVerifierException catch (e) {
          setState(() {
            _error = '$e · re-sincroniza catálogo EN1';
            _pin = '';
          });
          return;
        }
        final displayName = await CashierDisplay.resolve(
          name: selected.name,
          contactId: selected.contactId,
          code: selected.code,
        );
        cashier = Cashier(
          localId: selected.key,
          serverId: '${selected.contactId}',
          name: displayName,
          pinHash: 'en1_secure',
          role: CashierRole.cashier,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else if (selected.local != null) {
        final ok =
            await PinVerifier.verify(_pin, selected.local!.pinHash);
        if (!ok) {
          _onFail();
          return;
        }
        final local = selected.local!;
        final displayName = CashierDisplay.displayName(name: local.name);
        cashier = displayName == local.name
            ? local
            : local.copyWith(name: displayName);
      }

      if (cashier == null) {
        _onFail();
        return;
      }

      _failCount = 0;
      ref
          .read(posSessionProvider.notifier)
          .login(cashier, cashierContactId: contactId);

      final cashRepo = ref.read(cashRegisterRepositoryProvider);
      final openRegister = await cashRepo.getOpenRegister();
      if (openRegister != null) {
        await cashRepo.assignCurrentCashier(
          cashierId: cashier.localId,
          cashierName: cashier.name,
          cashierContactId: contactId,
        );
        ref
            .read(posSessionProvider.notifier)
            .setCashRegister(openRegister.localId);
      }

      if (mounted) {
        unawaited(En1ClockGuard.checkAndWarn(context));
      }

      if (openRegister != null) {
        if (mounted) context.go('/pos');
      } else {
        if (mounted) context.go('/cash/open');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onFail() {
    _failCount++;
    if (_failCount >= 5) {
      _lockedUntil =
          DateTime.now().add(Duration(seconds: 30 * (_failCount - 4)));
      _failCount = 5;
    }
    setState(() {
      _error = _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!)
          ? 'PIN incorrecto. Bloqueado ${_lockedUntil!.difference(DateTime.now()).inSeconds}s'
          : 'PIN incorrecto';
      _pin = '';
    });
  }

  void _onDigit(String digit) {
    if (_loading) return;
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _selectCashier(String key) {
    setState(() {
      _selectedKey = key;
      _pin = '';
      _error = null;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(businessConfigProvider);
    final cashiersAsync = ref.watch(loginCashiersProvider);

    // Auto-selección: primero con PIN; si no, el único disponible.
    cashiersAsync.whenData((list) {
      if (_selectedKey == null && list.isNotEmpty) {
        final withPin = list.where((e) => e.hasPin).toList();
        final pick = withPin.isNotEmpty
            ? withPin.first
            : (list.length == 1 ? list.first : null);
        if (pick != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedKey == null) {
              setState(() => _selectedKey = pick.key);
            }
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: EposBrand.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final keypadMaxHeight = isLandscape
                ? constraints.maxHeight - 16
                : math.min(240.0, constraints.maxHeight * 0.38);

            final header = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.switchCashier)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade900.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Cambio de cajero · el turno permanece abierto',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                _PinHeader(
                  businessName: config?.businessName ?? 'EPOSOne',
                  cashiersAsync: cashiersAsync,
                  selectedKey: _selectedKey,
                  onSelect: _selectCashier,
                  pinLength: _pin.length,
                  error: _error,
                  loading: _loading,
                  compact: isLandscape,
                ),
              ],
            );

            final keypad = _NumericKeypad(
              maxHeight: keypadMaxHeight,
              onDigit: _onDigit,
              onBackspace: _backspace,
              onSubmit: _submit,
            );

            if (isLandscape) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Center(child: header)),
                    SizedBox(
                      width: math.min(340, constraints.maxWidth * 0.4),
                      child: keypad,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  header,
                  const SizedBox(height: 16),
                  keypad,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PinHeader extends StatelessWidget {
  final String businessName;
  final AsyncValue<List<_LoginCashierOption>> cashiersAsync;
  final String? selectedKey;
  final ValueChanged<String> onSelect;
  final int pinLength;
  final String? error;
  final bool loading;
  final bool compact;

  const _PinHeader({
    required this.businessName,
    required this.cashiersAsync,
    required this.selectedKey,
    required this.onSelect,
    required this.pinLength,
    this.error,
    this.loading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 48.0 : 56.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EposBrandIcon(size: iconSize),
        SizedBox(height: compact ? 8 : 12),
        Text(
          businessName,
          style: TextStyle(
            fontSize: compact ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: EposBrand.navy,
          ),
          textAlign: TextAlign.center,
        ),
        const Text('Selecciona cajero e ingresa PIN',
            style: TextStyle(color: EposBrand.textSecondary)),
        SizedBox(height: compact ? 8 : 16),
        cashiersAsync.when(
          data: (cashiers) {
            if (cashiers.isEmpty) {
              return const Text(
                'Sin cajeros activos.\nDescarga catálogo EN1 o configura onboarding.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
              );
            }
            // Auto-hint: si solo hay uno, el padre puede no haber seleccionado aún.
            return Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: cashiers.map((c) {
                final selected = selectedKey == c.key ||
                    (selectedKey == null && cashiers.length == 1);
                return ChoiceChip(
                  selected: selected,
                  avatar: Icon(
                    Icons.person,
                    size: 16,
                    color: selected ? Colors.white : EposBrand.navy,
                  ),
                  label: Text(
                    [
                      c.name,
                      if (c.code != null && c.code!.isNotEmpty) '(${c.code})',
                      if (!c.hasPin) '· sin PIN',
                    ].join(' '),
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : EposBrand.navy,
                    ),
                  ),
                  selectedColor: EposBrand.orange,
                  onSelected: (_) => onSelect(c.key),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => Text('$e',
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        ),
        SizedBox(height: compact ? 12 : 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: compact ? 12 : 14,
              height: compact ? 12 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < pinLength ? EposBrand.orange : EposBrand.divider,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center),
        ],
        if (loading) ...[
          const SizedBox(height: 12),
          const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ],
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final double maxHeight;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  const _NumericKeypad({
    required this.maxHeight,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '✓', '0', '⌫'];
    const rows = 4;
    const cols = 3;
    const spacing = 6.0;
    final rowHeight = (maxHeight - spacing * (rows - 1)) / rows;
    final fontSize = (rowHeight * 0.42).clamp(16.0, 26.0);

    return SizedBox(
      height: maxHeight,
      child: Column(
        children: List.generate(rows, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row < rows - 1 ? spacing : 0),
            child: SizedBox(
              height: rowHeight,
              child: Row(
                children: List.generate(cols, (col) {
                  final key = keys[row * cols + col];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: col > 0 ? spacing : 0),
                      child: Material(
                        color: EposBrand.surface,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            if (key == '⌫') {
                              onBackspace();
                            } else if (key == '✓') {
                              onSubmit();
                            } else {
                              onDigit(key);
                            }
                          },
                          onLongPress: key == '⌫' ? onBackspace : null,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: EposBrand.divider),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              key,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                color: EposBrand.navy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        }),
      ),
    );
  }
}
