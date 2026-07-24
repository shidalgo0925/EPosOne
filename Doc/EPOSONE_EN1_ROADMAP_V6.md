# Roadmap EPosOne + EN1 V6 — Sprint Comercial

**Fecha del sprint:** 19 jul 2026  
**Estado:** borradores Fases 1–5 listos · **paquete de revisión** pendiente aprobación  
**Actualización oficial:** [`EPOSONE_V6_OFFICIAL_STATUS_2026-07-19.md`](EPOSONE_V6_OFFICIAL_STATUS_2026-07-19.md)  
**Regla:** Prog2 no implementa lógica comercial hasta que ADR y contratos estén aprobados y congelados.  
**Revisión contratos:** [`EPOSONE_COMMERCIAL_V6_REVIEW_PACKAGE.md`](EPOSONE_COMMERCIAL_V6_REVIEW_PACKAGE.md)  
**Instrucción Prog2 (vigente):** [`EPOSONE_V6_PROG2_OFFICIAL_INSTRUCTION.md`](EPOSONE_V6_PROG2_OFFICIAL_INSTRUCTION.md) — operativo + arquitectura; **sin** lógica comercial nueva.  
**Checklist E2E:** [`EPOSONE_E2E_CHECKLIST_HITO25_V1.md`](EPOSONE_E2E_CHECKLIST_HITO25_V1.md) (bloques A–E)

**Principio dual-mode:** misma lógica de negocio en Standalone e Integrado. La diferencia es únicamente el origen de los datos (local vs EN1).

**Cierre de plataforma:** al completar Hito 2.5 (E2E) + Hito 2.6, EPosOne cierra infraestructura base y pasa a fase de reglas de negocio (Motor V6 post-freeze).

---

## 1. Estado de entrada (oficial 19/07/2026)

### Arquitectura Motor Comercial

| Pieza | Estado |
|-------|--------|
| `commercial_engine` · Facade · `CalculationResult` · Dual Mode · bridges legacy | ✅ |
| Reglas V6 | ⏳ Freeze Modelo + Contratos + ADR-008 |

### Hito 2.5 — Cajeros · 🟡 95%

Implementado en código: CRUD local · PIN PBKDF2 · login · cambio de cajero · Cajero↔Turno · bootstrap `cashiers_version` · sync · bloqueo inactivos.

**Cierre oficial:** ⏳ E2E tablet checklist A–E.

### Hito 2.6 — Diagnóstico · 🟡 Iniciado (APK)

“Este dispositivo”: provisioning · bootstrap · sync · cola · versiones · licencia · soporte básico.  
Observabilidad multiempresa = **EN1**.

### Documentación (después de E2E)

Ownership Matrix · Matriz Standalone / Integrado.

### Sync / cadena operativa · 🟡

Validar en tablet vía checklist A–E (Pedido · Pago · Offline · Idempotencia incluidos).

### EN1 (contexto, no Prog2)

~85–90% infra BO; falta producto administrable (políticas UI, reportes, dashboard).

---

## 2. Objetivo del Sprint Comercial

Cerrar el **modelo comercial único** de EPosOne para que funcione igual en:

- **Standalone** (origen: SQLite local; POS administra).
- **Integrado con EN1** (origen: EN1; BO administra y sincroniza).

Vinculación posterior: cutover sin reinstalar.

No se desarrollará código comercial nuevo hasta congelar Fases 1–4.

---

## 3. Orden oficial (Analista · aprobado)

### Fase 1 — Modelo Comercial (primero)

**Archivo:** [`Doc/EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md`](EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md) — **borrador 19 jul · pendiente aprobación Analista/P1/P2**

### Fase 2 — Contratos

| # | Contrato | Archivo |
|---|----------|---------|
| 2.1 | Fiscal | [`Doc/EPOSONE_TAX_CONTRACT_V1.md`](EPOSONE_TAX_CONTRACT_V1.md) — **borrador 19 jul** |
| 2.2 | Propinas | [`Doc/EPOSONE_TIP_POLICY_CONTRACT_V1.md`](EPOSONE_TIP_POLICY_CONTRACT_V1.md) — **borrador 19 jul** |
| 2.3 | Pagos | [`Doc/EPOSONE_PAYMENT_REFUND_CONTRACT_V1.md`](EPOSONE_PAYMENT_REFUND_CONTRACT_V1.md) — **borrador 19 jul** |
| 2.4 | Recibo | [`Doc/EPOSONE_PRINT_CONTRACT_V1.md`](EPOSONE_PRINT_CONTRACT_V1.md) — **borrador 19 jul** |

### Fase 3 — Motor Comercial

**Archivo:** [`Doc/EPOSONE_COMMERCIAL_ENGINE_SPEC_V1.md`](EPOSONE_COMMERCIAL_ENGINE_SPEC_V1.md) — **borrador 19 jul**

### Fase 4 — Motor de Totales

**Archivo:** [`Doc/EPOSONE_TOTALS_ENGINE_SPEC_V1.md`](EPOSONE_TOTALS_ENGINE_SPEC_V1.md) — **borrador 19 jul**

### Fase 5 — ADR-008

**Archivo:** [`Doc/ADR-008-EPOSONE-COMMERCIAL-ENGINE.md`](ADR-008-EPOSONE-COMMERCIAL-ENGINE.md) — **propuesto 19 jul · pendiente aprobación**

---

## 4. Después comienza el desarrollo (post-freeze)

1. Contrato Fiscal → Propinas → Pagos → Recibo  
2. Motor Comercial → Motor de Totales  
3. Implementación EPosOne + EN1  
4. Sync de políticas · E2E comercial  

---

### Trabajo Prog2 autorizado (mientras congelan contratos)

| # | Trabajo | Estado |
|---|---------|--------|
| 1 | Hito 2.5 Cajeros (código) | ✅ · ⏳ E2E tablet |
| 2 | Validar Sync E2E + Offline + idempotencia | 🟡 Checklist A–E |
| 3 | Pagos mixtos (persistencia · recibo · reporte) | 🟡 Confirmar E2E |
| 4 | Hito 2.6 Diagnóstico APK | 🟡 Extender “Este dispositivo” |
| 5 | Ownership + matriz Standalone/Integrado | ⏳ Docs |
| 6 | Capa `commercial_engine` | ✅ Sin reglas V6 definitivas |
| 7 | UI desacoplada + Dual Mode | ✅ |

**Prohibido hasta freeze:** lógica Fiscal/Propinas/Pagos/Recibo/Totales V6 definitiva.

**Fuera de Prog2 (EN1):** Back Office comercial, pantallas de políticas, reportes gerenciales, dashboard multi-dispositivo, Gap Analysis V7 backend, Hito Administración Sistema SaaS.

---

## 6. Criterio de cierre documental

- Modelo Comercial V1 aprobado.  
- Cuatro contratos V1 congelables.  
- Spec Motor Comercial + Spec Motor de Totales con ejemplos Panamá.  
- ADR-008 redactado **después**, alineado a lo anterior.  
- Ownership dual-mode explícito.  
- Sin código comercial disperso en APK.

---

## 7. Regla del Sprint

A partir del 19 jul 2026 no se desarrollará ninguna funcionalidad comercial nueva sin contrato funcional aprobado.

EPosOne y EN1 compartirán un único modelo comercial. Standalone vs Integrado solo cambia el origen de los datos.

---

## 8. Fuera de alcance hasta freeze Fases 1–4

- Implementación Flutter/EN1 del nuevo motor.  
- Rediseño final del recibo · PAC / FE real.  
- Configuración → Comercial.  
- Gift Card / CxC / cortesías operativas.

---

## 9. Orden de trabajo inmediato (Prog2)

| # | Entregable | Estado |
|---|------------|--------|
| 1 | Ejecutar checklist E2E A–E en tablet | ⏳ |
| 2 | Cerrar oficialmente Hito 2.5 | ⏳ |
| 3 | Hito 2.6 Diagnóstico APK | 🟡 |
| 4 | Ownership Matrix + Standalone/Integrado | ⏳ |
| 5 | Freeze contratos V6 → Sprint Motor | ⏳ Analista/P1 |

---

## Changelog roadmap

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Roadmap V6 creado · docs comerciales borrador |
| 2026-07-19 | Analista: Cajeros 95%, E2E A–E, Sync, Hito 2.6, docs ownership; EN1 vs EPosOne gaps |
| 2026-07-19 | Actualización oficial EPosOne V6 — cierre plataforma tras 2.5+2.6; Motor V6 post-freeze |
