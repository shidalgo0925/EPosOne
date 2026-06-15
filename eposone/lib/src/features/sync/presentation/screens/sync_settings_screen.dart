import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/products/presentation/providers/product_provider.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/sync/data/repositories/sync_repository.dart';
import 'package:eposone/src/features/sync/domain/entities/en1_sync_mode.dart';
import 'package:eposone/src/features/sync/domain/entities/sync_entity_kind.dart';
import 'package:eposone/src/features/sync/presentation/providers/sync_provider.dart';
import 'package:eposone/src/features/sync/presentation/widgets/sync_status_chip.dart';

class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  final _branchCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _enabled = false;
  En1SyncMode _mode = En1SyncMode.none;
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
      _enabled = config.en1SyncEnabled;
      _mode = config.en1SyncMode;
      _branchCtrl.text = config.en1BranchId ?? '';
      _urlCtrl.text = config.en1ApiUrl ?? '';
      _tokenCtrl.text = config.en1ApiToken ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _branchCtrl.dispose();
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
          en1SyncEnabled: _enabled,
          en1SyncMode: _mode,
          en1BranchId: _branchCtrl.text.trim().isEmpty ? null : _branchCtrl.text.trim(),
          en1ApiUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
          en1ApiToken: _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
        ).markAsModified(),
      );
      ref.invalidate(businessConfigAsyncProvider);
      ref.invalidate(syncPendingCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración EN1 guardada')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncNow() async {
    try {
      final result = await ref.read(runSyncCycleProvider)();
      ref.invalidate(productsListProvider);
      ref.invalidate(categoriesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync: ${result.succeeded} ok, ${result.failed} error')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pullCatalog() async {
    try {
      await ref.read(syncRepositoryProvider).enqueueCatalogPull();
      ref.invalidate(syncPendingCountProvider);
      await _syncNow();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(businessConfigProvider);
    final pendingAsync = ref.watch(syncPendingCountProvider);
    final running = ref.watch(syncRunningProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('EN1 Cloud'),
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
                    title: const Text('Sincronizar con EN1'),
                    subtitle: const Text('Cola offline: ventas ↑, catálogo ↓'),
                    value: _enabled,
                    onChanged: _saving ? null : (v) => setState(() => _enabled = v),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<En1SyncMode>(
                  value: _mode,
                  decoration: const InputDecoration(labelText: 'Modo', border: OutlineInputBorder()),
                  items: En1SyncMode.values
                      .map((m) => DropdownMenuItem(value: m, child: Text(en1SyncModeLabel(m))))
                      .toList(),
                  onChanged: _saving ? null : (v) => setState(() => _mode = v ?? En1SyncMode.none),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _branchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID sucursal EN1',
                    hintText: 'store-001',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL API EN1',
                    border: OutlineInputBorder(),
                  ),
                  enabled: _mode == En1SyncMode.live,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Token API EN1',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  enabled: _mode == En1SyncMode.live,
                ),
                const SizedBox(height: 16),
                pendingAsync.when(
                  data: (count) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Operaciones pendientes'),
                    trailing: count > 0
                        ? CircleAvatar(
                            radius: 14,
                            backgroundColor: EposBrand.orange,
                            child: Text('$count', style: const TextStyle(fontSize: 11, color: Colors.white)),
                          )
                        : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (config?.en1LastSyncAt != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Última sincronización'),
                    subtitle: Text(dateFmt.format(config!.en1LastSyncAt!)),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: running || config?.isEn1SyncReady != true ? null : _syncNow,
                  icon: running
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.sync),
                  label: Text(running ? 'Sincronizando…' : 'Sincronizar ahora'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: running || config?.isEn1SyncReady != true ? null : _pullCatalog,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Descargar catálogo EN1'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/settings/sync/history'),
                  icon: const Icon(Icons.history),
                  label: const Text('Historial de sync'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'L9 — last-write-wins por updatedAt. Ventas y clientes se encolan al guardar; reintento automático hasta 5 veces.',
                  style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                ),
              ],
            ),
    );
  }
}

class SyncHistoryScreen extends ConsumerWidget {
  const SyncHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opsAsync = ref.watch(syncOperationsProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Historial sync')),
      body: opsAsync.when(
        data: (ops) {
          if (ops.isEmpty) {
            return const Center(child: Text('Sin operaciones', style: TextStyle(color: EposBrand.textSecondary)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: ops.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final op = ops[i];
              return ListTile(
                leading: Icon(
                  op.direction == SyncDirection.push ? Icons.upload_outlined : Icons.download_outlined,
                  color: EposBrand.navy,
                ),
                title: Text(
                  '${syncDirectionLabel(op.direction)} · ${syncEntityKindLabel(op.entityKind)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${dateFmt.format(op.createdAt)}'
                  '${op.entityLocalId != null ? '\n${op.entityLocalId}' : ''}'
                  '${op.errorMessage != null ? '\n${op.errorMessage}' : ''}',
                  maxLines: 4,
                ),
                trailing: SyncStatusChip(status: op.operationStatus),
                isThreeLine: true,
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
