import 'package:eposone/src/features/fiscal/domain/establishment_type.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Contrato fiscal local del comercio (Tax Contract V1 — subset Panamá).
class BusinessFiscalContract {
  const BusinessFiscalContract({
    required this.establishmentType,
    required this.chargesRestaurantService,
    required this.sellsAlcohol,
    required this.isExemptEstablishment,
    required this.taxIncluded,
    this.taxName,
  });

  final EstablishmentType establishmentType;
  final bool chargesRestaurantService;
  final bool sellsAlcohol;
  final bool isExemptEstablishment;
  final bool taxIncluded;
  final String? taxName;

  factory BusinessFiscalContract.fromConfig(BusinessConfig? config) {
    if (config == null) {
      return const BusinessFiscalContract(
        establishmentType: EstablishmentType.other,
        chargesRestaurantService: false,
        sellsAlcohol: false,
        isExemptEstablishment: false,
        taxIncluded: false,
        taxName: 'ITBMS',
      );
    }
    return BusinessFiscalContract(
      establishmentType: config.establishmentType,
      chargesRestaurantService: config.chargesRestaurantService,
      sellsAlcohol: config.sellsAlcohol,
      isExemptEstablishment: config.isExemptEstablishment ||
          config.establishmentType == EstablishmentType.fonda,
      taxIncluded: config.taxIncluded,
      taxName: config.taxName,
    );
  }
}
