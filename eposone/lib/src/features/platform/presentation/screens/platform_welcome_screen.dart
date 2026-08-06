import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';

/// Gate 2 — Bienvenida única (sin Modo Local / Cloud / Online / Offline).
enum _WelcomeChoice {
  createBusiness,
  haveAccount,
  activateCode,
  restore,
}

class PlatformWelcomeScreen extends ConsumerStatefulWidget {
  const PlatformWelcomeScreen({super.key});

  @override
  ConsumerState<PlatformWelcomeScreen> createState() =>
      _PlatformWelcomeScreenState();
}

class _PlatformWelcomeScreenState extends ConsumerState<PlatformWelcomeScreen> {
  _WelcomeChoice? _selected;
  bool _busy = false;

  static const _defaultEn1 = 'https://appdev.easynodeone.com';

  Future<String> _resolveBaseUrl() async {
    final draft = await ProvisioningStore.getApiUrlDraft();
    final cfg = await ProvisioningStore.loadConfig();
    if (cfg != null && cfg.apiBaseUrl.isNotEmpty) return cfg.apiBaseUrl;
    if (draft != null && draft.isNotEmpty) return draft;
    return _defaultEn1;
  }

  Future<void> _continue() async {
    final choice = _selected;
    if (choice == null) return;
    setState(() => _busy = true);
    try {
      await DeviceRegistry.getOrCreateUuid();
      if (!mounted) return;

      switch (choice) {
        case _WelcomeChoice.createBusiness:
          final base = await _resolveBaseUrl();
          final uri = Uri.parse('$base/start');
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Abre en el navegador: $uri')),
            );
          }
          // Tras crear negocio en web, vuelve y usa código / cuenta.
          break;
        case _WelcomeChoice.haveAccount:
          context.go('/platform/onboarding/login');
        case _WelcomeChoice.activateCode:
          context.go('/platform/connect');
        case _WelcomeChoice.restore:
          context.go('/platform/onboarding/login?restore=1');
      }
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
                    'Bienvenido a EPOSOne',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: EposBrand.navy,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Instala esta caja en pocos pasos. La modalidad la define EN1.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: EposBrand.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  _ChoiceCard(
                    selected: _selected == _WelcomeChoice.createBusiness,
                    icon: Icons.storefront_outlined,
                    title: 'Crear un negocio',
                    subtitle: 'Abre EN1 (/start) para cuenta, plan y panel de instalación.',
                    onTap: _busy
                        ? null
                        : () => setState(
                              () => _selected = _WelcomeChoice.createBusiness,
                            ),
                  ),
                  const SizedBox(height: 12),
                  _ChoiceCard(
                    selected: _selected == _WelcomeChoice.haveAccount,
                    icon: Icons.login,
                    title: 'Ya tengo una cuenta',
                    subtitle: 'Inicia sesión EN1, elige caja y registra este dispositivo.',
                    onTap: _busy
                        ? null
                        : () => setState(
                              () => _selected = _WelcomeChoice.haveAccount,
                            ),
                  ),
                  const SizedBox(height: 12),
                  _ChoiceCard(
                    selected: _selected == _WelcomeChoice.activateCode,
                    icon: Icons.vpn_key_outlined,
                    title: 'Activar con código',
                    subtitle: 'Pega o escanea el código de aprovisionamiento.',
                    onTap: _busy
                        ? null
                        : () => setState(
                              () => _selected = _WelcomeChoice.activateCode,
                            ),
                  ),
                  const SizedBox(height: 12),
                  _ChoiceCard(
                    selected: _selected == _WelcomeChoice.restore,
                    icon: Icons.phonelink_setup,
                    title: 'Restaurar instalación',
                    subtitle: 'Recupera el vínculo de una caja ya autorizada en EN1.',
                    onTap: _busy
                        ? null
                        : () => setState(() => _selected = _WelcomeChoice.restore),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: (_selected == null || _busy) ? null : _continue,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _selected == _WelcomeChoice.createBusiness
                                ? 'Abrir EN1'
                                : 'Continuar',
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EposBrand.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? EposBrand.orange : EposBrand.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: selected ? EposBrand.orange : EposBrand.navy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: EposBrand.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: EposBrand.textSecondary,
                      ),
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
