import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

part 'business_config_repository.g.dart';

@riverpod
BusinessConfigRepository businessConfigRepository(BusinessConfigRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return BusinessConfigRepository(db);
}

class BusinessConfigRepository {
  final Isar _isar;
  BusinessConfigRepository(this._isar);

  Future<BusinessConfig> getConfig() async {
    final config = await _isar.businessConfigs.get(1);
    if (config != null) return config;
    final defaultConfig = BusinessConfig.defaultConfig();
    await _isar.writeTxn(() => _isar.businessConfigs.put(defaultConfig));
    return defaultConfig;
  }

  Future<void> saveConfig(BusinessConfig config) => _isar.writeTxn(() => _isar.businessConfigs.put(config));

  Future<String> getNextReceiptNumber() async {
    final config = await getConfig();
    final number = config.nextReceiptNumber;
    await saveConfig(config.incrementReceiptNumber());
    return number;
  }
}