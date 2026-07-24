import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/features/commercial_engine/application/commercial_engine_facade.dart';
import 'package:eposone/src/features/commercial_engine/infrastructure/commercial_engine_factory.dart';

final commercialEngineProvider = Provider<CommercialEngineFacade>((ref) {
  final config = ref.watch(businessConfigProvider);
  return buildCommercialEngine(config);
});
