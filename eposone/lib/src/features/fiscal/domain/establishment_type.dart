/// Tipo de establecimiento (contrato fiscal del comercio).
enum EstablishmentType {
  restaurant,
  fonda,
  cafeteria,
  bar,
  supermarket,
  pharmacy,
  hardware,
  store,
  other,
}

String establishmentTypeLabel(EstablishmentType type) {
  switch (type) {
    case EstablishmentType.restaurant:
      return 'Restaurante';
    case EstablishmentType.fonda:
      return 'Fonda / exento';
    case EstablishmentType.cafeteria:
      return 'Cafetería';
    case EstablishmentType.bar:
      return 'Bar';
    case EstablishmentType.supermarket:
      return 'Supermercado';
    case EstablishmentType.pharmacy:
      return 'Farmacia';
    case EstablishmentType.hardware:
      return 'Ferretería';
    case EstablishmentType.store:
      return 'Tienda';
    case EstablishmentType.other:
      return 'Otro';
  }
}
