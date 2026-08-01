# EPosOne — Modelo Operacional de Eventos de Pedido (Local)

| Campo | Valor |
|-------|--------|
| Estado | Implementado APK · 28 jul 2026 |
| Contrato HTTP | [`EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`](EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md) |
| Spec | [`EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md`](EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md) |

---

## Reglas

| Estado | Eliminar físico | Acción |
|--------|-----------------|--------|
| Ticket **sin** Order Domain (borrador) | ✔ Descartar | Borrado local del ticket |
| Pedido confirmado (`open` / `sent` / …) | ✘ | **Cancelar** → `pedido.anulado` + `lifecycle=cancelled` |
| Cobrado / cerrado | ✘ | Reembolso → `pedido.devuelto` |

Nadie elimina físicamente un Order Domain confirmado.

---

## Eventos (tipos contrato — no inventar)

`pedido.creado` · `pedido.actualizado` · `producto.*` · `pedido.enviado` · `pedido.cobrado` · **`pedido.anulado`** · **`pedido.devuelto`**

Auditoría en `payload`: `reason`, `origin` (`EPOSONE`\|`EN1`\|`SYSTEM`), caja, dispositivo, turno, `created_by`.

---

## Flujo cancelación

```text
UI (motivo) → cancelOrder → OrderEvent(pedido.anulado) → status cancelled
  → cola Sync → POST /orders/{id}/events → ACK → SYNCED
```

Offline-first: la operación no espera EN1.

---

## UI

- Tickets abiertos: **Descartar** (borrador) vs **Cancelar pedido** (confirmado + motivo).
- Lista Pedidos EN1: cancelados visibles con motivo / actor; no desaparecen.
- Recepción EN1: `ingestRemoteEventsFromOrderJson` al GET con `include=events`.

---

## Pendiente (roles)

Permisos Supervisor/Admin formales viven en EN1/Portal. Local exige **motivo** obligatorio; gate de rol = futuro.
