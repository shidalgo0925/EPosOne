# Sprint Pedido — Log de Validación Funcional V1.0

**Método:** [`ETS_PRODUCT_VALIDATION_METHOD_V1.md`](ETS_PRODUCT_VALIDATION_METHOD_V1.md)  
**Inicio:** 18 jul 2026  
**APK:** `eposone/epos1.apk` (última release con TZ + sin seed Istmo)  
**Ambiente:** EN1 Dev · org demo / Itsmo según provisioning  
**Estado del módulo Pedido:** 🟡 En validación funcional (Caso 1)

---

## Preflight (antes de Caso 1)

Marcar al iniciar la sesión en tablet:

- [ ] APK instalada (datos limpios o catálogo EN1 ya descargado)
- [ ] Provisionado EN1 (URL + código caja)
- [ ] Catálogo EN1 descargado (Comida / Bar con productos)
- [ ] Cajero con PIN · caja **abierta**
- [ ] Chip EN1 visible (conectado o al menos provisionado)
- [ ] Acceso a BackOffice EN1 para Casos 9–10

**No abrir:** inventario, licencias, features nuevas, “ya que estamos…”.

---

## Pre-auditoría de flujo (agente · 18 jul 2026)

Mapa del código real, para que la sesión no se pierda:

**Camino real del cajero (validar este):**

```
POS (carrito) → agregar productos → «Guardar pedido» (icono guardar)
   → crea Ticket abierto + upsert Pedido EN1 (linkedOrderLocalId), sync si EN1 listo
   → «Cobrar» (/payment) → createPaidOrderFromPosSale → pedido pagado a EN1
```

- `pos_screen.dart` (carrito, «Guardar pedido»), `save_open_ticket_flow.dart`, `pos_provider.dart` (`createPaidOrderFromPosSale`).

**Pantalla “Pedidos EN1” (`/settings/orders`) = herramienta de diagnóstico, NO el flujo de caja.**

- Tiene consola “Diagnóstico Sync (Hito 3C)”, “copiar log — pegar a Teams / P1”, y «Nuevo pedido» crea un pedido **vacío sin productos**.
- El cajero **no** opera desde aquí. Útil solo para depurar sync.

### Candidatos de hallazgo (confirmar en tablet)

| # | Observación | Categoría propuesta |
|---|-------------|---------------------|
| P1 | “Pedidos EN1” expone consola de diagnóstico y “pegar a Teams/P1” en build de cliente | Mejora UX (ocultar/gate antes de RC) |
| P2 | Dos entradas de pedido (POS carrito vs Pedidos EN1) pueden confundir | Mejora UX / Backlog (aclarar navegación) |
| P3 | Creación de Pedido EN1 depende de `isEn1SyncReady`; offline guarda ticket local | Verificar en Caso 7 (esperado, no bloqueador) |

Estos son **candidatos**; se confirman operando, no leyendo código.

---

## Caso 1 — Happy Path

**Historia:** Un cliente pide, paga con un solo método, se imprime/cierra, el pedido llega a EN1.

### Guion de operación (ejecutar en orden)

| Paso | Acción del cajero | Resultado esperado |
|------|-------------------|--------------------|
| 1.1 | PIN → entra al POS | Pantalla venta lista, caja abierta, chip EN1 visible |
| 1.2 | Elige página **Comida** o **Bar** · toca **1 producto** | Línea en el ticket del carrito, total coherente |
| 1.3 | Agrega **segundo producto** (otra categoría si hay) | 2 líneas, subtotal/ITBMS/total OK |
| 1.4 | Toca **Guardar pedido** (icono guardar) · pon mesa/etiqueta | Overlay “Guardando pedido…” · snackbar OK · ticket recuperable |
| 1.5 | Abre **Tickets abiertos** y reabre el ticket | Mismas líneas y totales · ligado a Pedido EN1 |
| 1.6 | **Cobrar** (/payment) · un solo método (efectivo) · Confirmar Cobro | Cobrado · sin saldo pendiente · vuelto si aplica |
| 1.7 | Impresión / recibo | Documento usable con **hora local negocio** (o anotar si falta) |
| 1.8 | Ticket cerrado / carrito limpio | Estado correcto en POS |
| 1.9 | Chip sync / cola EN1 | Pasa a sincronizado o limpia pendientes |
| 1.10 | EN1 BO: localizar el pedido pagado | Mismo total, líneas, pago, **sin duplicar** |

> No uses “Pedidos EN1” (Configuración) para este caso: es pantalla de diagnóstico sin selección de productos.

### Resultado Caso 1

| Campo | Valor |
|-------|--------|
| Fecha / hora | |
| Ejecutor | |
| ¿Pasó? | ☐ Sí · ☐ No · ☐ Parcial |
| Bloqueadores RC | (lista o “ninguno”) |
| Mejoras UX | |
| Backlog futuro | |
| Notas jornada | ¿Fluido para 8 h? ☐ Sí ☐ No |

### Hallazgos Caso 1

*(copiar plantilla por cada uno)*

```
Caso: 1
Momento:
Observado:
Esperado:
Categoría: Bloqueador RC | Mejora UX | Backlog futuro
Nota:
```

---

## Casos 2–10 (no empezar hasta cerrar Caso 1)

| # | Caso | Estado |
|---|------|--------|
| 2 | Cliente cambia de opinión | ⏸ |
| 3 | Cliente agrega más | ⏸ |
| 4 | Se equivoca el cajero | ⏸ |
| 5 | Cambio de vendedor | ⏸ |
| 6 | Pago mixto | ⏸ |
| 7 | Se cae Internet | ⏸ |
| 8 | Regresa Internet | ⏸ |
| 9 | Verificación EN1 | ⏸ (parcialmente en 1.11) |
| 10 | Auditoría | ⏸ |

---

## Resumen módulo Pedido

| Estado ETS | ☐ Desarrollado · ☑ Validación en curso · ☐ Validado funcional · ☐ Pulido UX · ☐ RC |
|------------|-------------------------------------------------------------------------------------|
| Bloqueadores abiertos | 0 (actualizar) |
| Siguiente | Completar Caso 1 en tablet → reportar hallazgos aquí o en chat |

---

*EasyTech · Sprint Pedido V1.0 · GO*
