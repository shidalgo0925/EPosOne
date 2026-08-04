# EPosOne — Modelo Operacional de Eventos de Pedido (Local)

| Campo | Valor |
|-------|--------|
| Estado | Implementado APK · actualizado 4 ago 2026 (Cancelar / Anular / Reembolsar) |
| Contrato HTTP | [`EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`](EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md) |
| Spec | [`EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md`](EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md) |

---

## Principio (cerrado)

Un **Order Domain** nunca se elimina físicamente. Solo cambia de estado y genera eventos.

---

## Reglas P0 (UI / negocio)

| Situación | Botón | Estado local | Evento EN1 |
|-----------|-------|--------------|------------|
| Ticket sin Order (borrador) | Descartar | — (borra ticket local) | — |
| Confirmado, **pre-cocina** (`open` / `confirmed`) | **Cancelar** | `cancelled` | `pedido.anulado` |
| **Post-cocina** (`sent` … `delivered`) | **Anular** | `voided` | `pedido.anulado` (mismo contrato) |
| Cobrado (`paid` / `completed` / `closed`) | **Reembolsar** | `refunded` | `pedido.devuelto` |

Nunca mostrar **Eliminar** sobre un Order confirmado.

`voidOrder()` y `cancelOrder()` comparten el evento HTTP `pedido.anulado`; difieren en estado local y copy de UI. Un posible `pedido.voided` en EN1 = **P1** (no tocar contrato ahora).

---

## Pipeline cocina

Estados `sent` / `preparing` / `ready` / `delivered` **no se rediseñan en P0**. Solo alimentan la regla Cancelar vs Anular.

---

## Flujo cancelación / anulación

```text
UI (motivo) → cancelOrder | voidOrder → OrderEvent(pedido.anulado)
  → lifecycle cancelled | voided → cola Sync → POST .../events
```

Offline-first: la operación no espera EN1.

---

## UI

- Tickets abiertos: Descartar · Cancelar · Anular según estado.
- Lista Pedidos EN1: acción según `OrderLifecycle.abortAction`.
- Cancelados / anulados visibles con motivo; no desaparecen.

---

## Pendiente P1

- ADR cocina + máquina de estados definitiva.
- Supervisor / autorización.
- Auditoría completa estado anterior → nuevo.
- Decidir si VOIDED requiere evento EN1 propio.
- Reportes: excluir CANCELLED/VOIDED de ventas (ajuste fino).
