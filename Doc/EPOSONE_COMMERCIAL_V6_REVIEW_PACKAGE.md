# Sprint Comercial V6 — Paquete de revisión

| Campo | Valor |
|-------|--------|
| **Fecha** | 19 jul 2026 |
| **Estado** | Borradores listos · **pendiente aprobación** Analista / P1 / P2 |
| **Roadmap** | [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md) |
| **Regla** | Sin código comercial nuevo hasta freeze de este paquete |

---

## 1. Índice de documentos

| Orden | Documento | Archivo | Estado |
|------:|-----------|---------|--------|
| 1 | Modelo Comercial | [`EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md`](EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md) | Borrador |
| 2.1 | Contrato Fiscal | [`EPOSONE_TAX_CONTRACT_V1.md`](EPOSONE_TAX_CONTRACT_V1.md) | Borrador |
| 2.2 | Contrato Propinas | [`EPOSONE_TIP_POLICY_CONTRACT_V1.md`](EPOSONE_TIP_POLICY_CONTRACT_V1.md) | Borrador |
| 2.3 | Contrato Pagos/Reembolsos | [`EPOSONE_PAYMENT_REFUND_CONTRACT_V1.md`](EPOSONE_PAYMENT_REFUND_CONTRACT_V1.md) | Borrador |
| 2.4 | Contrato Impresión | [`EPOSONE_PRINT_CONTRACT_V1.md`](EPOSONE_PRINT_CONTRACT_V1.md) | Borrador |
| 3 | Motor Comercial | [`EPOSONE_COMMERCIAL_ENGINE_SPEC_V1.md`](EPOSONE_COMMERCIAL_ENGINE_SPEC_V1.md) | Borrador |
| 4 | Motor de Totales | [`EPOSONE_TOTALS_ENGINE_SPEC_V1.md`](EPOSONE_TOTALS_ENGINE_SPEC_V1.md) | Borrador |
| 5 | ADR-008 | [`ADR-008-EPOSONE-COMMERCIAL-ENGINE.md`](ADR-008-EPOSONE-COMMERCIAL-ENGINE.md) | Propuesto |

---

## 2. Checklist de aprobación

Marcar por rol. Freeze = todas las filas OK (o decisión abierta explícitamente diferida a v1.1).

### Principios

| # | Pregunta | Analista | P1 | P2 |
|---|----------|:--------:|:--:|:--:|
| A1 | Dual Mode: misma lógica, distinto origen de datos | ☐ | ☐ | ☐ |
| A2 | Standalone puede vivir sin EN1 | ☐ | ☐ | ☐ |
| A3 | Integrado: EN1 source of truth de políticas | ☐ | ☐ | ☐ |
| A4 | Vinculación sin reinstalar | ☐ | ☐ | ☐ |
| A5 | ADR no inventa; solo documenta Fases 1–4 | ☐ | ☐ | ☐ |

### Contratos

| # | Pregunta | Analista | P1 | P2 |
|---|----------|:--------:|:--:|:--:|
| B1 | Fiscal: catálogo, multi-impuesto, sin tasas hardcode | ☐ | ☐ | ☐ |
| B2 | Propinas: none/opcional/sugerida/obligatoria + base | ☐ | ☐ | ☐ |
| B3 | Pagos: mixto, cambio, reembolsos, tenders estructurados | ☐ | ☐ | ☐ |
| B4 | Recibo: plantilla por secciones + snapshot | ☐ | ☐ | ☐ |

### Motores

| # | Pregunta | Analista | P1 | P2 |
|---|----------|:--------:|:--:|:--:|
| C1 | Orden: Pedido→Desc→Promo→Propina→Impuesto→Redondeo→Total | ☐ | ☐ | ☐ |
| C2 | Ejemplos Totales §7 verificables | ☐ | ☐ | ☐ |
| C3 | En divergencia sync gana EN1 | ☐ | ☐ | ☐ |

---

## 3. Decisiones abiertas (cerrar o diferir)

| ID | Tema | Doc | Propuesta | Decisión |
|----|------|-----|-----------|----------|
| O1 | Producto sin categoría fiscal | Tax | Bloquear venta | ☐ OK · ☐ Diferir |
| O2 | Stack promos: prioridad vs mayor descuento | Commercial | Prioridad; empate → mayor desc. | ☐ OK · ☐ Diferir |
| O3 | Tolerancia revalidación EN1 | Totales | 0.01 sync / 0.00 golden | ☐ OK · ☐ Diferir |
| O4 | ISC compound → ITBMS (ej. 7.2) | Totales/Tax | Validar con fiscal PA | ☐ OK · ☐ Diferir |
| O5 | FE pendiente: ¿imprimir? | Print | Leyenda; default sí recibo comercial | ☐ OK · ☐ Diferir |
| O6 | Tip default base post-tax | Tip/Totales | Sí, configurable | ☐ OK · ☐ Diferir |
| O7 | Reembolso tarjeta sin void → efectivo | Pagos | Sí + motivo | ☐ OK · ☐ Diferir |

---

## 4. Tras el freeze

1. Cambiar estado de docs a **v1.0 CONGELADO** + changelog fechado.  
2. ADR-008 → **Aprobado**.  
3. Handoff a P1: implementación motores/políticas EN1.  
4. P2 espera handoff oficial antes de cablear motor en Flutter.  
5. Paralelo P2 (ya permitido): Cajeros tag, Sync E2E, bugs operativos.

---

## 5. Fuera de este paquete

- Código Flutter/EN1 del motor.  
- PAC/FE real.  
- UI Configuración → Comercial.  
- Gift card / depósitos / CxC operativos.

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Índice + checklist + decisiones abiertas para revisión conjunta. |
