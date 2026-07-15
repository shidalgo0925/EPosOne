# Hito 3B.1 — Sprint UX-01 (P2)

| Campo | Valor |
|-------|--------|
| Estado | ✅ Cerrado P2 (15 jul 2026) — E2E checklist = 3C |
| Contrato | Sin cambios — Order Domain v1.0 congelado |
| EN1 | No modificado |

## Entregado

1. Guardar pedido: progress → local → Order Domain + sync inmediato → cierra tickets → snackbar
2. Overlay bloqueante (`BlockingProgressOverlay`)
3. Auto-sync cada 30s solo si `dirty` / cola pendiente
4. Sync inmediato: guardar, cobrar, anular (borrar ticket), mutations OrderService
5. Ciclo de vida completo (pedido nace al Guardar, no solo al cobrar)
6. `Order.dirty` + clear tras sync OK
7. Chip EN1 en AppBar POS (conectado / offline / syncing)
8. Cola sync agrupada: Pendientes / Sincronizando / Completado / Error (errores no se borran)

## Fuera de alcance (OK)

Inventario, Kardex, FE, KDS, caja avanzada — siguiente hito.
