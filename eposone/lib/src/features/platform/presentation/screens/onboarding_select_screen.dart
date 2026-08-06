import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/platform/data/en1_onboarding_api.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_api.dart';
import 'package:eposone/src/features/platform/data/en1_provisioning_repository.dart';
import 'package:eposone/src/features/platform/data/onboarding_user_session_store.dart';
import 'package:eposone/src/features/platform/domain/onboarding_session.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/en1_sync_mode.dart';

/// Gate 2 — Selección org + caja → issue-code → Register → Bootstrap.
class OnboardingSelectScreen extends ConsumerStatefulWidget {
  const OnboardingSelectScreen({super.key, this.restore = false});

  final bool restore;

  @override
  ConsumerState<OnboardingSelectScreen> createState() =>
      _OnboardingSelectScreenState();
}

class _OnboardingSelectScreenState extends ConsumerState<OnboardingSelectScreen> {
  final _api = En1OnboardingApi();
  final _provisionRepo = En1ProvisioningRepository();

  OnboardingSession? _session;
  String? _apiUrl;
  String? _token;
  int? _orgId;
  String? _registerRef;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await OnboardingUserSessionStore.loadToken();
      final url = await OnboardingUserSessionStore.loadApiUrl();
      if (token == null || url == null || token.isEmpty || url.isEmpty) {
        if (!mounted) return;
        context.go(
          widget.restore
              ? '/platform/onboarding/login?restore=1'
              : '/platform/onboarding/login',
        );
        return;
      }
      final session = await _api.fetchSession(
        apiBaseUrl: url,
        userBearer: token,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _apiUrl = url;
        _token = token;
        _orgId = session.selectedOrganizationId ??
            (session.organizations.length == 1
                ? session.organizations.first.organizationId
                : null);
        _loading = false;
      });
      if (_orgId != null &&
          session.organizations.length > 1 &&
          session.selectedOrganizationId == null) {
        await _reloadOrg(_orgId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is En1OnboardingException
            ? e.userMessage
            : 'No se pudo cargar la sesión.';
      });
    }
  }

  Future<void> _reloadOrg(int orgId) async {
    final url = _apiUrl;
    final token = _token;
    if (url == null || token == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await _api.fetchSession(
        apiBaseUrl: url,
        userBearer: token,
        organizationId: orgId,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _orgId = orgId;
        _registerRef = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is En1OnboardingException
            ? e.userMessage
            : 'No se pudo cargar la organización.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  OnboardingOrganization? get _org {
    final s = _session;
    final id = _orgId;
    if (s == null || id == null) return null;
    for (final o in s.organizations) {
      if (o.organizationId == id) return o;
    }
    return null;
  }

  Future<void> _activate() async {
    final org = _org;
    final url = _apiUrl;
    final token = _token;
    final regRef = _registerRef;
    if (org == null || url == null || token == null || regRef == null) {
      setState(() => _error = 'Selecciona organización y caja.');
      return;
    }
    if (!org.subscriptionEntitled) {
      setState(() => _error = 'Suscripción inactiva. Revisa el plan en EN1.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      var code = org.registers
          .where((r) => r.registerRef == regRef)
          .map((r) => r.activeProvisioningCode)
          .firstWhere((c) => c != null && c.isNotEmpty, orElse: () => null);

      if (code == null || code.isEmpty) {
        if (!org.canIssueProvisioningCode) {
          throw En1OnboardingException(
            userMessage:
                'No puedes emitir código. Usa el portal EN1 o elige otra caja.',
            technicalDetail: 'can_issue_provisioning_code=false',
          );
        }
        final issued = await _api.issueCode(
          apiBaseUrl: url,
          userBearer: token,
          organizationId: org.organizationId,
          registerRef: regRef,
        );
        code = issued.code;
      }

      final pkg = await PackageInfo.fromPlatform();
      final config = await _provisionRepo.provision(
        apiBaseUrl: url,
        provisioningCode: code,
        appVersion: '${pkg.version}+${pkg.buildNumber}',
      );

      final isar = await ref.read(databaseProvider.future);
      final configRepo = BusinessConfigRepository(isar);
      final current = await configRepo.getConfig();
      await configRepo.saveConfig(
        current
            .copyWith(
              businessName: config.businessName ??
                  config.empresaName ??
                  current.businessName,
              isSetupComplete: true,
              en1SyncEnabled: true,
              en1SyncMode: En1SyncMode.live,
              en1ApiUrl: config.apiBaseUrl,
              en1ApiToken: config.accessToken,
              en1BranchId: config.branchRef,
            )
            .markAsModified(),
      );

      await OnboardingUserSessionStore.clear();
      if (!mounted) return;
      context.go('/platform/bootstrap');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is En1OnboardingException
            ? e.userMessage
            : e is En1ProvisioningException
                ? e.userMessage
                : 'No se pudo registrar el dispositivo.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.restore ? 'Restaurar caja' : 'Instalar dispositivo';
    return Scaffold(
      backgroundColor: EposBrand.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy
              ? null
              : () => context.go(
                    widget.restore
                        ? '/platform/onboarding/login?restore=1'
                        : '/platform/onboarding/login',
                  ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (_error != null) ...[
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
                        const SizedBox(height: 16),
                        if (_session == null)
                          TextButton(
                            onPressed: _busy ? null : _load,
                            child: const Text('Reintentar'),
                          ),
                      ],
                      if (_session != null) ...[
                        Text(
                          _session!.fullName?.isNotEmpty == true
                              ? 'Hola, ${_session!.fullName}'
                              : _session!.email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.restore
                              ? 'Elige la caja a recuperar. Se emitirá código y se registrará este dispositivo.'
                              : 'Elige organización y caja. Luego Register → Bootstrap (sin cambiar el pipeline).',
                          style: const TextStyle(color: EposBrand.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          value: _orgId,
                          decoration: const InputDecoration(
                            labelText: 'Organización',
                          ),
                          items: [
                            for (final o in _session!.organizations)
                              DropdownMenuItem(
                                value: o.organizationId,
                                child: Text(
                                  '${o.name} · ${o.modality}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  _reloadOrg(v);
                                },
                        ),
                        const SizedBox(height: 16),
                        if (_org != null) ...[
                          Text(
                            'Plan: ${_org!.planCode} · Modalidad: ${_org!.modality}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: EposBrand.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_org!.registers.isEmpty)
                            const Text(
                              'No hay cajas en esta organización. Créalas en EN1.',
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: _registerRef,
                              decoration: const InputDecoration(
                                labelText: 'Caja (POS)',
                              ),
                              items: [
                                for (final r in _org!.registers)
                                  DropdownMenuItem(
                                    value: r.registerRef,
                                    child: Text(
                                      r.name.isNotEmpty ? r.name : r.registerRef,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (v) => setState(() => _registerRef = v),
                            ),
                          if (widget.restore && _org!.devices.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Dispositivos conocidos',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            for (final d in _org!.devices)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.tablet_android),
                                title: Text(d.deviceLabel ?? d.deviceUuid),
                                subtitle: Text(
                                  '${d.status ?? ""} · ${d.registerRef ?? ""}',
                                ),
                              ),
                          ],
                        ],
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: (_busy ||
                                  _orgId == null ||
                                  _registerRef == null)
                              ? null
                              : _activate,
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
                                  widget.restore
                                      ? 'Restaurar y continuar'
                                      : 'Registrar dispositivo',
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
