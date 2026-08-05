# EPosOne — Instrucción Oficial Sprint V6 (Prog2)

| Campo | Valor |
|-------|--------|
| **Fecha** | 19 jul 2026 |
| **Estado** | Vigente |
| **Audiencia** | Prog2 (EPosOne) |
| **Contexto** | Modelo comercial V6 en congelación ([`EPOSONE_COMMERCIAL_V6_REVIEW_PACKAGE.md`](EPOSONE_COMMERCIAL_V6_REVIEW_PACKAGE.md)) |
| **E2E** | [`EPOSONE_E2E_CHECKLIST_HITO25_V1.md`](EPOSONE_E2E_CHECKLIST_HITO25_V1.md) |
| **Status oficial** | [`EPOSONE_V6_OFFICIAL_STATUS_2026-07-19.md`](EPOSONE_V6_OFFICIAL_STATUS_2026-07-19.md) |

---

## Estado (oficial 19/07/2026)

- Arquitectura Motor Comercial preparada (Facade · `CalculationResult` · Dual Mode · bridges).
- **Sin** reglas V6 hasta freeze (Modelo · Contratos · ADR-008).
- Hito **2.5 Cajeros 95%** — código listo; cierre = E2E A–E en tablet.
- Hito **2.6 Diagnóstico** — iniciado en “Este dispositivo” (APK); multiempresa = EN1.
- Docs Ownership / Standalone-Integrado **después** del E2E.
- Con cierre 2.5 + 2.6 → fin de fase plataforma POS → solo Motor Comercial V6 (post-freeze), salvo correcciones/soporte.

## Objetivo

Preparar EPosOne para consumir el nuevo modelo comercial sin volver a modificar la arquitectura.

Compatibilidad obligatoria:

- **Standalone** (datos locales).
- **Integrado con EN1** (datos sincronizados).

Misma lógica; únicamente cambia el origen de los datos.

## Trabajo autorizado (orden)

### 1. Cerrar Hito 2.5 — E2E tablet

Ejecutar checklist oficial bloques **A–E**. Declarar hito cerrado solo con evidencia en tablet.

### 2. Sync + Offline + pagos mixtos

Cadena: Turno → Pedido → Eventos → Pago (efectivo + mixto) → Recibo → Sync.  
Offline: push sin duplicados · idempotencia.  
Mixto: persistencia · recibo · resumen de turno.

### 3. Hito 2.6 — Diagnóstico APK

Extender “Este dispositivo”:

- Provisioning · último bootstrap · último sync  
- Pendientes / cola · último error  
- Versiones (APK, bootstrap, `cashiers_version`, políticas)  
- Conectividad EN1 · licencia (si hay snapshot)

> Dashboard multi-cliente = EN1, no APK.

### 4. Documentación

- Ownership Matrix de entidades locales  
- Matriz Standalone / Integrado  

### 5. Arquitectura Motor Comercial (ya hecha — mantener)

Capa `commercial_engine` · Facade · `CalculationResult` · Dual Mode · bridges legacy.  
Sin lógica V6 definitiva.

## No implementar todavía

Contratos Fiscal/Propinas/Pagos/Recibo · motores definitivos · promociones nuevas · Back Office EN1 · Gap Analysis V7 backend.

## Criterio de cierre infra base (Prog2)

- [ ] Checklist E2E A–E OK  
- [ ] Hito 2.5 cerrado oficialmente  
- [x] Hito 2.6 diagnóstico usable en soporte (`ca50112`+)  
- [x] Ownership + matriz Dual Mode documentadas (borrador 5 ago 2026)  
- [x] Arquitectura motor lista (ya ✅)  
- [x] ADR-016 Operations Control Center (principio + roadmap; UI Fase A = GO aparte)

Docs:

- [`EPOSONE_OWNERSHIP_MATRIX_V1.md`](EPOSONE_OWNERSHIP_MATRIX_V1.md)  
- [`EPOSONE_STANDALONE_INTEGRATED_MATRIX_V1.md`](EPOSONE_STANDALONE_INTEGRATED_MATRIX_V1.md)  
- [`ADR-016-EPOSONE-OPERATIONS-CONTROL-CENTER.md`](ADR-016-EPOSONE-OPERATIONS-CONTROL-CENTER.md)  
- [`EPOSONE_OCC_SOURCE_INVENTORY_V1.md`](EPOSONE_OCC_SOURCE_INVENTORY_V1.md)

Luego: E2E C–E en tablet · OCC Fase A UI con GO · Sprint V6 Motor Comercial (post-freeze).

---

## Requisitos arquitectónicos (19 jul 2026)

1. `CommercialEngineFacade` es el único punto de entrada para cálculos.
2. Pantallas/widgets no calculan impuestos, propinas, descuentos, promociones,
   settlement, cambio ni total.
3. El motor devuelve un único `CalculationResult` con:
   `subtotal`, `discounts`, `promotions`, `taxes`, `tips`, `rounding`, `total`
   y `detail`.
4. La misma suite de entradas debe producir exactamente el mismo resultado
   usando origen `local` o `en1`.
5. La capa queda preparada para consumidores futuros sin implementar reglas V6 definitivas.

### Estado de preparación

- UI POS, cobro, split, pre-cuenta, cupones y pago mixto delegan al facade.
- Recomputación de Pedido delega al facade.
- Bridges `legacy_*` preservan la conducta actual hasta el freeze.
- Prueba de paridad Standalone/Integrado creada.
- Cajeros: CRUD local, PIN PBKDF2, cambio de cajero, turno↔cajero, bootstrap versionado.

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Instrucción oficial registrada en Doc. |
| 2026-07-19 | Facade único, `CalculationResult`, UI desacoplada y parity tests. |
| 2026-07-19 | Analista: checklist E2E A–E, Cajeros 95%, Hito 2.6 diagnóstico, docs ownership. |
| 2026-07-19 | Actualización oficial EPosOne V6 registrada (`EPOSONE_V6_OFFICIAL_STATUS_2026-07-19`). |
