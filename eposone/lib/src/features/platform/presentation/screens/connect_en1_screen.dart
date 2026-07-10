import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_repository.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/platform/domain/connection_status.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/en1_sync_mode.dart';

/// Pantalla Hito 1: conectar tablet a EasyNodeOne (provisioning).
///
/// No toca el POS Core. Sync de catálogo permanece stub.
class ConnectEn1Screen extends ConsumerStatefulWidget {
  const ConnectEn1Screen({super.key});

  @override
  ConsumerState<ConnectEn1Screen> createState() => _ConnectEn1ScreenState();
}

class _ConnectEn1ScreenState extends ConsumerState<ConnectEn1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _repo = En1ProvisioningRepository();

  ConnectionStatus _status = ConnectionStatus.notConfigured;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await ProvisioningStore.getApiUrlDraft();
    final status = await _repo.getStatus();
    final err = await _repo.getLastError();
    if (!mounted) return;
    setState(() {
      if (draft != null && draft.isNotEmpty) _urlCtrl.text = draft;
      _status = status;
      _error = err;
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _status = ConnectionStatus.registering;
      _error = null;
    });

    try {
      final config = await _repo.provision(
        apiBaseUrl: _urlCtrl.text.trim(),
        provisioningCode: _codeCtrl.text.trim(),
      );

      // Aplica identidad mínima en BusinessConfig (sin tocar pantallas POS).
      final isar = await ref.read(databaseProvider.future);
      final configRepo = BusinessConfigRepository(isar);
      final current = await configRepo.getConfig();
      await configRepo.saveConfig(
        current.copyWith(
          businessName: config.businessName ?? config.empresaName ?? current.businessName,
          en1SyncEnabled: true,
          en1SyncMode: En1SyncMode.live,
          en1ApiUrl: config.apiBaseUrl,
          en1ApiToken: config.accessToken,
          en1BranchId: config.branchRef,
        ).markAsModified(),
      );

      if (!mounted) return;
      setState(() {
        _status = ConnectionStatus.connected;
        _busy = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Conectado · POS ${config.posName ?? config.posId} · '
            'Caja ${config.cajaName ?? config.cajaId}',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      // Siguiente: cajero local si hace falta; si ya hay setup → PIN vía splash/startup.
      context.go('/onboarding');
    } catch (e) {
      final message = e is En1ProvisioningException
          ? e.userMessage
          : 'No se pudo conectar con EasyNodeOne. Intenta de nuevo.';
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = ConnectionStatus.error;
        _error = message;
      });
    }
  }

  Color get _statusColor => switch (_status) {
        ConnectionStatus.notConfigured => EposBrand.textSecondary,
        ConnectionStatus.registering => EposBrand.orange,
        ConnectionStatus.connected => const Color(0xFF2E7D32),
        ConnectionStatus.error => const Color(0xFFC62828),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EposBrand.background,
      appBar: AppBar(
        title: const Text('Conectar EasyNodeOne'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : () => context.go('/platform/welcome'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Registra este dispositivo en la plataforma. '
                    'Solo necesitas la URL de EN1 y el código de provisioning '
                    'asociado a una Caja (BackOffice).',
                    style: TextStyle(color: EposBrand.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  _StatusBanner(status: _status, color: _statusColor, error: _error),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _urlCtrl,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'URL API EasyNodeOne',
                      hintText: 'https://en1.tudominio.com',
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Requerido';
                      final uri = Uri.tryParse(t);
                      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                        return 'URL inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeCtrl,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Código de provisioning',
                      hintText: 'Asociado a una Caja en EasyNodeOne',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _register,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Registrar dispositivo'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : () => context.go('/platform/welcome'),
                    child: const Text('Volver'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Contrato EN1-02 · POST /api/v1/devices/register\n'
                    'Header X-EN1-Provisioning-Code · la jerarquía viene en la respuesta.\n'
                    'La sincronización de productos y ventas se activará en el Hito 2.',
                    style: TextStyle(fontSize: 11, color: EposBrand.textSecondary),
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

class _StatusBanner extends StatelessWidget {
  final ConnectionStatus status;
  final Color color;
  final String? error;

  const _StatusBanner({
    required this.status,
    required this.color,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 8),
              Text(
                'Estado: ${status.label}',
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          if (error != null && error!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(fontSize: 13, color: EposBrand.textPrimary)),
          ],
        ],
      ),
    );
  }
}
