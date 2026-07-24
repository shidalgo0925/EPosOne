/// Códigos de feature del License Engine V1.0.
///
/// La app pregunta `FeatureManager.isEnabled(...)`, nunca `licenseType == ...`.
enum LicenseFeature {
  sales,
  payments,
  inventory,
  customers,
  reports,
  dashboard,
  tips,
  taxes,
  kitchen,
  bar,
  kds,
  delivery,
  giftcards,
  loyalty,
  credit,
  multiPos,
  multiBranch,
  api,
  ai,
  fiscal,
}

extension LicenseFeatureX on LicenseFeature {
  String get code => switch (this) {
        LicenseFeature.sales => 'sales',
        LicenseFeature.payments => 'payments',
        LicenseFeature.inventory => 'inventory',
        LicenseFeature.customers => 'customers',
        LicenseFeature.reports => 'reports',
        LicenseFeature.dashboard => 'dashboard',
        LicenseFeature.tips => 'tips',
        LicenseFeature.taxes => 'taxes',
        LicenseFeature.kitchen => 'kitchen',
        LicenseFeature.bar => 'bar',
        LicenseFeature.kds => 'kds',
        LicenseFeature.delivery => 'delivery',
        LicenseFeature.giftcards => 'giftcards',
        LicenseFeature.loyalty => 'loyalty',
        LicenseFeature.credit => 'credit',
        LicenseFeature.multiPos => 'multi_pos',
        LicenseFeature.multiBranch => 'multi_branch',
        LicenseFeature.api => 'api',
        LicenseFeature.ai => 'ai',
        LicenseFeature.fiscal => 'fiscal',
      };

  static LicenseFeature? tryParse(String raw) {
    final k = raw.trim().toLowerCase().replaceAll('-', '_');
    for (final f in LicenseFeature.values) {
      if (f.code == k) return f;
    }
    return null;
  }
}

/// Features core del POS que permanecen ON si no hay snapshot EN1 (Standalone).
const kStandaloneDefaultFeatures = <LicenseFeature>{
  LicenseFeature.sales,
  LicenseFeature.payments,
  LicenseFeature.customers,
  LicenseFeature.reports,
  LicenseFeature.tips,
  LicenseFeature.taxes,
  LicenseFeature.inventory,
  LicenseFeature.dashboard,
  LicenseFeature.kitchen,
  LicenseFeature.bar,
  LicenseFeature.fiscal,
};
