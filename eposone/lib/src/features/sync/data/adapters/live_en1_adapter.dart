import 'package:eposone/src/features/customers/domain/entities/customer.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';
import 'package:eposone/src/features/sync/data/adapters/en1_api_adapter.dart';

/// Adapter live residual: clientes aún no tienen endpoint Hito 2/3.
/// Catálogo → [En1BootstrapRepository]. Pedidos → Order Domain.
class LiveEn1Adapter implements En1ApiAdapter {
  @override
  Future<En1PushResult> pushCustomer({
    required BusinessConfig config,
    required Customer customer,
  }) async {
    throw StateError(
      'Push de clientes a EN1 aún no está en el contrato activo.',
    );
  }
}
