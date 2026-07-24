import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/sync/data/adapters/live_en1_adapter.dart';
import 'package:eposone/src/features/sync/data/adapters/stub_en1_adapter.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/domain/entities/en1_sync_mode.dart';

class En1PushResult {
  final String serverId;
  const En1PushResult({required this.serverId});
}

/// Adapter EN1 residual (Hito 2 customers stub).
/// Catálogo = [En1BootstrapRepository]. Pedidos = Order Domain (no este adapter).
abstract class En1ApiAdapter {
  Future<En1PushResult> pushCustomer({
    required BusinessConfig config,
    required Customer customer,
  });
}

En1ApiAdapter createEn1Adapter(En1SyncMode mode) {
  switch (mode) {
    case En1SyncMode.stub:
      return StubEn1Adapter();
    case En1SyncMode.live:
      return LiveEn1Adapter();
    case En1SyncMode.none:
      throw StateError('EN1 sync desactivado');
  }
}
