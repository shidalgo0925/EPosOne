import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/activation_claims_store.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/en1_activation_api.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/domain/en1_hosts.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';
import 'package:eposone/src/features/pos/presentation/screens/barcode_scanner_screen.dart';

/// Primera apertura Standalone — ACTIVAR EPOSONE (sin URL/Register/Bootstrap).
///
/// Entradas: App Link (auto) · escanear QR · continuar pendiente · manual (fallback).
/// Connected: ruta explícita aparte (`/platform/connect`).
class StandaloneActivationScreen extends ConsumerStatefulWidget {
  const StandaloneActivationScreen({
    super.key,
    this.initialRaw,
    this.autoRedeem = true,
  });

  /// Transporte crudo (URL App Link / QR). No mostrar al usuario.
  final String? initialRaw;

  /// Si hay token en [initialRaw] o pendiente, intentar redeem sin UI intermedia.
  final bool autoRedeem;

  @override
  ConsumerState<StandaloneActivationScreen> createState() =>
      _StandaloneActivationScreenState();
}

class _StandaloneActivationScreenState
    extends ConsumerState<StandaloneActivationScreen> {
  final _api = En1ActivationApi();
  final _manualCtrl = TextEditingController();

  bool _busy = false;
  bool _showManual = false;
  String? _error;
  String? _status; // mensaje suave durante redeem silencioso

  @override
  void initState() {
    super.initState();
    Future.microtask(_boot);
  }

  Future<void> _boot() async {
    // Ya activado Standalone → asistente.
    if (await ActivationClaimsStore.hasValidStandalone()) {
      if (!mounted) return;
      context.go('/platform/standalone/assistant');
      return;
    }

    final fromLink = widget.initialRaw?.trim();
    final pending = await ActivationClaimsStore.loadPendingToken();

    // Router pasa ?token= ya extraído, o App Link completo.
    String? token;
    if (fromLink != null && fromLink.isNotEmpty) {
      token = extractActivationToken(fromLink);
      // Query param del App Link (sin esquema): solo si autoRedeem desde deep link.
      if (token == null &&
          widget.autoRedeem &&
          !fromLink.contains('://') &&
          !fromLink.contains(' ') &&
          fromLink.length > 8) {
        token = fromLink;
      }
    }
    token ??= pending;

    if (token != null && token.isNotEmpty && widget.autoRedeem) {
      await _redeemSilent(token);
    }
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _redeemSilent(String token) async {
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Activando EPOSOne…';
    });
    await ActivationClaimsStore.savePendingToken(token);
    try {
      final uuid = await DeviceRegistry.getOrCreateUuid();
      final claims = await _api.redeem(
        token: token,
        deviceUuid: uuid,
        apiBaseUrl: En1Hosts.apiBase,
      );

      if (!claims.isStandalone) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _status = null;
          _error = claims.isConnected
              ? 'Esta activación es para EPOSOne Connected. '
                  'Use la ruta de instalación Connected (código de caja), '
                  'no este asistente Standalone.'
              : 'No pudimos usar esta activación en este dispositivo.';
        });
        return;
      }

      await ActivationClaimsStore.save(claims);
      await PlatformPrefs.completeOnboarding(PlatformMode.local);
      if (!mounted) return;
      // Transición casi invisible → asistente.
      context.go('/platform/standalone/assistant');
    } on En1ActivationException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = null;
        _error = e.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = null;
        _error =
            'No pudimos verificar tu activación. Revisa tu conexión e intenta nuevamente.';
      });
    }
  }

  Future<void> _scan() async {
    setState(() => _error = null);
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted) return;
    if (result == null || result.trim().isEmpty) return;

    final token = extractActivationToken(result.trim());
    if (token == null) {
      setState(() {
        _error =
            'Ese QR no es una activación EPOSOne. Escanee el QR de activación '
            'que recibió al registrarse (no el código de caja Connected).';
      });
      return;
    }
    await _redeemSilent(token);
  }

  Future<void> _continuePending() async {
    final pending = await ActivationClaimsStore.loadPendingToken();
    if (pending == null || pending.isEmpty) {
      setState(() => _error = 'No hay una activación pendiente en este dispositivo.');
      return;
    }
    await _redeemSilent(pending);
  }

  Future<void> _submitManual() async {
    final raw = _manualCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Ingrese el enlace o código de activación.');
      return;
    }
    final token = extractActivationToken(raw);
    if (token == null) {
      // Manual: permitir pegar solo el token si el usuario lo recibió por correo
      // (fallback). No mezclar con códigos de caja: copy explícito.
      if (raw.contains('://') || raw.toLowerCase().contains('caja')) {
        setState(() {
          _error =
              'Use el enlace de activación Standalone (…/activate?token=…). '
              'Los códigos de caja Connected van por otra opción.';
        });
        return;
      }
      await _redeemSilent(raw);
      return;
    }
    await _redeemSilent(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EposBrand.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                'Instale y active su negocio. No necesita configurar cajas en la nube.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EposBrand.textSecondary, height: 1.35),
              ),
              const Spacer(),
              if (_status != null) ...[
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: EposBrand.textPrimary),
                ),
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade800, height: 1.35),
                ),
                const SizedBox(height: 16),
              ],
              if (!_busy) ...[
                FilledButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear QR de activación'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _continuePending,
                  child: const Text('Continuar activación pendiente'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _showManual = !_showManual;
                    _error = null;
                  }),
                  child: Text(
                    _showManual
                        ? 'Ocultar código manual'
                        : 'Problemas para activar',
                  ),
                ),
                if (_showManual) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _manualCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Enlace de activación',
                      hintText: 'Pegue el enlace que recibió por correo',
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _submitManual,
                    child: const Text('Activar con enlace'),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/platform/connect'),
                  child: const Text(
                    'Instalación Connected (código de caja)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: En1Hosts.commercialStart),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Si aún no tiene cuenta, regístrese en eposone.easytech.services/start',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '¿Aún no se registró?',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
