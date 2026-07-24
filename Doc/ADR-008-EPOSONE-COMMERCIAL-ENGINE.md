# ADR-008 — Motor Comercial Dual-Mode (Standalone ↔ EN1)

| Campo | Valor |
|-------|--------|
| **Estado** | Propuesto — pendiente aprobación Analista / P1 / P2 |
| **Fecha** | 19 jul 2026 |
| **Sprint** | Comercial V6 |
| **Audiencia** | Analista · P1 (EN1) · P2 (EPosOne) · Producto |
| **Principio rector** | *Toda regla de negocio se implementa una sola vez. Standalone vs Integrado solo cambia el origen de los datos.* |
| **No inventa** | Este ADR **documenta** decisiones de Fases 1–4; no las descubre. |

### Fuentes (ya redactadas)

| Fase | Documento |
|------|-----------|
| 1 | [`EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md`](EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md) |
| 2.1 | [`EPOSONE_TAX_CONTRACT_V1.md`](EPOSONE_TAX_CONTRACT_V1.md) |
| 2.2 | [`EPOSONE_TIP_POLICY_CONTRACT_V1.md`](EPOSONE_TIP_POLICY_CONTRACT_V1.md) |
| 2.3 | [`EPOSONE_PAYMENT_REFUND_CONTRACT_V1.md`](EPOSONE_PAYMENT_REFUND_CONTRACT_V1.md) |
| 2.4 | [`EPOSONE_PRINT_CONTRACT_V1.md`](EPOSONE_PRINT_CONTRACT_V1.md) |
| 3 | [`EPOSONE_COMMERCIAL_ENGINE_SPEC_V1.md`](EPOSONE_COMMERCIAL_ENGINE_SPEC_V1.md) |
| 4 | [`EPOSONE_TOTALS_ENGINE_SPEC_V1.md`](EPOSONE_TOTALS_ENGINE_SPEC_V1.md) |
| Roadmap | [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md) |

Relacionados: Operación vs Admin · Order Domain · ADR-007 Licenciamiento.

---

## 1. Contexto

EPosOne ya opera pedidos, cobro mixto, cajeros, sync y offline. El riesgo era seguir añadiendo reglas comerciales dispersas en Flutter o solo en EN1.

El Analista ordenó: **modelo → contratos → motores → ADR**.  
P1/P2 acordaron: **misma lógica**, origen Local o EN1.

---

## 2. Decisión

### 2.1 Dual Mode oficial

EPosOne tiene dos modos de operación:

| Modo | Origen de maestros y políticas | Quién administra |
|------|--------------------------------|------------------|
| **Standalone** | Base local (SQLite) | Admin en el POS |
| **Integrado** | EN1 (source of truth) | BackOffice EN1; POS aplica snapshot |

**Vinculación:** un negocio puede pasar de Standalone a Integrado con asistente de cutover, **sin reinstalar** ni cambiar la forma de trabajar.

### 2.2 Una sola lógica de negocio

| Componente | Dónde vive la lógica | Dónde vive la config |
|------------|----------------------|----------------------|
| Motor Comercial | Mismo algoritmo (spec) | Políticas local o EN1 |
| Motor de Totales | Mismo algoritmo (spec) | — |
| Contratos Fiscal / Propina / Pagos / Recibo | Mismo modelo | Políticas local o EN1 |

No existen “dos POS” ni reglas distintas por modo.

### 2.3 Motor de políticas comerciales

Los contratos no son pantallas aisladas: son **tipos de política versionada**, asignables por:

```text
Empresa → Sucursal → Caja
```

(La más específica gana, salvo regla explícita en contrario.)

Tipos V1: Fiscal · Propinas · Pagos · Impresión · (reglas del Motor Comercial).

### 2.4 Orden de cálculo (Motor de Totales)

```text
Pedido → Descuentos → Promociones → Propinas → Impuestos → Redondeos → Total
```

Detalle, redondeo half-up 2 decimales, passthrough tip post-tax y ejemplos Panamá: spec Totales.

### 2.5 Offline first

El POS **siempre** calcula en local para vender sin Internet.

En Integrado, EN1 **revalida** al sync con el mismo algoritmo. Ante divergencia: gana EN1; se registra y notifica (tolerancia según Totales).

### 2.6 Snapshot inmutable

Cobro e impresión consumen un **snapshot** de totales, impuestos, propina y tenders. No se recalcula al reimprimir. Reembolsos usan el snapshot de origen.

### 2.7 Responsabilidades

| Actor | Responsabilidad |
|-------|-----------------|
| **EPosOne** | Operación: pedido, cobro, impresión, turno, offline, eventos, sync. En Standalone: admin de políticas/maestros. En Integrado: no edita políticas maestro. |
| **EN1** | En Integrado: source of truth de catálogo, políticas, validación de totales, reportes, auditoría, licenciamiento de caja. |
| **Analista** | Congela modelo y contratos antes de código. |
| **P1** | Implementa motores/políticas en EN1 tras freeze + handoff. |
| **P2** | Implementa el mismo algoritmo en el cliente tras freeze + handoff; paralelo operativo (Sync/Cajeros) sin lógica comercial nueva. |

### 2.8 Qué se rechaza

| Rechazado | Motivo |
|-----------|--------|
| EN1 como único lugar de reglas | Rompe Standalone y trial/APK pública. |
| Lógica distinta Standalone vs Integrado | Doble mantenimiento. |
| ADR antes del modelo de negocio | El ADR no debe descubrir reglas. |
| Tasas/propinas hardcode en UI | Deben vivir en políticas. |
| Código comercial nuevo antes de freeze Fases 1–4 | Riesgo de reescritura. |
| Recibo como formato fijo único | Plantilla por secciones. |

---

## 3. Consecuencias

### Positivas

- Un comercio puede empezar solo y crecer a EN1 sin cambio de producto.
- Cambios legales/comerciales = nueva versión de política, no forks de código.
- Golden tests compartidos (ejemplos Totales) para P1 y P2.

### Costos

- Hay que implementar el motor en **ambos** runtimes (Dart y EN1) con disciplina de parity.
- Admin local de políticas en Standalone (UI Configuración → Comercial) es trabajo real.
- Sync de políticas y cutover Standalone→Integrado son proyectos explícitos post-freeze.

### Implícito para desarrollo

Orden post-aprobación (V6):

1. Fiscal → 2. Propinas → 3. Pagos → 4. Recibo → 5. Motor Comercial → 6. Motor Totales → 7. EPosOne → 8. EN1 → 9. Sync políticas → 10. E2E.

Hasta freeze: **sin** código comercial nuevo en APK.

---

## 4. Versionado

| Artefacto | Versionado |
|-----------|------------|
| Este ADR | Aprobación = estado **Aprobado**; cambios = ADR-008bis o enmienda fechada |
| Contratos / specs | `v1.0` al freeze; breaking = `v1.1+` con GO |
| Snapshot de venta | Guarda códigos + versiones de políticas aplicadas |
| Motor | Identificador de algoritmo (ej. `totals-engine-v1`) en el snapshot |

---

## 5. Criterio de aceptación del ADR

- Analista confirma que no añade reglas nuevas respecto a Fases 1–4.
- P1 y P2 confirman ownership Dual Mode y orden de implementación.
- Decisiones abiertas de los borradores se resuelven o se listan explícitamente fuera de V1.
- Estado pasa a **Aprobado** → habilita desarrollo comercial según V6 §4.

---

## 6. Decisiones abiertas heredadas (no cerradas por este ADR)

Se mantienen en sus docs origen; el ADR no las inventa:

- Producto sin categoría fiscal: ¿bloquear? (Tax)
- Conflicto stack de promos (Commercial Engine)
- Tolerancia revalidación 0.00 vs 0.01 (Totales)
- Compound ISC→ITBMS ejemplo 7.2 vs regla fiscal PA real
- FE pendiente: ¿imprimir con leyenda? (Print)

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Propuesto: Dual Mode, políticas, motores, ownership, rechazos, consecuencias. |
