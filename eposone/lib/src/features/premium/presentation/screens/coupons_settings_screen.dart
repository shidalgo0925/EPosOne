import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/premium/data/repositories/coupon_repository.dart';
import 'package:eposone/src/features/premium/domain/entities/coupon.dart';
import 'package:eposone/src/features/premium/presentation/providers/premium_provider.dart';

class CouponsSettingsScreen extends ConsumerWidget {
  const CouponsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cupones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context, ref),
          ),
        ],
      ),
      body: couponsAsync.when(
        data: (coupons) {
          if (coupons.isEmpty) {
            return const Center(child: Text('Sin cupones', style: TextStyle(color: EposBrand.textSecondary)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = coupons[i];
              final valueLabel = c.discountType == CouponDiscountType.percent
                  ? '${c.value.toStringAsFixed(0)}%'
                  : 'B/. ${c.value.toStringAsFixed(2)}';
              return ListTile(
                title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '$valueLabel · usos ${c.useCount}${c.isUnlimitedUses ? '' : '/${c.maxUses}'}'
                  '${c.description != null ? '\n${c.description}' : ''}',
                ),
                trailing: Switch(
                  value: c.isActive,
                  onChanged: (v) async {
                    await ref.read(couponRepositoryProvider).save(c.copyWith(isActive: v).markAsModified());
                    ref.invalidate(couponsListProvider);
                  },
                ),
                onLongPress: () => _confirmDelete(context, ref, c),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo cupón'),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref) async {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '10');
    var type = CouponDiscountType.percent;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuevo cupón'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Código', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CouponDiscountType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                items: CouponDiscountType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(couponDiscountTypeLabel(t))))
                    .toList(),
                onChanged: (v) => setLocal(() => type = v ?? type),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: type == CouponDiscountType.percent ? 'Porcentaje' : 'Monto',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
          ],
        ),
      ),
    );

    if (ok != true || codeCtrl.text.trim().isEmpty) return;

    final value = double.tryParse(valueCtrl.text.replaceAll(',', '.'));
    if (value == null || value <= 0) return;

    await ref.read(couponRepositoryProvider).save(
          Coupon.create(code: codeCtrl.text, discountType: type, value: value, description: 'Cupón promocional'),
        );
    ref.invalidate(couponsListProvider);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Coupon coupon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cupón'),
        content: Text('¿Eliminar ${coupon.code}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(couponRepositoryProvider).delete(coupon.localId);
              ref.invalidate(couponsListProvider);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
