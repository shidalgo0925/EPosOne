import 'package:eposone/src/features/commercial_engine/application/commercial_engine_facade.dart';
import 'package:eposone/src/features/commercial_engine/domain/commercial_policy_source.dart';
import 'package:eposone/src/features/commercial_engine/infrastructure/legacy_merchandising_engine.dart';
import 'package:eposone/src/features/commercial_engine/infrastructure/legacy_payment_engine.dart';
import 'package:eposone/src/features/commercial_engine/infrastructure/legacy_totals_engine.dart';
import 'package:eposone/src/features/commercial_engine/infrastructure/local_policy_source.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Composition root reutilizable por Riverpod y servicios de sync.
CommercialEngineFacade buildCommercialEngine(
  BusinessConfig? config, {
  CommercialDataOrigin? origin,
}) {
  return CommercialEngineFacade(
    totals: LegacyTotalsEngine(),
    tax: StubTaxEngine(),
    tip: StubTipEngine(),
    payment: LegacyPaymentEngine(),
    merchandising: LegacyMerchandisingEngine(),
    policies: LocalCommercialPolicyResolver(config, origin: origin),
  );
}
