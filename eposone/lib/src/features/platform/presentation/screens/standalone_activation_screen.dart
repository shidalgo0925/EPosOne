import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/activation_claims_store.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/en1_activation_api.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/en1_hosts.dart';
import 'package:eposone/src/features/platform/domain/onboarding_session.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';
import 'package:eposone/src/features/pos/presentation/screens/barcode_scanner_screen.dart';

/// Activación ADR-035 → rama Standalone (ADR-033) o puente legacy Connected.
class StandaloneActivationScreen extends ConsumerStatefulWidget {
  const StandaloneActivationScreen({super.key, this.initialRaw});

  final String? initialRaw;

  @override
  ConsumerState<StandaloneActivationScreen> createState() =>
      _StandaloneActivationScreenState();
}

class _StandaloneActivationScreenState
    extends ConsumerState<StandaloneActivationScreen> {
  final _tokenCtrl = TextEditingController();
  final _urlCtrl = TextEditingController(text: En1Hosts.apiBase);
  final _api = En1ActivationApi();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRaw?.trim();
    if (initial != null && initial.isNotEmpty) {
      _tokenCtrl.text = initial;
      Future.microtask(() => _submit());
    } else {
      _loadUrlDraft();
    }
  }

  Future<void> _loadUrlDraft() async {
    final draft = await ProvisioningStore.getApiUrlDraft();
    if (!mounted) return;
    if (draft != null && draft.isNotEmpty) {
      _urlCtrl.text = draft;
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim();
    if (raw == null || raw.isEmpty) return;
    setState(() => _tokenCtrl.text = raw);
  }

  Future<void> _scanWithDedicated() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (!mounted) return;
    if (result != null && result.trim().isNotEmpty) {
      setState(() => _tokenCtrl.text = result.trim());
    }
  }

  Future<void> _submit() async {
    final raw = _tokenCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Ingrese o escanee el código de activación.');
      return;
    }

    // Puente legacy: código de provisioning (no transporte ADR-035).
    final activationTok = extractActivationToken(raw);
    if (activationTok == null && !looksLikeActivationTransport(raw)) {
      final code = extractProvisioningCodeFromScan(raw) ?? raw;
      if (!mounted) return;
      context.go('/platform/connect?code=${Uri.encodeComponent(code)}');
      return;
    }

    final token = activationTok ?? raw.trim();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ProvisioningStore.saveApiUrlDraft(_urlCtrl.text.trim());
      final uuid = await DeviceRegistry.getOrCreateUuid();
      final claims = await _api.redeem(
        token: token,
        deviceUuid: uuid,
        apiBaseUrl: _urlCtrl.text.trim(),
      );
      await ActivationClaimsStore.save(claims);

      if (!mounted) return;

      if (claims.isStandalone) {
        await PlatformPrefs.completeOnboarding(PlatformMode.local);
        if (!mounted) return;
        context.go('/platform/standalone/assistant');
        return;
      }

      if (claims.isConnected) {
        setState(() {
          _busy = false;
          _error =
              'Esta licencia es Connected. Cuando la implementación esté '
              'lista para aprovisionar, use el código de caja del Portal '
              '(flujo ADR-034).';
        });
        return;
      }

      setState(() {
        _busy = false;
        _error = 'Modalidad desconocida: ${claims.modality}';
      });
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
        _error = 'No se pudo activar. Intente de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EposBrand.background,
      appBar: AppBar(
        title: const Text('Activar EPOSOne'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : () => context.go('/platform/welcome'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Pegue o escanee el código / QR de activación. '
              'La modalidad la determina EN1 (no se pregunta aquí).',
              style: TextStyle(color: EposBrand.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade800, height: 1.35),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _urlCtrl,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'URL EN1',
                helperText: En1Hosts.apiBase,
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenCtrl,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'Código o enlace de activación',
                hintText: 'Pegar token o URL /activate?token=',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Pegar',
                      onPressed: _busy ? null : _paste,
                      icon: const Icon(Icons.content_paste),
                    ),
                    IconButton(
                      tooltip: 'Escanear QR',
                      onPressed: _busy ? null : _scanWithDedicated,
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Activar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => context.go('/platform/connect'),
              child: const Text('Tengo un código de caja (Connected)'),
            ),
          ],
        ),
      ),
    );
  }
}
