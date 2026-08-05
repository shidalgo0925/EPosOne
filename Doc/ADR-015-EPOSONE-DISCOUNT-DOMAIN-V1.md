# ADR-015 — Discount Domain V1 (Motor de Descuentos)

| Campo | Valor |
|-------|--------|
| **Estado** | **Fase B en curso** — Isar + seed + UI mínima + puente Totales; P0 E2E sigue primero |
| **Fecha** | 5 de agosto de 2026 |
| **Prioridad** | **P0.5** — no desplaza certificación P0 |
| **SoT** | Este ADR + decisión ETS Discount Domain V1 |
| **Relacionado** | [`ADR-008`](ADR-008-EPOSONE-COMMERCIAL-ENGINE.md) · Totals Engine · [`EPOSONE_DISCOUNT_DOMAIN_INVENTORY_V1.md`](EPOSONE_DISCOUNT_DOMAIN_INVENTORY_V1.md) |

---

## 1. Decisión

EPOSOne adopta un **Discount Domain** genérico:

- El descuento es un **Programa** (`DiscountProgram`).
- El porcentaje/monto **nunca** pertenece al cliente.
- LEGAL y COMMERCIAL usan la **misma** infraestructura.
- `AppliedDiscount` (+ allocations) queda **inmutable** en la venta.
- El dominio **no calcula impuestos**; solo base elegible, monto de descuento y distribución.
- Totals/Pricing Engine consume el resultado y calcula ITBMS/total.
- UI **no decide** descuentos: consume `DiscountResolver`.

### Secuencia canónica

```text
Order (líneas)
    ↓
Discount Domain (DiscountResolver)
    ↓
Pricing / Totals Engine
    ↓
Taxes
    ↓
Receipt
```

---

## 2. Decisiones de cierre (ETS + Local)

| # | Decisión |
|---|----------|
| D1 | Discount Domain **no conoce impuestos** |
| D2 | `DiscountProgram.version` + `AppliedDiscount.program_version`; nunca recalcular venta con otra versión |
| D3 | `effective_from` / `effective_to` (además de vigencia comercial) |
| D4 | Única puerta: **`DiscountResolver`** |
| — | `scope`: `ORDER` \| `ITEMS` |
| — | Un programa activo por venta en V1; multi-línea OK en `ITEMS` |
| — | Jubilado restaurante: `LEGAL_PENSIONER_RESTAURANT_PA` 25% `ITEMS` |
| — | Fast food: `LEGAL_PENSIONER_FAST_FOOD_PA` 15% (seed, no auto-activar) |
| — | Clasificación comercio fuera de la venta (`RESTAURANT`, `FAST_FOOD_FRANCHISE`, …) |
| — | `MANUAL_AUTHORIZED` reemplaza % libre sin trazabilidad |
| — | Standalone-first; EN1 solo lectura cuando `source=EN1` y exista contrato |

---

## 3. Fuera de V1

Cupones, loyalty, happy hour, campañas, promos automáticas, combos, reglas por horario/categoría/sucursal (diseño extensible, no implementado).

---

## 4. Fases

| Fase | Contenido | Estado |
|------|-----------|--------|
| **A** | ADR, inventario, modelos, resolver, tests unitarios, doc EN1 pendiente | **Cerrada** (`5f131da`) |
| **B** | Isar catálogo, seed SYSTEM, snapshot en ticket/cart, puente Totales, UI Programa + Settings | **En curso** (paralelo P0; % legacy aún disponible) |
| **C** | Contrato HTTP EN1 + sync | Bloqueada |

---

## 5. Entidades (Fase A — código)

| Entidad | Rol |
|---------|-----|
| `DiscountProgram` | Catálogo: type, source, value, scope, **version**, **effective_from/to**, auth/doc flags |
| `AppliedDiscount` | Snapshot inmutable en venta + **program_version** |
| `AppliedDiscountAllocation` | Distribución por línea |
| `DiscountResolver` | Única API: elegibles → validar → un resultado |
| `DefaultDiscountResolver` | Implementación pura (sin I/O, sin impuestos) |

Código: `eposone/lib/src/features/discount/`  
Tests: `eposone/test/features/discount/discount_domain_v1_test.dart`

Percent almacenado en **centésimas de punto porcentual** (25% → `2500`). Montos en **centavos**.

---

## 6. Dinero

Cálculos del Discount Domain en **centavos enteros** (`int`). Asignación por peso con remainder; `sum(allocations) == discount_amount`. Bridge a `double` solo en bordes legacy hasta migración Totales (Fase B).

Fiscal post-descuento: **propuesta técnica** sujeta a validación contador/PAC antes de producción.

---

## 7. Consecuencias

- Pantallas nuevas no escriben `documentDiscountPercent` / `Amount` directamente.
- Campos legacy → deprecated; puente vía `MANUAL_AUTHORIZED` en Fase B.
- P0 (caja, sync, cajeros, pedidos, reportes, licencia) **sigue primero**.
- **No** cablear Discount Domain al flujo de venta POS hasta Fase B.
