import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/pos/presentation/utils/pos_layout.dart';

final activeCashiersProvider = FutureProvider<List<Cashier>>((ref) async {
  final repo = ref.watch(cashierRepositoryProvider);
  return repo.getActiveCashiers();
});

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PosLayout.unlockOrientations();
    });
  }

  Future<void> _submit() async {
    if (_pin.length < 4) {
      setState(() => _error = 'PIN incompleto');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cashier = await ref.read(cashierRepositoryProvider).verifyPin(_pin);
      if (cashier == null) {
        setState(() {
          _error = 'PIN incorrecto';
          _pin = '';
        });
        return;
      }

      ref.read(posSessionProvider.notifier).login(cashier);

      final openRegister = await ref.read(cashRegisterRepositoryProvider).getOpenRegister();
      if (openRegister != null) {
        ref.read(posSessionProvider.notifier).setCashRegister(openRegister.localId);
        if (mounted) context.go('/pos');
      } else {
        if (mounted) context.go('/cash/open');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length >= 4) _submit();
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(businessConfigProvider);
    final cashiersAsync = ref.watch(activeCashiersProvider);

    return Scaffold(
      backgroundColor: EposBrand.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final keypadMaxHeight = isLandscape
                ? constraints.maxHeight - 16
                : math.min(240.0, constraints.maxHeight * 0.38);

            final header = _PinHeader(
              businessName: config?.businessName ?? 'EPOSOne',
              cashiersAsync: cashiersAsync,
              pinLength: _pin.length,
              error: _error,
              loading: _loading,
              compact: isLandscape,
            );

            final keypad = _NumericKeypad(
              maxHeight: keypadMaxHeight,
              onDigit: _onDigit,
              onBackspace: _backspace,
            );

            if (isLandscape) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
  final AsyncValue<List<Cashier>> cashiersAsync;
  final int pinLength;
  final String? error;
  final bool loading;
  final bool compact;

  const _PinHeader({
    required this.businessName,
    required this.cashiersAsync,
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
        const Text('Ingresa tu PIN', style: TextStyle(color: EposBrand.textSecondary)),
        SizedBox(height: compact ? 8 : 16),
        cashiersAsync.when(
          data: (cashiers) => Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: cashiers
                .map((c) => Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.person, size: 16),
                      label: Text(c.name, style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
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
          Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        if (loading) ...[
          const SizedBox(height: 12),
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ],
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final double maxHeight;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _NumericKeypad({
    required this.maxHeight,
    required this.onDigit,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
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
                  if (key.isEmpty) {
                    return Expanded(child: SizedBox(height: rowHeight));
                  }
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
