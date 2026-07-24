import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/fiscal/domain/establishment_type.dart';
import 'package:eposone/src/features/fiscal/domain/fiscal_category.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';

/// Ajustes → Fiscal / Impuestos (contrato del comercio).
class TaxContractSettingsScreen extends ConsumerStatefulWidget {
  const TaxContractSettingsScreen({super.key});

  @override
  ConsumerState<TaxContractSettingsScreen> createState() =>
      _TaxContractSettingsScreenState();
}

class _TaxContractSettingsScreenState
    extends ConsumerState<TaxContractSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  EstablishmentType _establishmentType = EstablishmentType.other;
  bool _chargesRestaurantService = false;
  bool _sellsAlcohol = false;
  bool _isExemptEstablishment = false;
  bool _taxIncluded = false;
  final _taxNameCtrl = TextEditingController(text: 'ITBMS');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await ref.read(businessConfigRepositoryProvider).getConfig();
    if (!mounted) return;
    setState(() {
      _establishmentType = config.establishmentType;
      _chargesRestaurantService = config.chargesRestaurantService;
      _sellsAlcohol = config.sellsAlcohol;
      _isExemptEstablishment = config.isExemptEstablishment ||
          config.establishmentType == EstablishmentType.fonda;
      _taxIncluded = config.taxIncluded;
      _taxNameCtrl.text =
          (config.taxName == null || config.taxName!.trim().isEmpty)
              ? 'ITBMS'
              : config.taxName!;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _taxNameCtrl.dispose();
    super.dispose();
  }

  void _onEstablishmentChanged(EstablishmentType? type) {
    if (type == null) return;
    setState(() {
      _establishmentType = type;
      if (type == EstablishmentType.fonda) {
        _isExemptEstablishment = true;
        _chargesRestaurantService = false;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(businessConfigRepositoryProvider);
      final config = await repo.getConfig();
      final exempt = _isExemptEstablishment ||
          _establishmentType == EstablishmentType.fonda;
      await repo.saveConfig(
        config
            .copyWith(
              establishmentType: _establishmentType,
              chargesRestaurantService:
                  exempt ? false : _chargesRestaurantService,
              sellsAlcohol: _sellsAlcohol,
              isExemptEstablishment: exempt,
              taxIncluded: _taxIncluded,
              taxName: _taxNameCtrl.text.trim().isEmpty
                  ? 'ITBMS'
                  : _taxNameCtrl.text.trim(),
              // Legacy: tasa referencia 7% para reportes antiguos.
              taxRate: exempt ? 0 : 7,
            )
            .markAsModified(),
      );
      ref.invalidate(businessConfigAsyncProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato fiscal guardado')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiscal / Impuestos'),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Contrato fiscal del comercio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Las tasas salen del catálogo por categoría de producto. '
                  'No se fijan porcentajes en la pantalla de cobro.',
                  style: TextStyle(
                    fontSize: 13,
                    color: EposBrand.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EstablishmentType>(
                  value: _establishmentType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de establecimiento',
                    border: OutlineInputBorder(),
                  ),
                  items: EstablishmentType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(establishmentTypeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: _saving ? null : _onEstablishmentChanged,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _taxNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del impuesto',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_saving,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Establecimiento exento'),
                        subtitle: const Text(
                          'Fondas / exentos legales: todas las líneas a 0%',
                        ),
                        value: _isExemptEstablishment ||
                            _establishmentType == EstablishmentType.fonda,
                        onChanged: _saving ||
                                _establishmentType == EstablishmentType.fonda
                            ? null
                            : (v) =>
                                setState(() => _isExemptEstablishment = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Cobra servicio de restaurante'),
                        subtitle: const Text(
                          'Alimentos EXENTO se gravan al 7% como servicio',
                        ),
                        value: _chargesRestaurantService &&
                            !_isExemptEstablishment &&
                            _establishmentType != EstablishmentType.fonda,
                        onChanged: _saving ||
                                _isExemptEstablishment ||
                                _establishmentType == EstablishmentType.fonda
                            ? null
                            : (v) =>
                                setState(() => _chargesRestaurantService = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Vende alcohol'),
                        subtitle: const Text(
                          'Permite categorías ITBMS 10% en catálogo',
                        ),
                        value: _sellsAlcohol,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _sellsAlcohol = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Precios con impuesto incluido'),
                        subtitle: const Text(
                          'El motor extrae ITBMS del precio de lista',
                        ),
                        value: _taxIncluded,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _taxIncluded = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Catálogo de categorías (referencia)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...FiscalCategory.catalog.map(
                  (c) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.name),
                    subtitle: Text(c.code),
                    trailing: Text(
                      '${c.baseRatePercent.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
