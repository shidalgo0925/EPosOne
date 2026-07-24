# Contrato Fiscal EPosOne V1

| Campo | Valor |
|-------|--------|
| **Estado** | Borrador — revisión Analista / P1 / P2 |
| **Fecha** | 19 jul 2026 |
| **Versión** | v1.0-draft |
| **Roadmap** | [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md) |
| **Depende de** | [`EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md`](EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md) |
| **Siguiente** | Contrato de Propinas |
| **Alcance** | Reglas fiscales de negocio. **Sin** tablas SQL, payloads HTTP ni integración PAC/FE. |

---

## 1. Propósito

Definir cómo EPosOne (Standalone o Integrado) determina **qué impuestos aplican**, **sobre qué base**, **con qué prioridad y redondeo**, y cómo se **desglosan** en la venta y el documento.

**Prohibido:** programar tasas fijas (7, 10, 15…) en UI, recibos o lógica de venta. Toda tasa vive en el **catálogo** del contrato.

---

## 2. Principios

| # | Regla |
|---|--------|
| 1 | Un **Contrato Fiscal** es una política versionada (igual que el Modelo Comercial). |
| 2 | Mismo contrato en Standalone (local) e Integrado (EN1 → sync). |
| 3 | Un producto no “tiene un porcentaje”: tiene una **categoría fiscal** que apunta a una o más **reglas de impuesto**. |
| 4 | Una línea puede acumular **varios impuestos** (p. ej. ISC + ITBMS). |
| 5 | El desglose fiscal de una venta solo muestra **impuestos realmente aplicados** (dinámico). |
| 6 | Cambiar el contrato no altera ventas pasadas; la venta conserva montos calculados. |
| 7 | El **orden relativo** propina ↔ impuesto lo congela el Motor de Totales; este contrato define la **base imponible fiscal**. |

---

## 3. Contrato Fiscal (política)

### 3.1 Datos generales

| Campo | Descripción |
|-------|-------------|
| Nombre | Etiqueta humana (ej. “Fiscal Panamá Retail 2026”). |
| Código | Identificador estable (ej. `PA-RETAIL-2026`). |
| País / jurisdicción | Contexto legal (ej. PA). |
| Activo | Sí/No. |
| Vigencia | Desde / hasta. |
| Versión | Incrementa en cada cambio publicado. |
| Moneda de cálculo | Alineada a la empresa (ej. USD/PAB). |

### 3.2 Scope de asignación

Empresa → Sucursal → Caja (la más específica gana), según Modelo Comercial.

### 3.3 Origen

| Modo | Edición | Aplicación |
|------|---------|------------|
| Standalone | Admin local POS | Motor local |
| Integrado | EN1 BO | Snapshot POS + validación EN1 al sync |

---

## 4. Catálogo de impuestos (reglas)

Cada **regla de impuesto** dentro del contrato define un impuesto concreto.

### 4.1 Atributos de una regla

| Atributo | Descripción |
|----------|-------------|
| Código | Estable (ej. `ITBMS_7`, `ITBMS_10`, `ISC_LICOR`, `EXENTO`). |
| Nombre | Para UI y recibo (ej. “ITBMS 7%”). |
| Tipo | Ver §4.2. |
| Tasa | Porcentaje o monto fijo según tipo de cálculo. |
| Modo de cálculo | `percent_of_base` · `fixed_per_unit` · `fixed_per_line` · `none` (exento/marcador). |
| Prioridad | Orden de aplicación cuando hay varios en la misma línea (menor = primero). |
| Acumula | Si el siguiente impuesto se calcula sobre base + impuestos previos (`compound`) o solo sobre la misma base (`parallel`). |
| Base imponible | Ver §5. |
| Aplica descuento antes | Sí: la base ya trae descuentos de línea/globales asignados. |
| Precio incluye impuesto | Sí/No a nivel regla o heredado de categoría (ver §6). |
| Redondeo | Ver §7. |
| Imprimible | Si aparece en resumen fiscal del recibo. |
| Activo / vigencia | Independiente dentro del contrato. |

### 4.2 Tipos de impuesto (catálogo, no hardcode)

Valores de referencia Panamá (configurables; no cerrados en código):

| Tipo (ejemplo) | Uso |
|----------------|-----|
| `vat_like` / ITBMS | Impuesto al valor agregado por tasa. |
| `excise` / ISC | Impuesto selectivo (p. ej. licores). |
| `exempt` | Marcador: no genera monto; la línea es exenta. |
| `zero_rated` | Tasa 0% con tracking (si aplica al negocio). |
| `export` | Régimen exportación / no sujeto según política. |
| `internal_consumption` | Consumo interno / no venta (fuera de ticket cobrado). |
| `other` | Extensible. |

**No asumir** que solo existen 7 / 10 / 15. Si mañana aparece otra tasa, se agrega una regla al catálogo.

### 4.3 Ejemplos de reglas (ilustrativos)

| Código | Nombre | Tasa | Notas |
|--------|--------|------|-------|
| `ITBMS_7` | ITBMS 7% | 7% | Bienes/servicios gravados estándar. |
| `ITBMS_10` | ITBMS 10% | 10% | Según categoría del negocio. |
| `ITBMS_15` | ITBMS 15% | 15% | Según categoría del negocio. |
| `EXENTO` | Exento | — | Sin monto. |
| `ISC_LICOR` | ISC Licor | según política | Puede ir **además** de ITBMS. |
| `EXPORT` | Exportación | — | Régimen especial. |

Las tasas exactas legales las define el administrador / EN1; el contrato solo exige que existan como reglas.

---

## 5. Base imponible

Cada regla declara su base:

| Base | Significado |
|------|-------------|
| `line_gross` | Precio × cantidad (antes de descuentos). |
| `line_net` | Tras descuentos de línea. |
| `line_after_allocated_discount` | Tras prorrateo de descuento global / promo. |
| `line_plus_prior_taxes` | Base + impuestos de menor prioridad (compound). |

Reglas por defecto propuestas (congelables en Motor de Totales):

1. Descuentos de línea y globales asignados **antes** de calcular impuestos, salvo que la regla diga lo contrario.
2. Impuestos `parallel` comparten la misma base neta.
3. Impuestos `compound` (p. ej. ISC luego ITBMS sobre base+ISC) respetan `prioridad`.

---

## 6. Precio con impuesto incluido vs excluido

### 6.1 Modo empresa / categoría

El catálogo/producto (o la categoría fiscal) indica si el **precio de lista incluye impuesto**.

| Modo | Comportamiento |
|------|----------------|
| **Excluido** | Precio es neto; impuesto se suma. |
| **Incluido** | Precio es bruto; el motor **extrae** el componente de impuesto para desglose y reportes. |

### 6.2 Extracción (incluido)

Para una tasa \(r\) sobre precio bruto \(P\):

\[
\text{neto} = \frac{P}{1 + r}, \quad \text{impuesto} = P - \text{neto}
\]

Con varios impuestos en paralelo o compound, el Motor de Totales publicará la fórmula exacta y ejemplos. Este contrato **exige** que `taxIncluded=true` **nunca** reporte impuesto = 0 si hay reglas gravadas aplicadas.

---

## 7. Redondeo fiscal

Cada regla (o el contrato) define:

| Política | Opciones |
|----------|----------|
| Precisión | 2 decimales (default comercial PA). |
| Modo | half-up · half-even · toward zero (elegir uno por contrato). |
| Nivel | Por línea · por impuesto agregado · por documento. |

**Propuesta V1:** redondeo **por línea e impuesto** a 2 decimales half-up; el residual de centavos se documenta en Motor de Totales.

---

## 8. Categorías fiscales (producto)

El producto **no** guarda “7%”. Guarda una **categoría fiscal**.

### 8.1 Categoría

| Campo | Descripción |
|-------|-------------|
| Código | Ej. `STD_7`, `LICOR`, `EXENTO`, `SERVICIO`. |
| Nombre | Hamburguesa gravada, Ron, Servicio exento… |
| Reglas asociadas | Lista ordenada de códigos de impuesto del contrato. |
| Precio incluye impuesto | Override opcional. |

### 8.2 Ejemplos

| Producto | Categoría | Reglas |
|----------|-----------|--------|
| Hamburguesa | `STD_7` | `ITBMS_7` |
| Ron | `LICOR` | `ISC_LICOR` + `ITBMS_7` (o la combinación que defina el admin) |
| Servicio | `EXENTO` | `EXENTO` |
| Diesel | `FUEL_X` | Las reglas que el negocio configure |

Si un producto no tiene categoría: **error de catálogo** (no se vende) o categoría default de la sucursal (configurable; debe ser explícita).

---

## 9. Resultado fiscal de una venta (snapshot)

Tras el cálculo, la venta conserva:

### 9.1 Por línea

- Categoría fiscal aplicada (código + versión contrato).
- Cada impuesto: código, nombre, tasa, base, monto, redondeo.

### 9.2 Por documento (agregado)

Agrupación dinámica por código/tasa:

```text
ITBMS 7%     xx.xx
ISC Licor    yy.yy
Exento       (sin monto; opcional conteo)
```

Solo aparecen impuestos con monto ≠ 0, más exentos si la política de recib lo pide.

---

## 10. Reembolsos fiscales

| Caso | Regla |
|------|-------|
| Reembolso total | Invierte todos los montos de impuesto del snapshot original (misma versión). |
| Reembolso parcial | Prorratea o recalcula solo líneas/cantidades devueltas con **las mismas reglas** del snapshot de origen (no el contrato vigente si cambió). |
| Nota de crédito | Documento ligado a la venta origen; el Contrato de Recibo / FE detallará la forma. |

No se “reinterpreta” la venta antigua con el contrato nuevo.

---

## 11. Impresión y reportes

- El Contrato de Recibo consume el **desglose dinámico** de §9.2.
- Caja y reportes agrupan por código de impuesto del snapshot.
- No inventar filas fijas ITBMS 7/10/15 si esa venta no las usó.

---

## 12. Integración con otros contratos

| Contrato | Relación |
|----------|----------|
| Propinas | Si la propina es base o no de impuesto lo define el Contrato de Propinas + Motor de Totales. |
| Pagos | Los impuestos no dependen del método de pago. |
| Recibo | Solo presenta lo calculado. |
| Motor Comercial | Descuentos/promos afectan la base según §5. |

---

## 13. Fuera de alcance V1

- Emisión FE / PAC / CUFE / QR fiscal real.
- Contingencia DGI.
- Multimoneda fiscal avanzada.
- Retenciones / percepciones (se podrán agregar como tipos nuevos).

---

## 14. Criterios de aceptación (documentales)

1. No hay tasas hardcodeadas en la especificación de producto.  
2. Multi-impuesto por línea está definido.  
3. Categoría fiscal es el vínculo producto ↔ reglas.  
4. Tax-included exige extracción/desglose.  
5. Redondeo y prioridad están declarados.  
6. Reembolsos usan snapshot, no contrato futuro.  
7. Dual-mode (mismo modelo, distinto origen) está explícito.

---

## 15. Decisiones abiertas

1. ¿Default de producto sin categoría = bloquear venta o categoría sucursal? **Propuesta: bloquear.**  
2. ¿ISC compound sobre ITBMS o parallel? **Depende de regla; el catálogo lo configura; ejemplo Panamá en Motor de Totales.**  
3. ¿Propina gravada? **Fuera de este contrato; Contrato de Propinas + Totales.**

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Borrador V1: catálogo, categorías, multi-impuesto, incluido/excluido, redondeo, snapshot, reembolsos. |
