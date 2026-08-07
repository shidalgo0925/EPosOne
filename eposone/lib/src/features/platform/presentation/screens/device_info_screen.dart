import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/time/en1_clock_guard.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/core/ui/user_facing_error.dart';
import 'package:eposone/src/features/auth/presentation/screens/pin_screen.dart';
import 'package:eposone/src/features/auth/presentation/utils/cashier_session_guard.dart';
import 'package:eposone/src/features/licensing/domain/license_enums.dart';
import 'package:eposone/src/features/licensing/domain/license_service.dart';
import 'package:eposone/src/features/platform/data/device_registry.dart';
import 'package:eposone/src/features/platform/data/en1_bootstrap_repository.dart';
import 'package:eposone/src/features/platform/data/en1_cashier_catalog_store.dart';
import 'package:eposone/src/features/platform/data/en1_device_auth_recovery.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_repository.dart';
import 'package:eposone/src/features/platform/data/platform_prefs.dart';
import 'package:eposone/src/features/platform/domain/connection_status.dart';
import 'package:eposone/src/features/platform/domain/platform_mode.dart';
import 'package:eposone/src/features/platform/domain/provisioning_config.dart';
import 'package:eposone/src/features/pos/presentation/providers/pos_page_provider.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_operation.dart';
import 'package:eposone/src/features/sync/presentation/providers/en1_connection_status.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';

/// Pantalla "Este dispositivo" — UUID, modo, estado EN1, bootstrap / Hito 2.6.
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
  bool _repairingPages = false;
  bool _bootstrapDone = false;
  DateTime? _bootstrapAt;
  String? _progressLabel;
  double? _progressFraction;

  bool _checkingClock = false;
  List<Map<String, dynamic>> _clockAudit = const [];

  int? _cashiersVersion;
  int _cashiersActive = 0;
  int _cashiersTotal = 0;
  int _pendingOps = 0;
  int _failedOps = 0;
  String _queueBreakdown = '—';
  String? _bootstrapError;
  String? _syncError;
  DateTime? _lastSyncAt;
  En1LinkState _link = En1LinkState.unknown;
  String _licenseSummary = 'Sin snapshot';
  String _appVersionLabel = '…';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pkg = await PackageInfo.fromPlatform();
    final appVersion = '${pkg.version}+${pkg.buildNumber}';
    final repo = En1ProvisioningRepository();
    final device = await DeviceRegistry.snapshot(appVersion: appVersion);
    final mode = await PlatformPrefs.getMode();
    final status = await repo.getStatus();
    final config = await repo.getConfig();
    final error = await repo.getLastError();
    final isar = await ref.read(databaseProvider.future);
    final bootRepo = En1BootstrapRepository(isar: isar);
    final done = await bootRepo.isBootstrapDone();
    final at = await bootRepo.lastBootstrapAt();
    final bootstrapError = await bootRepo.lastBootstrapError();
    final audit = await En1DateTimeService.loadAuditLog(limit: 12);
    final cashiersVersion = await En1CashierCatalogStore.getCashiersVersion();
    final cashiersMeta = await En1CashierCatalogStore.listMetaOnly();
    final pendingOps = await ref.read(syncPendingCountProvider.future);
    final biz = ref.read(businessConfigProvider);
    final licenseVal = await LicenseService().validate();
    final licenseSnap = await LicenseService().load();
    final licenseSummary = licenseSnap == null
        ? 'Sin snapshot EN1'
        : '${licenseSnap.licenseType.label} · ${licenseVal.effectiveStatus.label}'
            '${licenseSnap.planCode != null ? ' · ${licenseSnap.planCode}' : ''}';

    final pendingList = await isar.syncOperations
        .filter()
        .operationStatusEqualTo(SyncOperationStatus.pending)
        .findAll();
    final failedList = await isar.syncOperations
        .filter()
        .operationStatusEqualTo(SyncOperationStatus.failed)
        .sortByUpdatedAtDesc()
        .findAll();
    final byKind = <String, int>{};
    for (final op in pendingList) {
      final label = syncEntityKindLabel(op.entityKind);
      byKind[label] = (byKind[label] ?? 0) + 1;
    }
    final queueBreakdown = byKind.isEmpty
        ? 'Sin pendientes'
        : byKind.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
    final syncError = failedList.isEmpty
        ? null
        : '${syncEntityKindLabel(failedList.first.entityKind)}: '
            '${failedList.first.errorMessage ?? 'error'}';

    En1StatusSnapshot? en1Snap;
    try {
      en1Snap = await ref.read(en1StatusSnapshotProvider.future);
    } catch (_) {}
    if (config?.timezone != null) {
      await En1DateTimeService.setBusinessTimezone(config!.timezone);
    }
    En1DateTimeService.detectDeviceTimezoneMismatch();
    if (!mounted) return;
    setState(() {
      _device = device;
      _mode = mode;
      _status = status;
      _config = config;
      _error = error;
      _bootstrapDone = done;
      _bootstrapAt = at;
      _bootstrapError = bootstrapError;
      _syncError = syncError;
      _clockAudit = audit;
      _cashiersVersion = cashiersVersion;
      _cashiersTotal = cashiersMeta.length;
      _cashiersActive = cashiersMeta.where((c) => c.isActive).length;
      _pendingOps = en1Snap?.pendingOrders ?? pendingOps;
      _failedOps = failedList.length;
      _queueBreakdown = queueBreakdown;
      _lastSyncAt = en1Snap?.lastSyncAt ?? biz?.en1LastSyncAt;
      _link = en1Snap?.link ?? En1LinkState.unknown;
      _licenseSummary = licenseSummary;
      _appVersionLabel = appVersion;
      _loading = false;
    });
  }

  Future<void> _checkClock() async {
    if (!mounted) return;
    setState(() => _checkingClock = true);
    try {
      await En1ClockGuard.checkQuiet(apiBaseUrl: _config?.apiBaseUrl);
      final audit = await En1DateTimeService.loadAuditLog(limit: 12);
      if (!mounted) return;
      setState(() => _clockAudit = audit);
      final warnings = <String>[
        if (En1DateTimeService.timezoneMismatchWarningMessage() case final m?) m,
        if (En1DateTimeService.driftWarningMessage() case final m?) m,
      ];
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (warnings.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(warnings.join('\n\n')),
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Reloj OK respecto a EN1')),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingClock = false);
    }
  }

  Future<void> _copyClockAudit() async {
    final text = await En1DateTimeService.auditLogAsText(limit: 40);
    if (!mounted) return;
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log de reloj copiado')),
    );
  }

  bool _disconnecting = false;

  Future<void> _reprovision() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reaprovisionar dispositivo'),
        content: const Text(
          'Se pedirá un código de Caja de EN1. El UUID no cambia; '
          'el Device Token se rota y el bootstrap será obligatorio otra vez.\n\n'
          '¿Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.push(En1DeviceAuthRecovery.connectRoute);
  }

  Future<void> _disconnectEn1() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desconectar EasyNodeOne'),
        content: const Text(
          'Se borrará el token y la configuración de provisioning en este dispositivo. '
          'El UUID local se conserva. Deberás volver a conectar con un código de Caja.\n\n'
          '¿Desconectar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _disconnecting = true);
    try {
      final isar = await ref.read(databaseProvider.future);
      final configRepo = BusinessConfigRepository(isar);
      final current = await configRepo.getConfig();
      await configRepo.saveConfig(
        current
            .copyWith(
              en1SyncEnabled: false,
              en1ApiToken: '',
              en1ApiUrl: '',
            )
            .markAsModified(),
      );
      await En1ProvisioningRepository().disconnect();
      ref.read(posSessionProvider.notifier).lock();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispositivo desconectado de EN1')),
      );
      context.go('/platform/welcome');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo desconectar. Intente de nuevo.',
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await En1ProvisioningRepository().refreshConfig();
      if (!mounted) return;
      final cfg = await En1ProvisioningRepository().getConfig();
      if (En1DeviceAuthRecovery.isRevokedDeviceStatus(cfg?.deviceStatus)) {
        final route = await En1DeviceAuthRecovery.recoverAndLockSession(
          ref,
          reason:
              'Dispositivo revocado o inactivo en EN1 (${cfg?.deviceStatus}).',
        );
        if (!mounted) return;
        context.go(route);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración actualizada desde EN1')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (En1DeviceAuthRecovery.isUnauthorized(e)) {
        final route = await En1DeviceAuthRecovery.recoverAndLockSession(
          ref,
          reason: e is En1ProvisioningException
              ? e.userMessage
              : 'Dispositivo no autorizado. Reaprovisiona.',
        );
        if (!mounted) return;
        context.go(route);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is En1ProvisioningException
                ? e.userMessage
                : 'No se pudo actualizar. Intente de nuevo.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _runBootstrap() async {
    setState(() {
      _bootstrapping = true;
      _progressLabel = 'Iniciando descarga…';
      _progressFraction = null;
    });
    try {
      final isar = await ref.read(databaseProvider.future);
      final result = await En1BootstrapRepository(isar: isar).runBootstrap(
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progressLabel = p.label;
            _progressFraction = p.fraction;
          });
        },
      );
      ref.invalidate(productsListProvider);
      ref.invalidate(categoriesListProvider);
      ref.invalidate(posPagesListProvider);
      ref.invalidate(syncOperationsProvider);
      ref.invalidate(loginCashiersProvider);
      await enforceActiveEn1CashierSession(ref, context: context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green.shade700,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(e, fallback: 'No se pudo completar la descarga.'),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      ref.invalidate(syncOperationsProvider);
    } finally {
      if (mounted) {
        setState(() {
          _bootstrapping = false;
          _progressLabel = null;
          _progressFraction = null;
        });
      }
    }
  }

  Future<void> _repairPosPages() async {
    setState(() => _repairingPages = true);
    try {
      final isar = await ref.read(databaseProvider.future);
      final n = await En1BootstrapRepository(isar: isar).repairEn1PosPagesFromLocal();
      ref.invalidate(productsListProvider);
      ref.invalidate(categoriesListProvider);
      ref.invalidate(posPagesListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n > 0
                ? 'Menú POS reparado ($n página(s) Comida/Bar)'
                : 'Sin catálogo EN1 local — descargue el bootstrap primero',
          ),
          backgroundColor: n > 0 ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(e, fallback: 'No se pudo reparar el menú.'),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _repairingPages = false);
    }
  }

  String get _modeLabel => switch (_mode) {
        PlatformMode.local => 'Local',
        PlatformMode.platform => 'Plataforma (EN1)',
        PlatformMode.undecided => 'Sin definir',
      };

  String get _linkLabel => switch (_link) {
        En1LinkState.connected => 'Conectado',
        En1LinkState.offline => 'Sin conexión / sync off',
        En1LinkState.syncing => 'Sincronizando…',
        En1LinkState.unknown => 'Desconocido',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Este dispositivo'),
        actions: [
          IconButton(
            tooltip: 'Actualizar diagnóstico',
            onPressed: _loading || _bootstrapping ? null : () async {
              setState(() => _loading = true);
              await _load();
            },
            icon: const Icon(Icons.refresh),
          ),
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
                const Text('Hito 2.6 — Diagnóstico',
                    style: TextStyle(fontWeight: FontWeight.w700, color: EposBrand.navy)),
                const SizedBox(height: 8),
                _tile('Provisioning', _config == null ? 'No provisionado' : 'OK · ${_status.label}'),
                _tile('Conectividad EN1', _linkLabel),
                _tile(
                  'Último bootstrap',
                  _bootstrapDone
                      ? (_bootstrapAt != null
                          ? En1DateTimeService.formatLocal(_bootstrapAt!)
                          : 'Hecho (sin timestamp)')
                      : 'Pendiente',
                ),
                _tile(
                  'Último sync',
                  _lastSyncAt == null
                      ? 'Sin registro'
                      : En1DateTimeService.formatLocal(_lastSyncAt!),
                ),
                _tile(
                  'Cola / pendientes',
                  '$_pendingOps total'
                      '${_failedOps > 0 ? ' · $_failedOps con error' : ''}',
                ),
                _tile('Cola (detalle)', _queueBreakdown),
                if (_error != null) _tile('Último error provisioning', _error!),
                if (_bootstrapError != null)
                  _tile('Último error bootstrap', _bootstrapError!),
                if (_syncError != null) _tile('Último error sync', _syncError!),
                _tile('Versión APK', _appVersionLabel),
                _tile(
                  'cashiers_version',
                  _cashiersVersion?.toString() ?? '—',
                ),
                _tile(
                  'Cajeros locales EN1',
                  '$_cashiersActive activos / $_cashiersTotal total',
                ),
                if (_config?.configVersion != null)
                  _tile('config_version (bootstrap)', '${_config!.configVersion}'),
                _tile(
                  'Políticas comerciales',
                  'Pendiente freeze V6 (snapshot vacío OK)',
                ),
                _tile(
                  'Licencia',
                  _licenseSummary,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push('/platform/license'),
                    icon: const Icon(Icons.vpn_key_outlined, size: 18),
                    label: const Text('Ver detalle de licencia'),
                  ),
                ),
                const SizedBox(height: 16),
                _tile('Estado EN1', _status.label),
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
                  _tile(
                    'Provisionado',
                    En1DateTimeService.formatLocal(_config!.provisionedAt, 'dd/MM/yyyy HH:mm:ss'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Zona horaria (política EN1)',
                      style: TextStyle(fontWeight: FontWeight.w700, color: EposBrand.navy)),
                  const SizedBox(height: 8),
                  _tile('Zona EN1', En1DateTimeService.en1TimezoneId),
                  _tile('Hora negocio ahora', En1DateTimeService.formatLocal(En1DateTimeService.nowUtc(), 'dd/MM/yyyy HH:mm:ss')),
                  _tile('Zona del dispositivo', En1DateTimeService.deviceTimezoneLabel()),
                  _tile(
                    'Drift vs servidor',
                    En1DateTimeService.lastDrift == null
                        ? 'Sin medición aún'
                        : '${En1DateTimeService.lastDrift!.inSeconds}s'
                            '${En1DateTimeService.lastCheckedAtUtc != null ? ' · ${En1DateTimeService.formatLocal(En1DateTimeService.lastCheckedAtUtc!)}' : ''}',
                  ),
                  if (En1DateTimeService.timezoneMismatch)
                    _tile('Aviso', 'La zona del SO no coincide con EN1'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _checkingClock ? null : _checkClock,
                    icon: _checkingClock
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.schedule),
                    label: const Text('Verificar reloj vs EN1'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _copyClockAudit,
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Copiar log de reloj'),
                  ),
                  if (_clockAudit.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._clockAudit.take(5).map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${e['kind']} · ${e['message']}\n${e['atUtc']}',
                              style: const TextStyle(fontSize: 11, color: EposBrand.textSecondary),
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Hito 2 — Device Bootstrap',
                      style: TextStyle(fontWeight: FontWeight.w700, color: EposBrand.navy)),
                  const SizedBox(height: 8),
                  _tile(
                    'Catálogo EN1',
                    _bootstrapDone
                        ? 'Descargado${_bootstrapAt != null ? ' · ${En1DateTimeService.formatLocal(_bootstrapAt!)}' : ''}'
                        : 'Pendiente — descargue el catálogo EN1',
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
                  OutlinedButton.icon(
                    onPressed: (_bootstrapping || _repairingPages) ? null : _repairPosPages,
                    icon: _repairingPages
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restaurant_menu),
                    label: const Text('Reparar páginas Comida / Bar'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Aprovisionamiento',
                      style: TextStyle(fontWeight: FontWeight.w700, color: EposBrand.navy)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: (_bootstrapping || _disconnecting) ? null : _reprovision,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Reaprovisionar dispositivo'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: (_bootstrapping || _disconnecting) ? null : _disconnectEn1,
                    icon: _disconnecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link_off),
                    label: const Text('Desconectar EN1'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reaprovisionar: mismo UUID + código de Caja → token nuevo + bootstrap.\n'
                    'Desconectar: borra token local (UUID se conserva).',
                    style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                  ),
                  if (_progressLabel != null) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _progressFraction),
                    const SizedBox(height: 8),
                    Text(
                      _progressLabel!,
                      style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Descarga productos, imágenes y saldos desde EN1 (contrato Hito 2). '
                    'Configura el menú POS para vender. No descuenta stock por ventas todavía.',
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
