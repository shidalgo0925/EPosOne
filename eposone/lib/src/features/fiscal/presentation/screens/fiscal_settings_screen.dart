import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/fiscal/domain/entities/fiscal_document.dart';
import 'package:eposone/src/features/fiscal/domain/entities/pac_provider_type.dart';
import 'package:eposone/src/features/fiscal/presentation/providers/fiscal_provider.dart';
import 'package:eposone/src/features/fiscal/presentation/widgets/fiscal_status_chip.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';

class FiscalSettingsScreen extends ConsumerStatefulWidget {
  const FiscalSettingsScreen({super.key});

  @override
  ConsumerState<FiscalSettingsScreen> createState() => _FiscalSettingsScreenState();
}

class _FiscalSettingsScreenState extends ConsumerState<FiscalSettingsScreen> {
  final _branchCtrl = TextEditingController();
  final _pointCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _enabled = false;
  PacProviderType _provider = PacProviderType.none;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await ref.read(businessConfigRepositoryProvider).getConfig();
    if (!mounted) return;
    setState(() {
      _enabled = config.fiscalInvoicingEnabled;
      _provider = config.pacProvider;
      _branchCtrl.text = config.fiscalBranchCode ?? '';
      _pointCtrl.text = config.fiscalPointOfSale ?? '';
      _urlCtrl.text = config.pacApiUrl ?? '';
      _tokenCtrl.text = config.pacApiToken ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _branchCtrl.dispose();
    _pointCtrl.dispose();
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(businessConfigRepositoryProvider);
      final config = await repo.getConfig();
      await repo.saveConfig(
        config.copyWith(
          fiscalInvoicingEnabled: _enabled,
          pacProvider: _provider,
          fiscalBranchCode: _branchCtrl.text.trim().isEmpty ? null : _branchCtrl.text.trim(),
          fiscalPointOfSale: _pointCtrl.text.trim().isEmpty ? null : _pointCtrl.text.trim(),
          pacApiUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
          pacApiToken: _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
        ).markAsModified(),
      );
      ref.invalidate(businessConfigAsyncProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración fiscal guardada')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(businessConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturación electrónica'),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: SwitchListTile(
                    title: const Text('Emitir FE al cobrar'),
                    subtitle: const Text('Genera comprobante fiscal DGI al completar venta'),
                    value: _enabled,
                    onChanged: _saving ? null : (v) => setState(() => _enabled = v),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PacProviderType>(
                  value: _provider,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor PAC',
                    border: OutlineInputBorder(),
                  ),
                  items: PacProviderType.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(pacProviderTypeLabel(p))))
                      .toList(),
                  onChanged: _saving ? null : (v) => setState(() => _provider = v ?? PacProviderType.none),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _branchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Código sucursal DGI',
                    hintText: '001',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pointCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Punto de emisión',
                    hintText: '001',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL API PAC (futuro)',
                    border: OutlineInputBorder(),
                  ),
                  enabled: _provider != PacProviderType.stub,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Token API PAC (futuro)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  enabled: _provider != PacProviderType.stub,
                ),
                const SizedBox(height: 16),
                if (config != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('RUC del negocio'),
                    subtitle: Text(
                      (config.ruc ?? '').isEmpty ? 'Configure en onboarding / datos del negocio' : config.ruc!,
                      style: TextStyle(color: (config.ruc ?? '').isEmpty ? Colors.orange.shade800 : null),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Próximo correlativo fiscal'),
                    subtitle: Text(config.nextFiscalNumber),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/settings/fiscal/documents'),
                  icon: const Icon(Icons.history),
                  label: const Text('Ver comprobantes emitidos'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'L8 — integración DGI en desarrollo. El modo Stub simula aceptación sin certificado real.',
                  style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                ),
              ],
            ),
    );
  }
}

class FiscalDocumentsScreen extends ConsumerWidget {
  const FiscalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(fiscalDocumentsProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Comprobantes fiscales')),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(child: Text('Sin comprobantes fiscales', style: TextStyle(color: EposBrand.textSecondary)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final doc = docs[i];
              return ListTile(
                leading: Icon(
                  doc.documentType == FiscalDocumentType.invoice ? Icons.receipt_long : Icons.undo,
                  color: EposBrand.navy,
                ),
                title: Text(doc.fiscalNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${fiscalDocumentTypeLabel(doc.documentType)} · ${dateFmt.format(doc.issuedAt)}'
                  '${doc.customerName != null ? '\n${doc.customerName}' : ''}',
                ),
                trailing: FiscalStatusChip(status: doc.status),
                isThreeLine: doc.customerName != null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
