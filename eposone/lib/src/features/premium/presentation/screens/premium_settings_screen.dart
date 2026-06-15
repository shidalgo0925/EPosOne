import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';

class PremiumSettingsScreen extends ConsumerStatefulWidget {
  const PremiumSettingsScreen({super.key});

  @override
  ConsumerState<PremiumSettingsScreen> createState() => _PremiumSettingsScreenState();
}

class _PremiumSettingsScreenState extends ConsumerState<PremiumSettingsScreen> {
  bool _loyaltyEnabled = false;
  final _pointsCtrl = TextEditingController(text: '1');
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
      _loyaltyEnabled = config.loyaltyEnabled;
      _pointsCtrl.text = config.loyaltyPointsPerUnit.toStringAsFixed(1);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveLoyalty() async {
    setState(() => _saving = true);
    try {
      final points = double.tryParse(_pointsCtrl.text.replaceAll(',', '.')) ?? 1;
      final repo = ref.read(businessConfigRepositoryProvider);
      final config = await repo.getConfig();
      await repo.saveConfig(
        config.copyWith(
          loyaltyEnabled: _loyaltyEnabled,
          loyaltyPointsPerUnit: points.clamp(0, 100),
        ).markAsModified(),
      );
      ref.invalidate(businessConfigAsyncProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fidelización guardada')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.local_offer_outlined, color: EposBrand.orange),
                  title: const Text('Cupones promocionales'),
                  subtitle: const Text('Códigos de descuento en POS'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/premium/coupons'),
                ),
                const Divider(height: 32),
                Text('Fidelización', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Acumular puntos al cobrar'),
                  subtitle: const Text('Requiere cliente en el ticket'),
                  value: _loyaltyEnabled,
                  onChanged: _saving ? null : (v) => setState(() => _loyaltyEnabled = v),
                ),
                TextField(
                  controller: _pointsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Puntos por unidad de moneda',
                    border: OutlineInputBorder(),
                    helperText: 'Ej: 1 punto por cada B/. 1 de venta',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _saveLoyalty,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar fidelización'),
                ),
                const SizedBox(height: 24),
                const ListTile(
                  leading: Icon(Icons.card_giftcard_outlined),
                  title: Text('Gift cards'),
                  subtitle: Text('Próximamente — add-on EN1'),
                ),
                const ListTile(
                  leading: Icon(Icons.workspace_premium_outlined),
                  title: Text('Membresías'),
                  subtitle: Text('Próximamente — add-on EN1'),
                ),
              ],
            ),
    );
  }
}
