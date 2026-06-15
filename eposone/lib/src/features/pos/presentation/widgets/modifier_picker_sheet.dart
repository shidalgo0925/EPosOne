import 'package:flutter/material.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/products/data/repositories/modifier_repository.dart';
import 'package:eposone/src/features/products/domain/entities/modifier.dart';
import 'package:eposone/src/features/products/domain/entities/selected_modifier.dart';

/// Muestra grupos de modificadores y devuelve la selección confirmada.
Future<List<SelectedModifier>?> showModifierPickerSheet(
  BuildContext context, {
  required List<ModifierGroupWithOptions> groups,
  required String symbol,
}) {
  return showModalBottomSheet<List<SelectedModifier>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => _ModifierPickerSheet(groups: groups, symbol: symbol),
  );
}

class _ModifierPickerSheet extends StatefulWidget {
  final List<ModifierGroupWithOptions> groups;
  final String symbol;

  const _ModifierPickerSheet({required this.groups, required this.symbol});

  @override
  State<_ModifierPickerSheet> createState() => _ModifierPickerSheetState();
}

class _ModifierPickerSheetState extends State<_ModifierPickerSheet> {
  late final Map<String, Set<String>> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {
      for (final g in widget.groups)
        g.group.localId: g.options.where((o) => o.isDefault).map((o) => o.localId).toSet(),
    };
  }

  void _toggle(ModifierGroupWithOptions group, Modifier option) {
    setState(() {
      final set = _selected[group.group.localId] ?? {};
      if (group.group.isSingleChoice) {
        _selected[group.group.localId] = {option.localId};
      } else {
        final next = Set<String>.from(set);
        if (next.contains(option.localId)) {
          next.remove(option.localId);
        } else if (group.group.maxSelect <= 0 || next.length < group.group.maxSelect) {
          next.add(option.localId);
        }
        _selected[group.group.localId] = next;
      }
    });
  }

  bool _validate() {
    for (final g in widget.groups) {
      final count = _selected[g.group.localId]?.length ?? 0;
      if (g.group.minSelect > 0 && count < g.group.minSelect) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Elige al menos ${g.group.minSelect} en "${g.group.name}"')),
        );
        return false;
      }
    }
    return true;
  }

  List<SelectedModifier> _buildSelection() {
    final result = <SelectedModifier>[];
    for (final g in widget.groups) {
      final ids = _selected[g.group.localId] ?? {};
      for (final opt in g.options) {
        if (ids.contains(opt.localId)) {
          result.add(SelectedModifier(
            modifierId: opt.localId,
            groupId: g.group.localId,
            groupName: g.group.name,
            name: opt.name,
            priceDelta: opt.priceDelta,
          ));
        }
      }
    }
    return result;
  }

  double get _extraTotal {
    var total = 0.0;
    for (final g in widget.groups) {
      final ids = _selected[g.group.localId] ?? {};
      for (final opt in g.options) {
        if (ids.contains(opt.localId)) total += opt.priceDelta;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: EposBrand.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Modificadores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final g in widget.groups) ...[
                      Text(
                        g.group.name + (g.group.isRequired ? ' *' : ''),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: EposBrand.navy),
                      ),
                      if (g.group.isSingleChoice)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text('Elige una opción', style: TextStyle(fontSize: 11, color: EposBrand.textSecondary)),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: g.options.map((opt) {
                          final selected = _selected[g.group.localId]?.contains(opt.localId) ?? false;
                          final priceLabel = opt.priceDelta > 0
                              ? ' +${widget.symbol}${opt.priceDelta.toStringAsFixed(2)}'
                              : '';
                          return FilterChip(
                            label: Text('${opt.name}$priceLabel'),
                            selected: selected,
                            onSelected: (_) => _toggle(g, opt),
                            selectedColor: EposBrand.orange.withValues(alpha: 0.2),
                            checkmarkColor: EposBrand.orange,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            if (_extraTotal > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Extra: ${widget.symbol}${_extraTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (!_validate()) return;
                      Navigator.pop(context, _buildSelection());
                    },
                    child: const Text('Agregar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
