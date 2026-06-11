import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

final businessConfigAsyncProvider = FutureProvider<BusinessConfig>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  return BusinessConfigRepository(isar).getConfig();
});

final businessConfigProvider = Provider<BusinessConfig?>((ref) {
  return ref.watch(businessConfigAsyncProvider).valueOrNull;
});
