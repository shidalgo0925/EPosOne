import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/data/adapters/en1_api_adapter.dart';

/// Stub offline-first para push de clientes (dev).
class StubEn1Adapter implements En1ApiAdapter {
  @override
  Future<En1PushResult> pushCustomer({
    required BusinessConfig config,
    required Customer customer,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (config.en1BranchId == null || config.en1BranchId!.trim().isEmpty) {
      throw StateError('Configure el ID de sucursal EN1');
    }
    return En1PushResult(serverId: 'EN1-CUS-${customer.localId}');
  }
}
