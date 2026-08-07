import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/activation_claims_store.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/en1_activation_api.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/data/standalone_assistant_draft_store.dart';
import 'package:eposone/src/features/platform/domain/en1_hosts.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';

/// GO LOCAL — Activar EPOSOne (ADR-035 v1.4): correo + código 6 dígitos.
///
/// Sin URL EN1, sin Register/Bootstrap, sin “código de caja”.
/// Connected: enlace secundario → `/platform/connect`.
class StandaloneActivationScreen extends ConsumerStatefulWidget {
  const StandaloneActivationScreen({
    super.key,
    this.initialRaw,
    this.autoRedeem = true,
  });

  /// Legado App Link `?token=` — no se usa en el camino canónico v1.4.
  final String? initialRaw;
  final bool autoRedeem;

  @override
  ConsumerState<StandaloneActivationScreen> createState() =>
      _StandaloneActivationScreenState();
}

class _StandaloneActivationScreenState
    extends ConsumerState<StandaloneActivationScreen> {
  final _api = En1ActivationApi();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_boot);
  }

  Future<void> _boot() async {
    if (await ActivationClaimsStore.hasValidStandalone()) {
      final ready = await StandaloneAssistantDraftStore.isReadyToSell();
      if (!mounted) return;
      context.go(
        ready ? '/pin' : '/platform/standalone/assistant',
      );
      return;
    }

    final pending = await ActivationClaimsStore.loadPendingEmailCode();
    if (pending != null && mounted) {
      _emailCtrl.text = pending.email;
      _codeCtrl.text = pending.code;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openRegister() async {
    final uri = Uri.parse(En1Hosts.commercialStart);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abre en el navegador: ${uri.toString()}')),
    );
  }

  Future<void> _activate() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim().replaceAll(RegExp(r'\s+'), '');

    setState(() {
      _busy = true;
      _error = null;
    });

    await ActivationClaimsStore.savePendingEmailCode(
      email: email,
      activationCode: code,
    );

    try {
      final uuid = await DeviceRegistry.getOrCreateUuid();
      final claims = await _api.redeemWithEmailCode(
        email: email,
        activationCode: code,
        deviceUuid: uuid,
        apiBaseUrl: En1Hosts.apiBase,
      );

      if (!claims.isStandalone) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = claims.isConnected
              ? 'Esta activación es para EPOSOne Connected. '
                  'Use «Instalación Connected» con el código de caja.'
              : 'No pudimos usar esta activación en este dispositivo.';
        });
        return;
      }

      await ActivationClaimsStore.save(claims);
      await PlatformPrefs.completeOnboarding(PlatformMode.local);
      if (!mounted) return;
      context.go('/platform/standalone/assistant');
    } on En1ActivationException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'No pudimos verificar tu activación. Revisa tu conexión e intenta nuevamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EposBrand.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            children: [
              const SizedBox(height: 12),
              const Center(child: EposBrandIcon(size: 72)),
              const SizedBox(height: 16),
              Text(
                'Activar EPOSOne',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: EposBrand.navy,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Usa el correo con el que te registraste y el código de '
                'activación de 6 dígitos que recibiste por email.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EposBrand.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 28),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade800, height: 1.35),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Ingresa tu correo';
                  if (!t.contains('@') || !t.contains('.')) {
                    return 'Correo no válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Código de activación',
                  hintText: '6 dígitos',
                  prefixIcon: Icon(Icons.pin_outlined),
                  counterText: '',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.length != 6) {
                    return 'El código tiene 6 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _activate,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Activar'),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: _busy ? null : _openRegister,
                child: const Text(
                  '¿Aún no tienes cuenta? Regístrate',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => context.go('/platform/connect'),
                child: const Text(
                  'Instalación Connected (código de caja)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
