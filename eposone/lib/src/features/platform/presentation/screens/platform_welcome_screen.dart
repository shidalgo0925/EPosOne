import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';

/// Wizard de bienvenida (capa Plataforma).
///
/// Local → onboarding de negocio existente.
/// Plataforma → pantalla Conectar EN1 (Hito 1 provisioning).
class PlatformWelcomeScreen extends ConsumerStatefulWidget {
  const PlatformWelcomeScreen({super.key});

  @override
  ConsumerState<PlatformWelcomeScreen> createState() => _PlatformWelcomeScreenState();
}

class _PlatformWelcomeScreenState extends ConsumerState<PlatformWelcomeScreen> {
  PlatformMode? _selected;
  bool _busy = false;

  Future<void> _continue() async {
    final mode = _selected;
    if (mode == null || mode == PlatformMode.undecided) return;

    setState(() => _busy = true);
    try {
      await DeviceRegistry.getOrCreateUuid();

      if (!mounted) return;

      if (mode == PlatformMode.local) {
        await PlatformPrefs.completeOnboarding(PlatformMode.local);
        if (!mounted) return;
        context.go('/onboarding');
        return;
      }

      // No marca onboarding done hasta provisioning exitoso.
      context.go('/platform/connect');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EposBrand.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Center(child: EposBrandIcon(size: 72)),
                  const SizedBox(height: 16),
                  const Center(child: EposOneLogo(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: EposBrand.navy,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '¿Cómo deseas comenzar?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: EposBrand.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  _ModeCard(
                    selected: _selected == PlatformMode.local,
                    icon: Icons.storefront_outlined,
                    title: 'Crear un negocio',
                    subtitle:
                        'Configura todo en este dispositivo. Ideal para empezar ya a vender.',
                    onTap: _busy ? null : () => setState(() => _selected = PlatformMode.local),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    selected: _selected == PlatformMode.platform,
                    icon: Icons.cloud_outlined,
                    title: 'Conectar EasyNodeOne',
                    subtitle:
                        'Registra este dispositivo en la plataforma y descarga la configuración.',
                    onTap: _busy ? null : () => setState(() => _selected = PlatformMode.platform),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: (_selected == null || _busy) ? null : _continue,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Continuar'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'El punto de venta no cambia. Solo eliges cómo inicia tu negocio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EposBrand.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? EposBrand.orange : EposBrand.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 36, color: selected ? EposBrand.orange : EposBrand.navy),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: EposBrand.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: EposBrand.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? EposBrand.orange : EposBrand.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
