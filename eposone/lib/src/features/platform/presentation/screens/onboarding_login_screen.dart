import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/en1_onboarding_api.dart';
import 'package:eposone/src/features/platform/data/onboarding_user_session_store.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/en1_hosts.dart';

/// Gate 2 — Login onboarding (User Bearer). Caminos B y D.
class OnboardingLoginScreen extends ConsumerStatefulWidget {
  const OnboardingLoginScreen({super.key, this.restore = false});

  final bool restore;

  @override
  ConsumerState<OnboardingLoginScreen> createState() =>
      _OnboardingLoginScreenState();
}

class _OnboardingLoginScreenState extends ConsumerState<OnboardingLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _api = En1OnboardingApi();
  bool _busy = false;
  String? _error;
  bool _obscure = true;

  static const _defaultEn1 = En1Hosts.apiBase;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final draft = await ProvisioningStore.getApiUrlDraft();
    final savedUrl = await OnboardingUserSessionStore.loadApiUrl();
    final email = await OnboardingUserSessionStore.loadEmail();
    final cfg = await ProvisioningStore.loadConfig();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = (cfg?.apiBaseUrl.isNotEmpty == true)
          ? cfg!.apiBaseUrl
          : (savedUrl?.isNotEmpty == true)
              ? savedUrl!
              : (draft?.isNotEmpty == true)
                  ? draft!
                  : _defaultEn1;
      if (email != null) _emailCtrl.text = email;
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _api.login(
        apiBaseUrl: _urlCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await OnboardingUserSessionStore.save(
        apiBaseUrl: _urlCtrl.text.trim(),
        accessToken: result.accessToken,
        email: result.session.email,
      );
      await ProvisioningStore.saveApiUrlDraft(_urlCtrl.text.trim());
      if (!mounted) return;
      final q = widget.restore ? '?restore=1' : '';
      context.go('/platform/onboarding/select$q');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is En1OnboardingException
            ? e.userMessage
            : 'No se pudo iniciar sesión.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.restore ? 'Restaurar instalación' : 'Ya tengo una cuenta';
    return Scaffold(
      backgroundColor: EposBrand.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : () => context.go('/platform/welcome'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Inicia sesión con tu cuenta EN1 (administrador). '
                    'Este token solo sirve para el asistente de instalación.',
                    style: TextStyle(color: EposBrand.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _urlCtrl,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'URL EN1',
                      hintText: En1Hosts.apiBase,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    enabled: !_busy,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFC62828)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Continuar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
