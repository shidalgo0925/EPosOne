# EPosOne — Inventario descuentos actuales (pre–Discount Domain V1)

| Campo | Valor |
|-------|--------|
| **Fecha** | 5 ago 2026 |
| **Fase** | A (ADR-015) |
| **Objetivo** | Listar puntos de escritura/lectura de descuento legacy antes de migrar |

---

## Campos / modelos

| Ubicación | Campo | Uso |
|-----------|--------|-----|
| `CartState` | `discountPercent` | % documento libre |
| `CartState` | `couponDiscount` | Monto cupón / global |
| `OpenTicket` (Isar) | `discountPercent` | Persistido en ticket abierto |
| `OrderTotalsInput` / totals | `documentDiscountPercent` | Entrada Totales |
| | `documentDiscountAmount` | Monto documento |
| | `couponDiscount` | Cupón |
| | `lineDiscount` (por línea) | Descuento de línea |
| `OrderItem` | `discount` | Descuento en ítem Order Domain |
| Premium cupones | UI / merchandising | Fuera de Discount Domain V1 |

## Pantallas / flujos que escriben descuento

| Flujo | Archivo (aprox.) | Acción Fase B |
|-------|------------------|---------------|
| Panel ticket % | `pos_ticket_panel.dart` | → UI Discount / `MANUAL_AUTHORIZED` |
| Cart provider | `cart_provider.dart` | Dejar de exponer % libre al cajero |
| Bill preview | `open_ticket_bill_preview.dart` | Leer `AppliedDiscount` |
| POS totals bridge | `pos_provider.dart` | Entrada desde Resolver → Totales |
| Legacy merchandising | `legacy_merchandising_engine.dart` | Deprecated para descuentos programa |
| Legacy totals | `legacy_totals_engine.dart` | Consumir resultado Discount Domain |

## Programas sistema (seed Fase A/B)

| Code | Notas |
|------|--------|
| `LEGAL_PENSIONER_RESTAURANT_PA` | 25% ITEMS ACTIVE |
| `LEGAL_PENSIONER_FAST_FOOD_PA` | 15% ITEMS seed, no auto |
| `MANUAL_AUTHORIZED` | ORDER + auth + motivo |
| Fixtures test | Empleado 10%, VIP 5%, Familiar 10% (inactivos) |

## Migración (Fase B)

1. Snapshot ventas históricas: conservar campos legacy en lectura.
2. Nuevas ventas: solo `AppliedDiscount` + allocations.
3. UI: ocultar editor %; botón **Descuento** → Resolver.
4. Bridge temporal: Totales acepta `discount_amount` del Resolver como documento hasta refactor limpio.
