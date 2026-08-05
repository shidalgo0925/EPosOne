import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/features/discount/data/discount_program_repository.dart';
import 'package:eposone/src/features/discount/domain/discount_program.dart';

final _discountProgramsProvider =
    FutureProvider<List<DiscountProgram>>((ref) async {
  return ref.watch(discountProgramRepositoryProvider).listAll();
});

/// Admin catalog for Discount Domain programs (SYSTEM + LOCAL).
class DiscountProgramsSettingsScreen extends ConsumerWidget {
  const DiscountProgramsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_discountProgramsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Programas de descuento')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (programs) {
          if (programs.isEmpty) {
            return const Center(child: Text('Sin programas'));
          }
          return ListView.separated(
            itemCount: programs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = programs[i];
              final active = p.isActive;
              return ListTile(
                title: Text(p.name),
                subtitle: Text(
                  '${p.code} · ${p.type.name} · ${p.source.name} · '
                  'v${p.version} · ${p.scope.name}'
                  '${p.valueType.name == 'percent' ? ' · ${p.percentDisplay}%' : ''}',
                ),
                trailing: Switch(
                  value: active,
                  onChanged: p.source.name == 'en1'
                      ? null
                      : (v) async {
                          await ref
                              .read(discountProgramRepositoryProvider)
                              .setActive(p.code, v);
                          ref.invalidate(_discountProgramsProvider);
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
