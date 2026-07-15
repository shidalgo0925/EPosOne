# Hito 3B — Contrato recibido · HTTP en curso

**Estado:** 4 Aceptado · implementación HTTP activa  
**Fecha:** 14 jul 2026

## Confirmación P2

> Documentos recibidos. Comienzo implementación HTTP.

Archivos en `Doc/`:

- [`EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`](EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md)
- [`EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md`](EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md)

Handoff: [`EPOSONE_EN1_HITO3B_HANDOFF_STATUS.md`](EPOSONE_EN1_HITO3B_HANDOFF_STATUS.md)

## Implementado

- `En1OrdersApi` — Bearer + POST/GET/PATCH orders · events · payments · split  
- `OrderMapper` — bodies/responses según contrato  
- `OrderService.syncOrderToEn1` / `flushPendingToEn1` — offline-first + cola `SyncEntityKind.order`  
- UI `/settings/orders`

## Siguiente

Cablear acciones desde POS Core (cart) cuando se valide flujo · E2E = Hito 3C.
