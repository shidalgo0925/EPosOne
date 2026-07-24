# Spec Motor de Totales EPosOne V1

| Campo | Valor |
|-------|--------|
| **Estado** | Borrador — revisión Analista / P1 / P2 |
| **Fecha** | 19 jul 2026 |
| **Versión** | v1.0-draft |
| **Roadmap** | [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md) |
| **Depende de** | Modelo · Tax · Tip · Pagos · Print · [`EPOSONE_COMMERCIAL_ENGINE_SPEC_V1.md`](EPOSONE_COMMERCIAL_ENGINE_SPEC_V1.md) |
| **Siguiente** | Fase 5 — ADR-008 (documenta decisiones) |
| **Alcance** | Algoritmo determinista de totales + ejemplos. **Sin** código ni APIs. |

---

## 1. Propósito

Congelar **cómo** se calcula el total de un pedido/venta para que:

- Standalone e Integrado den el **mismo resultado** con las mismas políticas y líneas.
- Impresión, caja, sync y reportes usen el mismo snapshot.
- EN1 pueda **revalidar** en modo Integrado.

Este documento es la fuente del orden de cálculo del V6.

---

## 2. Orden oficial de cálculo (congelado)

```text
Pedido (líneas a precio efectivo)
  → Descuentos de línea
  → Promociones / descuentos de documento (prorrateo)
  → Propinas          ← según Tip Policy (base configurable)
  → Impuestos         ← según Tax Contract (multi-regla por línea)
  → Redondeos
  → Total a cobrar
  → (Pagos / cambio — Contrato Pagos; no recalculan el total)
```

### Notas de orden

1. **Precio efectivo** ya incluye price list / happy hour / combo resueltos por el Motor Comercial (§ entrada).
2. **Propina antes de impuesto** es el orden V6 del analista. Si la Tip Policy elige base `post_tax_total`, el motor calcula un **passthrough**:
   - Pasa A: subtotal → desc → promos → base_pre_tax → impuestos → total_sin_propina.
   - Pasa B: propina = f(base tip) usando `post_tax` = total_sin_propina (o la base configurada).
   - Total final = total_sin_propina + propina.
3. Si la base tip es `pre_tax_*`, la propina se inserta **antes** de impuestos y puede formar parte o no de la base gravable según Tip+Tax (default V1: **propina no gravada**).

**Default tip V1:** base `post_tax_total` → usar passthrough A→B (compatibilidad UX actual del POS).

---

## 3. Precisión y redondeo

| Regla | Valor V1 |
|-------|----------|
| Unidad monetaria | 2 decimales |
| Modo | half-up |
| Qty | según producto (`allowDecimalQty`); redondeo de línea sobre `qty × price` a 4 decimales internos opcionales, resultado línea a 2 |
| Impuesto por línea y regla | 2 decimales half-up |
| Propina | 2 decimales half-up |
| Descuento | 2 decimales half-up |
| Residual de prorrateo | Ajuste de ±0.01 en la línea de mayor subtotal elegible |

Prohibido acumular error de `double` sin redondear en cada paso de dinero.

---

## 4. Pipeline detallado

### Paso 0 — Normalizar líneas

Para cada línea \(i\):

- `qty_i`, `unit_price_i` (efectivo post Motor Comercial)
- `line_gross_i = round2(qty_i × unit_price_i)`

`subtotal_gross = sum(line_gross_i)`

### Paso 1 — Descuentos de línea

- Monto o % según regla/manual.
- `line_after_line_disc_i = max(0, line_gross_i − line_disc_i)`
- `sum_line_disc = sum(line_disc_i)`

### Paso 2 — Promos / descuento documento

- Calcular beneficio global sobre base elegible (líneas no excluidas).
- Prorratear a líneas elegibles ∝ `line_after_line_disc_i`.
- Ajustar residual ±0.01.
- `line_net_i = max(0, line_after_line_disc_i − allocated_global_i)`
- `subtotal_net = sum(line_net_i)`
- `total_discounts = sum_line_disc + global_disc`

### Paso 3 — Impuestos (Tax Contract)

Para cada línea, según categoría fiscal → reglas ordenadas por prioridad:

**Precio excluido impuesto (default pipeline):**

- Base por regla según Tax (`line_net` u otra).
- Si `parallel`: impuesto = round2(base × tasa).
- Si `compound`: base incluye impuestos previos de menor prioridad.
- `line_tax_i = sum(tax components)`
- `tax_total = sum(line_tax_i)`

**Precio incluido impuesto:**

- Extraer neto e impuesto por fórmulas del Tax Contract (multi-regla: ver ejemplo §7.3).
- El `line_net` mostrado es neto; el cobro al cliente sigue siendo el bruto pactado tras descuentos sobre bruto (detalle en ejemplo).

`total_pre_tip = subtotal_net + tax_total`  
(si tax-included y el precio ya era bruto, no sumar de nuevo: `total_pre_tip = subtotal_net_bruto_tras_desc` con tax extraído solo para desglose)

### Paso 4 — Propina (Tip Policy)

Según modo (`none` / `optional` / `suggested` / `mandatory`) y método:

- Si base `post_tax_total`: `tip = round2(total_pre_tip × %)` o monto fijo.
- Si base `pre_tax_*`: calcular tip sobre `subtotal_net` (u otra) **antes** del paso 3 y no incluir tip en bases gravables (default).

`tip_amount` del snapshot.

### Paso 5 — Total

`grand_total = round2(total_pre_tip + tip_amount)`  
(ajustes de redondeo de documento si la política lo define; default ninguno extra)

### Paso 6 — Pagos (no recalcula)

Los tenders cubren `grand_total`. Cambio según Contrato Pagos.

---

## 5. Snapshot de totales (salida)

El motor emite un objeto lógico:

| Bloque | Contenido |
|--------|-----------|
| Versiones | commercial_engine, tax_contract, tip_policy, totals_engine |
| Líneas | gross, discs, net, taxes[], tip allocation n/a |
| Documento | subtotal_gross, discounts, subtotal_net, tax_breakdown{}, tip, grand_total |
| Trace | reglas comerciales disparadas |

Este snapshot alimenta Print, Sale, sync y revalidación EN1.

---

## 6. Dual Mode / validación EN1

| Modo | Comportamiento |
|------|----------------|
| Standalone | Solo motor local; snapshot local es verdad. |
| Integrado | POS calcula offline con snapshot de políticas; al sync EN1 recalcula con el mismo algoritmo. |
| Divergencia | Gana EN1; se registra diferencia y se notifica (no silenciar). Tolerancia propuesta: 0.00 (estricta) o 0.01 configurable. |

---

## 7. Ejemplos Panamá

Moneda: `$` = USD/PAB. Redondeo half-up 2 decimales. Propina default post-tax. Impuestos excluidos salvo §7.3.

### 7.1 Restaurante — ITBMS 7% + propina sugerida 10%

**Líneas**

| Producto | Qty | P.unit | Cat. fiscal |
|----------|-----|--------|-------------|
| Hamburguesa | 2 | 8.00 | ITBMS 7% |
| Refresco | 2 | 2.50 | ITBMS 7% |

**Cálculo**

- Subtotal gross = 16.00 + 5.00 = **21.00**
- Descuentos = 0
- Base = 21.00  
- ITBMS 7% = round2(21.00 × 0.07) = **1.47**
- Total pre-tip = 22.47  
- Propina 10% post-tax = round2(22.47 × 0.10) = **2.25**
- **Grand total = 24.72**

**Pago mixto:** Visa 20.00 + Efectivo 10.00 → aplicado 24.72; cambio efectivo = 5.28.

**Desglose fiscal recibo:** solo `ITBMS 7% 1.47`.

---

### 7.2 Bar — Ron con ISC + ITBMS (compound) + Happy Hour

**Política comercial:** Happy Hour −20% en categoría Bar (ya aplicado → precio efectivo).

| Producto | Qty | Lista | Efectivo (−20%) | Reglas |
|----------|-----|-------|-----------------|--------|
| Ron | 1 | 25.00 | 20.00 | ISC 10% compound + ITBMS 7% |

**Cálculo (precio excluido)**

- Line net = 20.00  
- ISC 10% = round2(20.00 × 0.10) = **2.00**  
- Base ITBMS = 20.00 + 2.00 = 22.00  
- ITBMS 7% = round2(22.00 × 0.07) = **1.54**  
- Tax total = 3.54  
- Total pre-tip = 23.54  
- Propina: política `none` → 0  
- **Grand total = 23.54**

**Recibo fiscal:**

```text
ISC Licor    2.00
ITBMS 7%     1.54
```

---

### 7.3 Cafetería — precios con ITBMS incluido

Producto: Café Latte · precio lista **5.35** (incluye ITBMS 7%) · qty 1 · sin desc · sin propina.

Extracción:

- Neto = round2(5.35 / 1.07) = round2(5.00) = **5.00**  
- ITBMS = round2(5.35 − 5.00) = **0.35**  
- **Grand total = 5.35** (no se suma el impuesto otra vez)

**Prohibido:** mostrar ITBMS 0.00 cuando taxIncluded=true.

---

### 7.4 Retail — descuento documento 10% + dos tasas

| Producto | Qty | P.unit | Fiscal |
|----------|-----|--------|--------|
| Camiseta | 1 | 40.00 | ITBMS 7% |
| Libro | 1 | 20.00 | EXENTO |

- Subtotal gross = 60.00  
- Desc. documento 10% = 6.00  
- Prorrateo: Camiseta 4.00 · Libro 2.00  
- Net: Camiseta 36.00 · Libro 18.00  
- ITBMS 7% solo camiseta = round2(36.00 × 0.07) = **2.52**  
- Libro exento = 0  
- Total = 36.00 + 18.00 + 2.52 = **56.52**  
- Propina none  

**Recibo:** `ITBMS 7% 2.52` (no fila 10%/15%).

---

### 7.5 Estación de combustible — qty decimal

| Producto | Qty | P.unit | Fiscal |
|----------|-----|--------|--------|
| Diesel | 36.04 | 1.11 | EXENTO (ejemplo ilustrativo) |

- Line = round2(36.04 × 1.11) = round2(40.0044) = **40.00**  
- Tax 0 · tip 0  
- **Total = 40.00**  
- Pago efectivo 40.00 · cambio 0  

Columnas recibo: Cant 36.04 · Und · Precio 1.11 · Itbms 0.00 · Monto 40.00.

---

### 7.6 Food truck — mixto sin propina

Subtotal 15.00 · ITBMS 7% = 1.05 · Total 16.05  

Pagos: Yappy 10.00 + Efectivo 10.00 → aplicado 16.05 · cambio 3.95.

---

## 8. Reembolsos (totales)

- **Total:** invierte snapshot (líneas, taxes, tip, tenders).  
- **Parcial:** recalcular con el mismo pipeline solo líneas/qty devueltas **o** prorratear montos del snapshot; **propuesta V1:** recalcular subset con mismos precios/reglas del snapshot origen (versiones guardadas), no con políticas nuevas.

---

## 9. Criterios de aceptación

1. Orden §2 documentado y ejemplos §7 verificables a mano.  
2. Redondeo half-up 2 decimales en cada monto.  
3. Multi-impuesto y tax-included correctos.  
4. Propina post-tax vía passthrough sin mezclar con tax en desglose.  
5. Prorrateo global + residual.  
6. Dual-mode / divergencia EN1 definida.  
7. Listo para que ADR-008 solo cite este algoritmo.

---

## 10. Decisiones abiertas

1. Tolerancia de revalidación EN1: **0.00 vs 0.01** — propuesta **0.01** en sync, **0.00** en pruebas golden.  
2. Confirmar compound ISC→ITBMS del ejemplo 7.2 con Analista fiscal PA.  
3. Tip gravada: default **no**; si un día sí, Tax rule explícita.

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Borrador V1: orden, redondeo, pipeline, dual-mode, 6 ejemplos Panamá. |
