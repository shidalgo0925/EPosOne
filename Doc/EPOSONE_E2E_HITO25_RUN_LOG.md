# EPosOne — Run log E2E Hito 2.5 (tablet)

| Campo | Valor |
|-------|--------|
| **Fecha inicio** | 1 ago 2026 |
| **APK** | `a5f2dbb`+ (sync Device Token / bootstrap gate) |
| **Checklist** | [`EPOSONE_E2E_CHECKLIST_HITO25_V1.md`](EPOSONE_E2E_CHECKLIST_HITO25_V1.md) |
| **Estado** | A ✅ · **B en curso** · C–E pendientes |

Marcar cada fila: `OK` / `FAIL` / `N/A` + nota breve.

---

## A. Provisioning + Bootstrap — CERRADO

Ya OK en tablet (19 jul / revalidado con sync 1 ago). No repetir salvo APK limpia nueva.

---

## B. Operación de Cajeros — EJECUTAR AHORA

**Preconds:** dispositivo provisionado, bootstrap OK, ≥2 cajeros EN1 activos con PIN, Wi‑Fi OK (salvo B2).

| # | Pasos en tablet | Resultado | Notas |
|---|-----------------|-----------|-------|
| B1 | PIN correcto → entra | | |
| B2 | Modo avión → PIN correcto → entra | | |
| B3 | PIN malo → error, no entra | | |
| B4 | Fallar PIN varias veces → lockout temporal | | |
| B5 | Abrir turno (fondo inicial) → POS | | |
| B6 | Cambiar cajero (sin pedido) → nuevo PIN → mismo turno | | |
| B7 | Pedido abierto → cambiar cajero → pedido sigue / cajero nuevo | | |
| B8 | Pedido pagado → cambiar cajero → ops OK | | |
| B9 | En EN1: desactivar cajero A → en tablet: Descargar catálogo / sync | | Requiere BO EN1 |
| B10 | Confirmar bootstrap/sync OK tras B9 | | |
| B11 | Login con cajero A desactivado → bloqueado | | |
| B12 | Pedidos/turnos previos siguen mostrando cajero original | | |

**Bloque B OK solo si B1–B8 + B11 (mínimo).** B9–B10 dependen de acceso BO EN1.

---

## C. Cadena operativa (siguiente tras B)

| # | Resultado | Notas |
|---|-----------|-------|
| C1 Abrir turno | | |
| C2 Crear pedido | | |
| C3 Modificar | | |
| C4 Agregar productos | | |
| C5 Quitar productos | | |
| C6 Cobrar efectivo | | |
| C7 Cobro mixto | | |
| C8 Recibo | | |
| C9 Cerrar pedido | | |
| C10 Sync sin error cola | | |
| C20 Ticket abierto desaparece tras paid en EN1 | | |

**EN1 debe mostrar:** pedido, eventos, pagos, cajero, caja, turno.

---

## D. Offline (después de C)

Ver checklist oficial D1–D12.

---

## E. Regresión (rápido al final)

Productos · Clientes · Inventario · Tickets · Pagos · Recibos · Bootstrap.

---

## Firma cierre

| Rol | Fecha | OK |
|-----|-------|----|
| Prog2 (tablet) | | ☐ |
| Analista / P1 handoff | | ☐ |

*Hito 2.5 cerrado solo con A+B+C mínimo OK.*
