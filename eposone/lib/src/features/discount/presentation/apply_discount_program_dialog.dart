import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/discount/application/default_discount_resolver.dart';
import 'package:eposone/src/features/discount/data/discount_program_repository.dart';
import 'package:eposone/src/features/discount/domain/discount_enums.dart';
import 'package:eposone/src/features/discount/domain/discount_mappers.dart';
import 'package:eposone/src/features/discount/domain/discount_program.dart';
import 'package:eposone/src/features/discount/domain/discount_resolve_request.dart';
import 'package:eposone/src/features/discount/domain/discount_resolve_result.dart';
import 'package:eposone/src/features/discount/domain/money_cents.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';

/// Applies a catalog program via [DiscountResolver] (UI does not compute).
Future<void> showApplyDiscountProgramDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final cart = ref.read(cartProvider);
  if (cart.items.isEmpty) return;

  final repo = ref.read(discountProgramRepositoryProvider);
  final catalog = await repo.listAll();
  final config = await ref.read(businessConfigRepositoryProvider).getConfig();
  final establishment =
      mapFiscalToDiscountEstablishment(config.establishmentType);
  const resolver = DefaultDiscountResolver();
  final eligible = resolver.eligiblePrograms(
    DiscountResolveRequest(
      lines: const [],
      catalog: catalog,
      establishmentType: establishment,
      at: DateTime.now(),
    ),
  );

  if (!context.mounted) return;
  if (eligible.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay programas de descuento elegibles')),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => _ApplyProgramDialog(
      eligible: eligible,
      establishment: establishment,
      catalog: catalog,
    ),
  );
}

class _ApplyProgramDialog extends ConsumerStatefulWidget {
  const _ApplyProgramDialog({
    required this.eligible,
    required this.establishment,
    required this.catalog,
  });

  final List<DiscountProgram> eligible;
  final DiscountEstablishmentClass establishment;
  final List<DiscountProgram> catalog;

  @override
  ConsumerState<_ApplyProgramDialog> createState() =>
      _ApplyProgramDialogState();
}

class _ApplyProgramDialogState extends ConsumerState<_ApplyProgramDialog> {
  DiscountProgram? _selected;
  final _nameCtrl = TextEditingController();
  final _manualPctCtrl = TextEditingController(text: '10');
  final _reasonCtrl = TextEditingController();
  bool _docConfirmed = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manualPctCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return AlertDialog(
      title: const Text('Programa de descuento'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cart.appliedDiscount != null)
                TextButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).clearProgramDiscount();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Quitar ${cart.appliedDiscount!.programCode}',
                  ),
                ),
              DropdownButtonFormField<DiscountProgram>(
                initialValue: _selected,
                decoration: const InputDecoration(
                  labelText: 'Programa',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final p in widget.eligible)
                    DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (${p.code})'),
                    ),
                ],
                onChanged: (p) => setState(() {
                  _selected = p;
                  _error = null;
                }),
              ),
              if (_selected?.code == 'MANUAL_AUTHORIZED') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _manualPctCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '% autorizado',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_selected?.requiresCustomer == true) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Beneficiario (ocasional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_selected?.requiresDocumentCheck == true) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Documento verificado'),
                  value: _docConfirmed,
                  onChanged: (v) =>
                      setState(() => _docConfirmed = v ?? false),
                ),
              ],
              if (_selected?.scope == DiscountScope.items) ...[
                const SizedBox(height: 8),
                const Text('Líneas beneficiario:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                for (final item in cart.items)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.displayName),
                    subtitle: Text(
                      '${item.quantity.toStringAsFixed(0)} × ${item.unitPrice.toStringAsFixed(2)}',
                    ),
                    value: item.discountBeneficiary,
                    onChanged: (v) {
                      ref
                          .read(cartProvider.notifier)
                          .setDiscountBeneficiary(item.id, v ?? false);
                    },
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selected == null ? null : _apply,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  void _apply() {
    final program = _selected!;
    final cart = ref.read(cartProvider);
    final session = ref.read(posSessionProvider);
    const resolver = DefaultDiscountResolver();

    int? valueOverride;
    if (program.code == 'MANUAL_AUTHORIZED') {
      final pct = double.tryParse(_manualPctCtrl.text.trim());
      if (pct == null || pct <= 0) {
        setState(() => _error = 'Indique un % válido');
        return;
      }
      valueOverride = (pct * 100).round();
    }

    final result = resolver.resolve(
      DiscountResolveRequest(
        lines: [
          for (final item in cart.items)
            DiscountLineInput(
              lineId: item.id,
              unitPriceCents:
                  MoneyCents.fromDecimalString(item.unitPrice.toStringAsFixed(2)),
              quantity: item.quantity.round().clamp(1, 999999),
              markedBeneficiary: item.discountBeneficiary,
            ),
        ],
        catalog: widget.catalog,
        establishmentType: widget.establishment,
        at: DateTime.now(),
        selectedProgramCode: program.code,
        valueOverride: valueOverride,
        beneficiary: DiscountBeneficiaryInput(
          kind: program.requiresCustomer
              ? BeneficiaryKind.occasional
              : BeneficiaryKind.none,
          occasionalName: _nameCtrl.text.trim().isEmpty
              ? null
              : _nameCtrl.text.trim(),
          documentCheckConfirmed: _docConfirmed,
          documentCheckType: _docConfirmed
              ? DocumentCheckType.cedula
              : DocumentCheckType.none,
        ),
        authorization: DiscountAuthorizationInput(
          authorized: !program.requiresAuthorization ||
              _reasonCtrl.text.trim().isNotEmpty,
          authorizedByUserId: session?.cashierId,
          reason: _reasonCtrl.text.trim().isEmpty
              ? null
              : _reasonCtrl.text.trim(),
        ),
      ),
    );

    if (result.status != DiscountResolveStatus.applied ||
        result.applied == null) {
      setState(() {
        _error = result.rejectionMessage ?? 'No se pudo aplicar';
      });
      return;
    }

    ref.read(cartProvider.notifier).applyProgramDiscount(result.applied!);
    Navigator.pop(context);
  }
}
