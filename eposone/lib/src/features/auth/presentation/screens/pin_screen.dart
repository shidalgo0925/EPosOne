import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/cash_register/data/repositories/cash_register_repository.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const EposBrandIcon(size: 64),
              const SizedBox(height: 16),
              Text(
                config?.businessName ?? 'EPOSOne',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: EposBrand.navy),
              ),
              const Text('Ingresa tu PIN', style: TextStyle(color: EposBrand.textSecondary)),
              const SizedBox(height: 24),
              cashiersAsync.when(
                data: (cashiers) => Wrap(
                  spacing: 8,
                  children: cashiers
                      .map((c) => Chip(avatar: const Icon(Icons.person, size: 18), label: Text(c.name)))
                      .toList(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length ? EposBrand.orange : EposBrand.divider,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const Spacer(),
              if (_loading) const CircularProgressIndicator(),
              _NumericKeypad(onDigit: _onDigit, onBackspace: _backspace, onEnter: _submit),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;

  const _NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();
        return Material(
          color: EposBrand.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EposBrand.divider),
              ),
              child: Center(
                child: Text(
                  key,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: EposBrand.navy),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
