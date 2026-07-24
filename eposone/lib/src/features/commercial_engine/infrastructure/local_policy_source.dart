import 'package:eposone/src/features/commercial_engine/domain/commercial_policy_source.dart';
import 'package:eposone/src/features/fiscal/domain/business_fiscal_contract.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Políticas desde [BusinessConfig] local (Standalone o snapshot ya sync).
///
/// En Integrado, el bootstrap/sync debe volcar EN1 → mismo [BusinessConfig]
/// (u otro store del mismo shape); no duplicar modelos.
class LocalCommercialPolicySource implements CommercialPolicySource {
  LocalCommercialPolicySource(this._config,
      {this.origin = CommercialDataOrigin.local});

  final BusinessConfig? _config;

  @override
  final CommercialDataOrigin origin;

  @override
  double get taxRatePercent => _config?.taxRate ?? 0;

  @override
  bool get taxIncluded => _config?.taxIncluded ?? false;

  @override
  String? get taxName => _config?.taxName;

  @override
  BusinessFiscalContract get fiscalContract =>
      BusinessFiscalContract.fromConfig(_config);
}

class LocalCommercialPolicyResolver implements CommercialPolicyResolver {
  LocalCommercialPolicyResolver(this._config, {CommercialDataOrigin? origin})
      : _origin = origin ??
            ((_config?.isEn1SyncReady ?? false)
                ? CommercialDataOrigin.en1
                : CommercialDataOrigin.local);

  final BusinessConfig? _config;
  final CommercialDataOrigin _origin;

  @override
  CommercialPolicySource resolve() =>
      LocalCommercialPolicySource(_config, origin: _origin);
}
