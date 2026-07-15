# Hito 3 — Dominio Operativo del Pedido · Notas (histórico)

> **Superseded por:** [`EPOSONE_EN1_ROADMAP_V5.md`](EPOSONE_EN1_ROADMAP_V5.md)  
> **Estado:** Hito 3 = dominio EN1 (P1). Hito 4 = operación APK (P2).  
> **Código:** congelado hasta **Order Domain Specification v1.0**.

**Fecha original:** 14 de julio de 2026  
**Decisión previa:** [`EPOSONE_EN1_DECISION_OPERATION_VS_ADMIN.md`](EPOSONE_EN1_DECISION_OPERATION_VS_ADMIN.md)  
**Bitácora:** [`EPOSONE_EN1_INTEGRATION_LOG.md`](EPOSONE_EN1_INTEGRATION_LOG.md)

---

## Split V5

| Hito | Responsable | Contenido |
|------|-------------|-----------|
| **3** | **P1 EN1** | Order Domain + APIs (sin inventario) |
| **4** | **P2 EPosOne** | Acciones POS sobre contrato congelado |

Orden: Spec → P1 → congelar → P2 → E2E → Inventario (H5) → Caja (H6) → FE (H7).

---

## Criterio de cierre E2E (H3+H4)

1. Crearse en un POS  
2. Modificarse  
3. Sincronizarse  
4. Visible en EN1 / BackOffice  
5. Cobrarse desde otro POS o BO  
6. Historial de eventos  
7. Sin conflictos (Ownership)

---

## P1 (resumen)

Entidades: Order, OrderItem, OrderPayment, OrderEvent, OrderCancellation, OrderReturn.  
APIs solo Pedido. Ver Roadmap V5.

## P2 (después)

No inventar reglas. Consumir contrato. Core / Provisioning / Bootstrap 🔒.

---

*Ver fuente viva: Roadmap V5*
