# EPosOne — Inventario de fuentes OCC (Fase A)

| Campo | Valor |
|-------|--------|
| **Fecha** | 5 ago 2026 |
| **ADR** | [`ADR-016`](ADR-016-EPOSONE-OPERATIONS-CONTROL-CENTER.md) |
| **Objetivo** | Listar de dónde salen las señales de **Hoy / Operación / Cajas** sin implementar aún |

---

## Hoy (pulso)

| Widget / señal | Fuente | Notas |
|----------------|--------|-------|
| Turno abierto | `CashRegister` sesión / Cash Shift `current` | Deep link a caja |
| Pedidos abiertos | `OpenTicket` count · Order abiertos | |
| Cola sync | `syncPendingCountProvider` / `SyncOperation` | |
| Licencia | `LicenseService` | Estado / vencimiento si hay snapshot |
| Errores recientes | DeviceInfo 2.6 · last bootstrap/sync error | Resumen, no dump técnico |

## Operación

| Señal | Fuente |
|-------|--------|
| Conectividad EN1 | `en1StatusSnapshotProvider` |
| Bootstrap / provisioning | `ProvisioningStore` · `En1BootstrapRepository` |
| Dispositivo | `DeviceRegistry` · UUID / modo |
| Pedidos atascados | Order status + age (definir umbral en impl) |

## Cajas

| Señal | Fuente |
|-------|--------|
| Cierre / arqueo | Cash Shift close · pantallas caja existentes |
| Bitácora turno | CashMovement · eventos Order / caja |
| Descuadre | `counted` vs teórico (contrato Cash Shift) |

## Pagos (Fase A = solo enlaces)

| Señal | Fuente |
|-------|--------|
| Medios del día | Sale / OrderPayment agregados locales | Detalle rico → Fase C |

## Alertas / Auditoría

Fase A: bandeja mínima o “sin alertas engine”.  
Fase B: reglas + bitácora formal.

## Reportes (fuera de OCC)

`ReportsHubScreen` — ventas / turnos / empleados. El OCC **enlaza**; no embebe el informe completo.
