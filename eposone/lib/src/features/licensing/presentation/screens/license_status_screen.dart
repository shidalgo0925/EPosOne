import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/licensing/data/license_audit_store.dart';
import 'package:eposone/src/features/licensing/domain/license_enums.dart';
import 'package:eposone/src/features/licensing/presentation/license_providers.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';

/// Pantalla informativa de licencia (sin compra / renovación).
class LicenseStatusScreen extends ConsumerStatefulWidget {
  const LicenseStatusScreen({super.key});

  @override
  ConsumerState<LicenseStatusScreen> createState() => _LicenseStatusScreenState();
}

class _LicenseStatusScreenState extends ConsumerState<LicenseStatusScreen> {
  List<Map<String, dynamic>> _events = const [];
  String? _org;
  String? _caja;

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final cfg = await ProvisioningStore.loadConfig();
    final events = await LicenseAuditStore.recent(limit: 12);
    if (!mounted) return;
    setState(() {
      _org = cfg?.organizationName ?? cfg?.businessName ?? cfg?.organizationId;
      _caja = cfg?.registerName ?? cfg?.registerRef;
      _events = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapAsync = ref.watch(licenseSnapshotProvider);
    final valAsync = ref.watch(licenseValidationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Licencia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'License Engine V1.0',
            style: TextStyle(fontWeight: FontWeight.w700, color: EposBrand.navy),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estado informativo. La tablet no crea ni renueva licencias comerciales.',
            style: TextStyle(color: EposBrand.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          snapAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (snap) {
              final validation = valAsync.valueOrNull;
              final effective = validation?.effectiveStatus ?? snap?.status;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tile('Plan', snap?.planCode ?? '—'),
                  _tile('Tipo', snap?.licenseType.label ?? 'Sin snapshot'),
                  _tile(
                    'Estado',
                    effective?.label ?? '—',
                  ),
                  _tile(
                    'Activación',
                    snap?.activationMethod.code ?? '—',
                  ),
                  _tile(
                    'Inicio',
                    snap?.startsAt != null
                        ? En1DateTimeService.formatLocal(snap!.startsAt!)
                        : '—',
                  ),
                  _tile(
                    'Vence',
                    snap?.expiresAt != null
                        ? En1DateTimeService.formatLocal(snap!.expiresAt!)
                        : (snap?.licenseType == LicenseType.perpetual
                            ? 'Nunca'
                            : '—'),
                  ),
                  _tile(
                    'Gracia hasta',
                    snap?.graceUntil != null
                        ? En1DateTimeService.formatLocal(snap!.graceUntil!)
                        : '—',
                  ),
                  _tile(
                    'Última validación',
                    snap?.lastValidation != null
                        ? En1DateTimeService.formatLocal(snap!.lastValidation!)
                        : '—',
                  ),
                  _tile(
                    'Puede operar POS',
                    validation == null
                        ? '—'
                        : (validation.canOperatePos ? 'Sí' : 'No'),
                  ),
                  _tile('Organización', _org ?? '—'),
                  _tile('Caja', snap?.registerId ?? _caja ?? '—'),
                  if (snap != null && snap.features.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Features',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: EposBrand.navy)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final e in snap.features.entries)
                          Chip(
                            label: Text(
                              '${e.key}${e.value ? '' : ' ✕'}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: e.value
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.08),
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('Eventos recientes',
              style: TextStyle(fontWeight: FontWeight.w700, color: EposBrand.navy)),
          const SizedBox(height: 8),
          if (_events.isEmpty)
            const Text('Sin eventos', style: TextStyle(color: EposBrand.textSecondary))
          else
            for (final e in _events)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${e['event']} · ${e['at'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                ),
              ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    color: EposBrand.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
