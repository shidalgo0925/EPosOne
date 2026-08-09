# LOCAL — Auditoría + fix: turnos/cierres EP1 → EN1

| Campo | Valor |
|-------|--------|
| Fecha | 2026-08-08 |
| Prioridad | P2 — sync real Cash Shift HTTP v1 |
| Commits | push master Standalone previo + este fix |

## Causa raíz (código)

1. **Auto-sync 30s solo flusheaba pedidos** (`flushPendingToEn1`). Las ops `SyncEntityKind.cashRegister` quedaban en cola y **nunca se reintentaban** tras un fallo del `runSyncCycle` one-shot.
2. **`hasPendingWork`** ignoraba `cashRegister` → el keeper ni siquiera despertaba solo por turnos pendientes.
3. **`enqueueIfReady`** podía no-op sin log si faltaba `cashier_contact_id` (PIN local sin catálogo EN1).
4. Errores de `runSyncCycle` tras open/close: `catch (_) {}` silencioso.

Contrato HTTP v1 ya estaba implementado (`En1CashShiftApi` + `CashShiftSyncService`). No se reactivó sync legado.

## Fix aplicado

| Cambio | Archivo |
|--------|---------|
| `hasPendingWork` incluye `cashRegister` | `order_service.dart` |
| Auto-sync 30s llama `runSyncCycle` tras flush pedidos | `en1_connection_status.dart` |
| Logs en skip/enqueue/OPEN/CLOSE OK | `cash_shift_sync_service.dart` |
| Re-enqueue si reingreso sin `serverId` | `cash_open_screen.dart` |
| PIN EN1 + turno abierto sin `shift_id` → enqueue OPEN | `pin_screen.dart` |
| `catch` con `debugPrint` | notifier / open |

## E2E requerido (evidencia)

No dar por cerrado sin:

1. Abrir caja EP1 (cajero EN1 con `cashier_contact_id`)  
2. EN1: turno `open`, mismo `client_shift_id`  
3. Vender  
4. Cerrar con contado en EP1  
5. EN1: mismo turno `closed` + OCC Cierres  
6. Offline close → reconnect → un solo close  
7. Segundo close sin duplicar  
8. Día siguiente → nuevo turno  

Formato evidencia:

```text
EP1: client_shift_id=…, cajero=…, open=…, close=…, counted=…
EN1: client_shift_id=…, same cashier, closed, same amounts/timestamps
```

## Nota UI (fase 2)

Estado “Cierre sincronizado / Pendiente” — fuera de este fix.
