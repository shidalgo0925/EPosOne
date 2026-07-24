# Roadmap EN1 + EPosOne V5

> **Superado para el Sprint Comercial por:** [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md).  
> V5 se conserva como registro del cierre técnico anterior.

**Actualizado:** 18 jul 2026 (noche)  
**Cierre de sesión P2:** UX-01 + Hito 3B.1 · Sync cliente listo · **fix recibo multi-ítem + back** · **pausa features → Motor Comercial (docs 19 jul)**

| Hito | Estado | Quién |
|------|--------|-------|
| 1 Provisioning | ✅ | |
| 2 Bootstrap | ✅ | |
| **2.5 Cajeros + Turno POS** | 🟡 EN1 Dev ✅ · APK P2 con PIN/bootstrap/`cashier_contact_id` · handoff OFICIAL (tag) pendiente P1 | P1 ✅ código · P2 |
| 3A Dominio + Contrato | ✅ | P1 |
| 3B Operación Flutter | ✅ (cliente) | P2 |
| UX-01 + 3B.1 Operación Pedido | ✅ | P2 |
| **3C Sync** | 🟡 Cliente listo · E2E/pruebas en tablet | P2 ejecuta checklist · P1 verifica BO |
| 4 Inventario | ⏸ hasta Sync E2E OK | |
| **Comercial / Licencias** | 🟡 ADR-007 aprobado · contrato License P1 pendiente | P1 License Manager · P2 tras handoff |
| **Motor Comercial (nuevo)** | 🟡 **Agenda 19 jul** — ADR-008 + 4 contratos (docs only) | P2 redacta · P1 alinea EN1 |

### Hito 2.5 — Cajeros (18 jul 2026)

Fuentes:

- [`Doc/EN1_EPOSONE_HITO25_CASHIER_CONTRACT.md`](EN1_EPOSONE_HITO25_CASHIER_CONTRACT.md)  
- [`Doc/EN1_EPOSONE_HITO25_CASHIER_SPEC_FUNCIONAL_V1.md`](EN1_EPOSONE_HITO25_CASHIER_SPEC_FUNCIONAL_V1.md)

- PIN: hash+sal · `pin_verifier` en bootstrap/sync · nunca plano.  
- Bloque `cashiers` + `cashiers_version` en bootstrap existente.  
- Turno normal desde POS; BO = excepción.  
- **Prog2 no cablea HTTP** hasta handoff OFICIAL (changelog + commit/tag).  
- **Nota:** checkout backend EN1 no está en este workspace; implementación código = sesión/repo P1.

### ADR comercial (18 jul 2026)

Fuente: [`Doc/ADR-007-EPOSONE-COMMERCIAL-LICENSING.md`](ADR-007-EPOSONE-COMMERCIAL-LICENSING.md)

- Licencia en **Caja** · trial 45d · pago→EN1→sync (sin códigos).  
- Offline + Grace Window · licencia como atributo del protocolo · heartbeat.  
- P2: License Store local solo tras contrato congelado.

### Agenda 19 jul 2026 — Motor Comercial (docs only · P2)

**Decisión:** pausar features aisladas (recibo “bonito”, más pantallas). Cerrar primero el **modelo comercial común** EN1 ↔ EPosOne. Implementación de código **después** de freeze + alineación P1.

**Entrada (análisis 18 jul):** recibo panameño = patrón estructural (secciones), no copia 1:1. Gap real = motor de cálculo + contratos, no UI.

| # | Entregable | Archivo objetivo | Contenido mínimo |
|---|------------|------------------|------------------|
| 1 | ADR-008 Motor Comercial | `Doc/ADR-008-EPOSONE-COMMERCIAL-ENGINE.md` | Orden de cálculo único; ownership EN1↔POS; anti-duplicación; aplica POS/APIs/reportes/impresión |
| 2 | Contrato Impuestos | `Doc/EPOSONE_TAX_CONTRACT_V1.md` | Catálogo (ITBMS multi-tasa, ISC, exento…); multi-impuesto por línea; extracción si precio incluye impuesto; breakdown dinámico |
| 3 | Contrato Propinas | `Doc/EPOSONE_TIP_POLICY_CONTRACT_V1.md` | No aplica / voluntaria / sugerida / automática; base; impresión separada de impuestos |
| 4 | Contrato Impresión Recibo | `Doc/EPOSONE_PRINT_RECEIPT_CONTRACT_V1.md` | Plantilla por secciones; snapshot DTO; caja·cajero·turno; cliente; tenders; QR configurable; 58/80 mm |
| 5 | Contrato Pagos/Reembolsos | `Doc/EPOSONE_PAYMENT_REFUND_CONTRACT_V1.md` | Multi-tender persistido en venta; cambio; reembolso total/parcial/por tender |

**Orden de cálculo a congelar en ADR-008:**

`Subtotal → Desc. línea → Desc. global → Base gravable → Impuestos → Recargos → Propinas → Total → distribución pagos → reembolsos`

**Fuera de alcance 19 jul (fase 2):** depósitos, gift cards operativos, cortesías, CxC, facturación posterior, recargo hotel, delivery/empaque, implementación Flutter del motor o del renderer.

**Criterio de cierre del día:** 5 borradores en `Doc/` listos para revisión conjunta P1; **sin** cambiar APK salvo bugs bloqueadores de prueba.

**Gaps conocidos que el motor debe resolver (no “parche UI”):**

- `taxIncluded` reporta ITBMS = 0 en totales/recibo.  
- Cupón se pierde al completar venta.  
- `Sale` no guarda tenders estructurados (mixto solo en notes).  
- Recibo actual sin columnas / impuestos dinámicos / QR / caja·turno.

## Hecho en P2 (cierre 15 jul 2026)

### Order Domain (Hito 3B / cliente 3C)
- Pedidos EN1: crear / guardar / modificar / cobrar / anular / cerrar sobre contrato congelado.
- Cobro POS → Order Domain (`createPaidOrderFromPosSale`); ticket abierto puede enlazar `linkedOrderLocalId`.
- Push legacy **Sale** desactivado: no se encola, no ensucia historial; mensaje apunta a Pedidos EN1.
- `dirty` en `Order`: true al modificar; false tras sync OK.
- Cola Order + `flushPendingToEn1` + sync inmediato en eventos de ciclo de vida.
- Auto-sync cada 30 s solo si hay trabajo pendiente y hay enlace EN1.
- Chip estado EN1 en POS (conectado / offline / sincronizando + pendientes).
- Overlay bloqueante en guardar pedido; cierre automático hoja Tickets + snackbar.
- Cola Sync UI: Pendientes · Sincronizando · Completado · Error (errores no se borran solos).

### Bootstrap / catálogo
- Páginas POS **Comida** / **Bar** reconstruidas desde categorías EN1.
- `isActive` robusto (Activo/Inactivo ES/EN).
- Handoff menú Istmo Brew para import en EN1: `Doc/EN1_HANDOFF_ISTMO_MENU/` (+ `tools/export_istmo_catalog_for_en1.py`).

### Contratos (fuente única — no reabrir)
- `Doc/EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`
- `Doc/EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md`
- Regla handoff: `.cursor/rules/en1-handoff.mdc` · `Doc/EPOSONE_EN1_HANDOFF_RULE.md`

## Pendiente inmediato

### A — 19 jul: Motor Comercial (prioridad docs)
Ver sección **Agenda 19 jul 2026** arriba. Bloquea rediseño de recibo e impuestos avanzados.

### B — Cierre Hito 3C (paralelo / no bloquear A)

1. **Validación Funcional V1.0 — módulo Pedido** (método ETS): [`Doc/ETS_PRODUCT_VALIDATION_METHOD_V1.md`](ETS_PRODUCT_VALIDATION_METHOD_V1.md). Operación real, no botones. Hallazgos: Bloqueador RC · Mejora UX · Backlog.
2. Confirmación P1: pedidos visibles en BackOffice EN1 sin duplicados (Casos 8–10).
3. Diagnóstico: versión APK, contrato, último sync, pendientes, token/caja/dispositivo.
4. Limpieza técnica previa a piloto solo para **Bloqueadores RC** del sprint Pedido.
5. **Congelar POS Core** — sin nuevas pantallas/flujos comerciales hasta freeze ADR-008 + contratos.

### Zona horaria (paralelo a 3C)

| Ítem | Estado |
|------|--------|
| **Fase 1 cliente** — UTC persist + format EN1 + drift vía `Date` + auditoría | ✅ Implementada (`Doc/EPOSONE_TIMEZONE_POLICY_V1.md`) |
| **Fase 2** — register diagnostics + bootstrap org.timezone + heartbeat `server_time` | ⏸ Esperando P1 (`Doc/EPOSONE_EN1_TIMEZONE_CONTRACT_DELTA_REQUEST.md`) |

**No reabrir** contratos Order / Provisioning / Bootstrap hasta respuesta P1 al delta.

## No implementar aún
Inventario · Kardex · Recetas · Compras · Transferencias · Facturación electrónica real (PAC) · CxC · KDS · Menú QR · Delivery · Fidelización · Multi-POS · License Store · **renderer de recibo nuevo** · **motor de impuestos multi-tasa en código** — hasta freeze docs 19 jul + acuerdo P1.

## Referencias de estado
- `Doc/EPOSONE_EN1_HITO3B1_UX01_STATUS.md`
- `Doc/EPOSONE_EN1_HITO3B_HANDOFF_STATUS.md`
- `Doc/EPOSONE_EN1_INTEGRATION_LOG.md`
