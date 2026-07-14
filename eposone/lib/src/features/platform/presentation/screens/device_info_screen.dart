import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_repository.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_repository.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/domain/connection_status.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';
import 'package:eposone/src/features/platform/domain/provisioning_config.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';

const _appVersionLabel = '1.0.0+1';

/// Pantalla "Este dispositivo" — UUID, modo, estado EN1, bootstrap Hito 2.
class DeviceInfoScreen extends ConsumerStatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  ConsumerState<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends ConsumerState<DeviceInfoScreen> {
  DeviceSnapshot? _device;
  PlatformMode _mode = PlatformMode.undecided;
  ConnectionStatus _status = ConnectionStatus.notConfigured;
  ProvisioningConfig? _config;
  String? _error;
  bool _loading = true;
  bool _refreshing = false;
  bool _bootstrapping = false;
  bool _bootstrapDone = false;
  DateTime? _bootstrapAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = En1ProvisioningRepository();
    final device = await DeviceRegistry.snapshot(appVersion: _appVersionLabel);
    final mode = await PlatformPrefs.getMode();
    final status = await repo.getStatus();
    final config = await repo.getConfig();
    final error = await repo.getLastError();
    final isar = await ref.read(databaseProvider.future);
    final bootRepo = En1BootstrapRepository(isar: isar);
    final done = await bootRepo.isBootstrapDone();
    final at = await bootRepo.lastBootstrapAt();
    if (!mounted) return;
    setState(() {
      _device = device;
      _mode = mode;
      _status = status;
      _config = config;
      _error = error;
      _bootstrapDone = done;
      _bootstrapAt = at;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await En1ProvisioningRepository().refreshConfig();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración actualizada desde EN1')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _runBootstrap() async {
    setState(() => _bootstrapping = true);
    try {
      final isar = await ref.read(databaseProvider.future);
      final result = await En1BootstrapRepository(isar: isar).runBootstrap();
      ref.invalidate(productsListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green.shade700,
        ),
      );
      await _load();
    } catch (e) {
      final msg = e is En1ProvisioningException
          ? e.userMessage
          : e is En1BootstrapException
              ? e.message
              : '$e';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _bootstrapping = false);
    }
  }

  String get _modeLabel => switch (_mode) {
        PlatformMode.local => 'Local',
        PlatformMode.platform => 'Plataforma (EN1)',
        PlatformMode.undecided => 'Sin definir',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Este dispositivo'),
        actions: [
          if (_config != null)
            IconButton(
              tooltip: 'Refrescar config EN1',
              onPressed: _refreshing || _bootstrapping ? null : _refresh,
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_download_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _tile('Estado EN1', _status.label),
                if (_error != null && _status == ConnectionStatus.error)
                  _tile('Último error', _error!),
                _tile('UUID', _device?.uuid ?? '—', copyable: true),
                _tile('Modelo / host', _device?.model ?? '—'),
                _tile('Sistema', _device?.os ?? '—'),
                _tile('Versión app', _appVersionLabel),
                _tile('Modo', _modeLabel),
                if (_config != null) ...[
                  const SizedBox(height: 8),
                  const Text('Jerarquía provisionada (EN1-02)',
                      style: TextStyle(fontWeight: FontWeight.w700, color: EposBrand.navy)),
                  const SizedBox(height: 8),
                  _tile(
                    'Empresa',
                    '${_config!.organizationName ?? _config!.businessName ?? '—'} '
                    '(${_config!.organizationId})',
                  ),
                  _tile(
                    'Sucursal',
                    '${_config!.branchName ?? '—'} (${_config!.branchRef})',
                  ),
                  _tile('POS', '${_config!.posName ?? '—'} (${_config!.posRef})'),
                  _tile(
                    'Caja',
                    '${_config!.registerName ?? '—'} (${_config!.registerRef})',
                  ),
                  _tile('Dispositivo', _config!.deviceName ?? '—'),
                  _tile('UUID dispositivo', _config!.deviceUuid, copyable: true),
                  if (_config!.deviceStatus != null)
                    _tile('Estado dispositivo', _config!.deviceStatus!),
                  if (_config!.configVersion != null)
                    _tile('config_version', '${_config!.configVersion}'),
                  _tile('API', _config!.apiBaseUrl),
                  _tile('Provisionado', _config!.provisionedAt.toLocal().toString()),
                  const SizedBox(height: 16),
                  const Text('Hito 2 — Device Bootstrap',
                      style: TextStyle(fontWeight: FontWeight.w700, color: EposBrand.navy)),
                  const SizedBox(height: 8),
                  _tile(
                    'Catálogo EN1',
                    _bootstrapDone
                        ? 'Descargado${_bootstrapAt != null ? ' · ${_bootstrapAt!.toLocal()}' : ''}'
                        : 'Pendiente (aún puede verse Istmo local)',
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _bootstrapping ? null : _runBootstrap,
                    icon: _bootstrapping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_sync),
                    label: Text(_bootstrapDone
                        ? 'Volver a descargar catálogo EN1'
                        : 'Descargar catálogo EN1'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Descarga productos, imágenes y saldos desde EN1 (contrato Hito 2). '
                    'No descuenta stock por ventas todavía.',
                    style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'El dispositivo se identifica para auditoría y sincronización. '
                  'La licencia futura se asocia al Punto de Venta, no a este hardware.',
                  style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                ),
              ],
            ),
    );
  }

  Widget _tile(String label, String value, {bool copyable = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 13, color: EposBrand.textSecondary)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        trailing: copyable
            ? IconButton(
                tooltip: 'Copiar',
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copiado')),
                  );
                },
              )
            : null,
      ),
    );
  }
}
