# EPosOne — Checklist E2E oficial (Prog2)

| Campo | Valor |
|-------|--------|
| **Fecha** | 19 jul 2026 |
| **Origen** | Analista — cierre Hito 2.5 + cadena operativa |
| **Precondición** | APK limpia: desinstalar + reinstalar (no update-over-install) |
| **Estado** | 🟡 Bloque A OK · **B en curso (1 ago 2026)** · C–E pendientes |
| **Run log** | [`EPOSONE_E2E_HITO25_RUN_LOG.md`](EPOSONE_E2E_HITO25_RUN_LOG.md) |

---

## A. Provisioning + Bootstrap

| # | Prueba | OK |
|---|--------|----|
| A1 | APK limpia (sin datos) | ✅ |
| A2 | Provisionar dispositivo | ✅ |
| A3 | Bootstrap inicial | ✅ |
| A4 | Descargar catálogo | ✅ |
| A5 | Descargar cajeros | ✅ |
| A6 | Descargar configuración de caja | ✅ |
| A7 | Descargar versión de políticas (aunque vacía) | ✅ |
| A8 | Verificar `cashiers_version` | ✅ |
| A9 | Reiniciar APK y confirmar persistencia | ✅ |

**Esperado:** dispositivo listo para operar sin repetir provisioning.

---

## B. Operación de Cajeros (Hito 2.5)

| # | Prueba | OK |
|---|--------|----|
| B1 | Login PIN online | ☐ |
| B2 | Login PIN offline | ☐ |
| B3 | PIN incorrecto | ☐ |
| B4 | PIN bloqueado (lockout tras fallos) | ☐ |
| B5 | Abrir turno | ☐ |
| B6 | Cambio de cajero | ☐ |
| B7 | Cambio de cajero con pedido abierto | ☐ |
| B8 | Cambio de cajero con pedido pagado | ☐ |
| B9 | Desactivar cajero desde EN1 | ☐ |
| B10 | Sincronizar / bootstrap | ☐ |
| B11 | Confirmar bloqueo del cajero desactivado | ☐ |
| B12 | Ops anteriores conservan cajero original | ☐ |

---

## C. Cadena operativa completa (crítica)

| # | Prueba | OK |
|---|--------|----|
| C1 | Abrir turno | ☐ |
| C2 | Crear pedido | ☐ |
| C3 | Modificar pedido | ☐ |
| C4 | Agregar productos | ☐ |
| C5 | Eliminar productos | ☐ |
| C6 | Cobrar efectivo | ☐ |
| C7 | Cobro mixto | ☐ |
| C8 | Imprimir recibo | ☐ |
| C9 | Cerrar pedido | ☐ |
| C10 | Sincronizar | ☐ |
| C20 | Pedido cobrado en EN1 (paid + financially_closed + closed) desaparece de tickets abiertos en APK tras sync | ☐ |

**Verificar en EN1:** Pedido · Eventos · Pagos · Cajero · Caja · Turno.

**Pagos mixtos (extra Analista):** persistencia local · recibo · reporte/turno.

**Nota C20 (Prog2):** EN1 ya cierra el pedido al liquidar. La APK debe reconciliar en sync y soft-delete el `OpenTicket` (Juanito/Pedrito).

---

## D. Offline

| # | Prueba | OK |
|---|--------|----|
| D1 | Provisionar (previo) | ☐ |
| D2 | Desconectar Internet | ☐ |
| D3 | Login | ☐ |
| D4 | Abrir turno | ☐ |
| D5 | Crear pedido | ☐ |
| D6 | Cobrar | ☐ |
| D7 | Imprimir | ☐ |
| D8 | Cerrar turno | ☐ |
| D9 | Reconectar | ☐ |
| D10 | Confirmar Push | ☐ |
| D11 | Sin duplicados | ☐ |
| D12 | Idempotencia | ☐ |

---

## E. Regresión

Confirmar que no se dañó:

| Área | OK |
|------|----|
| Productos | ☐ |
| Clientes | ☐ |
| Inventario | ☐ |
| Tickets abiertos | ☐ |
| Pagos | ☐ |
| Recibos / historial | ☐ |
| Bootstrap | ☐ |

---

## Criterio de cierre Hito 2.5

Hito 2.5 se declara **cerrado** solo cuando A + B + C (mínimo) están OK en tablet y Analista/P1 confirman handoff.

---

*EasyTech · Prog2 · 19 jul 2026*
