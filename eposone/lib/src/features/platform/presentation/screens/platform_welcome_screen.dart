import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';

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

  /// Embudo comercial (/start) — host EPosOne, no la API Device.
  /// Oficial: https://eposone.easytech.services/start
  static const _commercialStartUrl = 'https://eposone.easytech.services/start';

  Future<void> _openCreateBusiness() async {
    final uri = Uri.parse(_commercialStartUrl);

    var launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      launched = false;
    }

    if (!mounted) return;

    if (launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cuando termines en EN1, vuelve y usa «Activar con código» o «Ya tengo una cuenta».',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No se pudo abrir EN1'),
        content: Text(
          'La tablet no alcanzó el sitio (sin internet o DNS).\n\n'
          'Abre en un navegador con red:\n$uri\n\n'
          'Luego vuelve a la APK con el código o inicia sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: uri.toString()));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copiada')),
                );
              }
            },
            child: const Text('Copiar URL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selected = _WelcomeChoice.activateCode);
            },
            child: const Text('Activar con código'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
          await _openCreateBusiness();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    children: [
                      const SizedBox(height: 8),
                      const Center(child: EposBrandIcon(size: 64)),
                      const SizedBox(height: 12),
                      const Center(child: EposOneLogo(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        'Bienvenido a EPOSOne',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: EposBrand.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Instala esta caja en pocos pasos. La modalidad la define EN1.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: EposBrand.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ChoiceCard(
                        selected: _selected == _WelcomeChoice.createBusiness,
                        icon: Icons.storefront_outlined,
                        title: 'Crear un negocio',
                        subtitle:
                            'Abre eposone.easytech.services/start para cuenta, plan e instalación.',
                        onTap: _busy
                            ? null
                            : () => setState(
                                  () =>
                                      _selected = _WelcomeChoice.createBusiness,
                                ),
                      ),
                      const SizedBox(height: 10),
                      _ChoiceCard(
                        selected: _selected == _WelcomeChoice.haveAccount,
                        icon: Icons.login,
                        title: 'Ya tengo una cuenta',
                        subtitle:
                            'Inicia sesión EN1, elige caja y registra este dispositivo.',
                        onTap: _busy
                            ? null
                            : () => setState(
                                  () => _selected = _WelcomeChoice.haveAccount,
                                ),
                      ),
                      const SizedBox(height: 10),
                      _ChoiceCard(
                        selected: _selected == _WelcomeChoice.activateCode,
                        icon: Icons.vpn_key_outlined,
                        title: 'Activar con código',
                        subtitle:
                            'Pega o escanea el código de aprovisionamiento.',
                        onTap: _busy
                            ? null
                            : () => setState(
                                  () =>
                                      _selected = _WelcomeChoice.activateCode,
                                ),
                      ),
                      const SizedBox(height: 10),
                      _ChoiceCard(
                        selected: _selected == _WelcomeChoice.restore,
                        icon: Icons.phonelink_setup,
                        title: 'Restaurar instalación',
                        subtitle:
                            'Recupera el vínculo de una caja ya autorizada en EN1.',
                        onTap: _busy
                            ? null
                            : () => setState(
                                  () => _selected = _WelcomeChoice.restore,
                                ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: FilledButton(
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
                ),
              ],
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
              Icon(
                icon,
                size: 32,
                color: selected ? EposBrand.orange : EposBrand.navy,
              ),
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
