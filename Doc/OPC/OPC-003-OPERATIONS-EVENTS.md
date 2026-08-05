# OPC-003 — Operations Event Catalog

| Campo | Valor |
|-------|--------|
| **ID** | OPC-003 |
| **Padre** | [OPC-000](OPC-000-EPOSONE-OPERATIONS-CONNECTOR.md) |
| **Estado** | Inventario S2 · **solo documentar** · no modificar eventos existentes |
| **Fecha** | 5 ago 2026 |
| **Fuentes** | [`EPOSONE_ORDER_EVENTS_OPERATIONAL_MODEL_V1.md`](../EPOSONE_ORDER_EVENTS_OPERATIONAL_MODEL_V1.md) · Cash Shift · Sync · License |

---

## 1. Propósito

Inventariar **eventos operacionales** que EasyAI podría observar vía EIS Event (futuro).

S2 **no**:

- Crea nuevos eventos de dominio.  
- Cambia contratos EN1.  
- Implementa bus/subscribe.

S2 **sí**: nombra, describe origen y disponibilidad para EasyAI.

---

## 2. Modelo

| Campo | Descripción |
|-------|-------------|
| **Event ID (OPC)** | Nombre canónico para EasyAI (PascalCase misión) |
| **Origen EPOSOne** | Dominio / señal existente |
| **Payload lógico** | Campos no-tabla |
| **Disponibilidad** | `Emitido` · `Derivable` · `Future-EIS` |

---

## 3. Pedidos / Order Domain

| Event ID OPC | Origen | Payload lógico | Disponibilidad |
|--------------|--------|----------------|----------------|
| `OrderCreated` | Alta Order / ticket confirmado | order_id, ticket_id, cashier_id, at | Derivable |
| `OrderCancelled` | `cancelOrder` · lifecycle `cancelled` · EN1 `pedido.anulado` | order_id, reason, at | Emitido (dominio) |
| `OrderVoided` | `voidOrder` · lifecycle `voided` · mismo evento HTTP `pedido.anulado` | order_id, reason, at | Emitido (dominio) |
| `OrderPaid` / `PaymentCompleted` | Cobro / close paid | order_id, amounts, methods, at | Derivable |
| `RefundCreated` | `pedido.devuelto` / refund sale | order_id / sale_id, amount, at | Emitido (dominio) |

Fuente de verdad de reglas UI: Order Events Operational Model (Cancelar ≠ Anular ≠ Reembolsar).

---

## 4. Caja / Cash Shift

| Event ID OPC | Origen | Payload lógico | Disponibilidad |
|--------------|--------|----------------|----------------|
| `CashShiftOpened` | `CashRegister.open` / sync shift | register_id, opening_amount, cashier, at | Emitido / sync |
| `CashShiftClosed` | `CashRegister.close` / arqueo | register_id, counted, expected, difference, at | Emitido / sync |
| `CashMovementRecorded` | CashMovement in/out | register_id, type, amount, reason | Derivable |
| `CashDifferenceDetected` | close difference ≠ 0 | register_id, difference | Derivable |

---

## 5. Inventario / catálogo

| Event ID OPC | Origen | Disponibilidad |
|--------------|--------|----------------|
| `InventoryUpdated` | Ajuste stock / venta | Derivable |
| `CatalogBootstrapped` | Bootstrap EN1 | Derivable |

---

## 6. Dispositivo / sync / licencia

| Event ID OPC | Origen | Payload lógico | Disponibilidad |
|--------------|--------|----------------|----------------|
| `DeviceOffline` | `En1LinkState.offline` | device_uuid, at | Derivable (OCC) |
| `DeviceOnline` | link connected | device_uuid, at | Derivable |
| `SyncCompleted` | ciclo sync OK | pending→0, at | Derivable |
| `SyncFailed` | SyncOperation failed | entity_kind, message | Derivable |
| `BootstrapFailed` | lastBootstrapError | message | Derivable |
| `LicenseExpired` | LicenseStatus expired | plan, at | Derivable |
| `LicenseGraceEntered` | status grace | grace_until | Derivable |
| `LicenseSuspended` | status suspended | — | Derivable |

---

## 7. Relación con EasyAI

```text
Dominio EPOSOne emite / cambia estado
        │
        ▼
(Señal local · cola sync · OCC pulse)
        │
        ▼  [Future: EIS Event transport]
EasyAI Core subscribe / poll
```

Hasta que CODITO congele EIS Event transport:

- EasyAI usa **Tools** (`occ.analizar.alertas`, `telemetria.*`) para estado.  
- OPC-003 es el **diccionario** de nombres de evento.

---

## 8. Prohibiciones S2

- No renombrar eventos HTTP EN1 (`pedido.anulado`, `pedido.devuelto`, …).  
- No exigir `pedido.voided` (P1 Order Model).  
- No emitir eventos desde UI EasyAI.

---

## 9. Criterio S2

- [x] Eventos de la misión inventariados.  
- [x] Trazabilidad a Order / Cash / Sync / License.  
- [x] Sin modificación de eventos existentes.
