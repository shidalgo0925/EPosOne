# EPosOne — Run log E2E Hito 2.5 (tablet)

| Campo | Valor |
|-------|--------|
| **Fecha inicio** | 1 ago 2026 |
| **APK prueba** | Release 5 ago · `cc9b0de` · `eposone/build/app/outputs/flutter-apk/app-release.apk` |
| **Checklist** | [`EPOSONE_E2E_CHECKLIST_HITO25_V1.md`](EPOSONE_E2E_CHECKLIST_HITO25_V1.md) |
| **Estado** | A ✅ · B ✅ · **C–E pendientes (Ops)** · Ingeniería Prog2 **cerrada** ([cierre 5 ago](EPOSONE_PROG2_DELIVERY_CLOSE_2026-08-05.md)) |

Marcar cada fila: `OK` / `FAIL` / `N/A` + nota breve.

---

## A. Provisioning + Bootstrap — CERRADO

Ya OK en tablet (19 jul / revalidado con sync 1 ago). No repetir salvo APK limpia nueva.

---

## B. Operación de Cajeros — CERRADO (mínimo B1–B8)

**Preconds:** dispositivo provisionado, bootstrap OK, ≥2 cajeros EN1 activos con PIN, Wi‑Fi OK (salvo B2).

| # | Pasos en tablet | Resultado | Notas |
|---|-----------------|-----------|-------|
| B1 | Login PIN online | **OK** | 2 ago |
| B2 | Login PIN offline | **OK** | 2 ago |
| B3 | PIN incorrecto | **OK** | 2 ago |
| B4 | PIN bloqueado (lockout tras fallos) | **OK** | 2 ago |
| B5 | Abrir turno | **OK** | 2 ago |
| B6 | Cambio de cajero | **OK** | 2 ago |
| B7 | Cambio de cajero con pedido abierto | **OK** | 2 ago |
| B8 | Cambio de cajero con pedido pagado | **OK** | 2 ago |
| B9 | Desactivar cajero desde EN1 | | Requiere BO EN1 — diferido |
| B10 | Sincronizar / bootstrap | | Diferido con B9 |
| B11 | Confirmar bloqueo del cajero desactivado | | Diferido con B9 |
| B12 | Ops anteriores conservan cajero original | | Diferido / confirmar en C |

**Bloque B OK solo si B1–B8 + B11 (mínimo).** B9–B10 dependen de acceso BO EN1.

---

## C. Cadena operativa — EJECUTAR AHORA (2 ago)

**Preconds:** turno cerrado o listo para abrir · Wi‑Fi ON · catálogo EN1 · cola limpia o anotar pendientes previos.

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
