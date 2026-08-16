import 'package:eposone/src/features/platform/data/provisioning_store.dart';

/// Sello local org/POS/caja desde provisioning (no inventa HTTP).
class OrderPosProvenance {
  const OrderPosProvenance({
    this.organizationId,
    this.posRef,
    this.registerRef,
  });

  final String? organizationId;
  final String? posRef;
  final String? registerRef;

  static Future<OrderPosProvenance> load() async {
    final cfg = await ProvisioningStore.loadConfig();
    if (cfg == null) return const OrderPosProvenance();
    return OrderPosProvenance(
      organizationId:
          cfg.organizationId.trim().isEmpty ? null : cfg.organizationId.trim(),
      posRef: cfg.posRef.trim().isEmpty ? null : cfg.posRef.trim(),
      registerRef:
          cfg.registerRef.trim().isEmpty ? null : cfg.registerRef.trim(),
    );
  }
}
