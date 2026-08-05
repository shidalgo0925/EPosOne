# OPC-002 — Operations Tool Catalog

| Campo | Valor |
|-------|--------|
| **ID** | OPC-002 |
| **Padre** | [OPC-000](OPC-000-EPOSONE-OPERATIONS-CONNECTOR.md) |
| **Runtime** | [`EPOSONE_EASYAI_OPS_TOOL_CATALOG_V1.md`](../EPOSONE_EASYAI_OPS_TOOL_CATALOG_V1.md) |
| **Estado** | Inventario S2 · **solo documentar** (no implementar nuevos) |
| **Fecha** | 5 ago 2026 |

---

## 1. Propósito

Inventariar herramientas que EasyAI puede invocar.  
Convención: `{contexto}.{verbo}[.{recurso}]`.

Verbos canónicos: `consultar` · `analizar` · `crear` · `actualizar` · `cancelar` · `cerrar` · `abrir`.

| Riesgo | Auth |
|--------|------|
| Lectura (`consultar`/`analizar`) | No |
| Escritura | `OpsInvokeSession.authorized` + `actor_id` |

Leyenda madurez: **Wire** (scaffold) · **Spec** (S2 documentado, sin wire) · **Future**.

---

## 2. Inventario por intención de negocio (misión)

| Intención EasyAI | Tool ID propuesto | Madurez |
|------------------|-------------------|---------|
| Consultar ventas | `ventas.analizar.resumen_hoy` · `ventas.consultar` | Wire / Spec |
| Consultar pedidos | `pedidos.consultar.abiertos` · `pedidos.consultar.por_id` | Wire |
| Consultar turnos | `turnos.consultar.actual` · `turnos.consultar.historial` | Wire |
| Consultar arqueos | `caja.consultar.estado` | Wire |
| Consultar diferencias | `caja.analizar.descuadre` | Wire |
| Consultar clientes | `clientes.consultar` | Spec |
| Consultar inventario | `inventario.consultar.stock` · `inventario.analizar.alertas` | Spec |
| Consultar dispositivos | `dispositivos.consultar.este` · `dispositivos.analizar.salud` | Wire |
| Consultar sincronización | `telemetria.consultar.cola` · `telemetria.analizar.errores` | Wire |
| Consultar reportes | `reportes.consultar.disponibles` · `reportes.analizar.ventas_periodo` | Wire / Spec |
| Crear pedido | `pedidos.crear` | Spec |
| Cancelar pedido | `pedidos.cancelar` | Wire |
| Anular pedido | `pedidos.anular` *(alias lifecycle void)* | Spec |
| Abrir turno | `turnos.abrir` / `caja.abrir` | Wire |
| Cerrar turno | `turnos.cerrar` / `caja.cerrar` | Wire |
| Registrar pago | `pedidos.cerrar` / `ventas.registrar.pago` | Spec / Future |
| Registrar devolución | `ventas.cancelar` (refund) | Spec |

---

## 3. Catálogo detallado (alineado runtime + S2)

### caja

| Tool ID | Verbo | Auth | Madurez | Notas |
|---------|-------|------|---------|-------|
| `caja.consultar.estado` | consultar | No | Wire | Montos sesión |
| `caja.analizar.descuadre` | analizar | No | Wire | Input opcional `counted_amount` |
| `caja.abrir` | abrir | Sí | Wire | `opening_amount` |
| `caja.cerrar` | cerrar | Sí | Wire | `counted_amount`, notes |

### turnos

| Tool ID | Verbo | Auth | Madurez | Notas |
|---------|-------|------|---------|-------|
| `turnos.consultar.actual` | consultar | No | Wire | Alias CashRegister open |
| `turnos.consultar.historial` | consultar | No | Wire | limit N |
| `turnos.abrir` | abrir | Sí | Wire | Alias `caja.abrir` |
| `turnos.cerrar` | cerrar | Sí | Wire | Alias `caja.cerrar` |

### pedidos

| Tool ID | Verbo | Auth | Madurez | Notas |
|---------|-------|------|---------|-------|
| `pedidos.consultar.abiertos` | consultar | No | Wire | |
| `pedidos.consultar.por_id` | consultar | No | Wire | `ticket_id` |
| `pedidos.crear` | crear | Sí | Spec | No implementar en S2 |
| `pedidos.actualizar` | actualizar | Sí | Spec | Líneas |
| `pedidos.cancelar` | cancelar | Sí | Wire | Pre-cocina / OpenTicket |
| `pedidos.anular` | cancelar | Sí | Spec | Post-cocina void · Order Domain |
| `pedidos.cerrar` | cerrar | Sí | Spec | Cobro / pago |

### clientes / productos / inventario

| Tool ID | Verbo | Auth | Madurez |
|---------|-------|------|---------|
| `clientes.consultar` | consultar | No | Spec |
| `clientes.crear` / `.actualizar` | crear/actualizar | Sí | Spec |
| `productos.consultar` | consultar | No | Spec |
| `productos.crear` / `.actualizar` | crear/actualizar | Sí | Spec · ownership Dual Mode |
| `inventario.consultar.stock` | consultar | No | Spec |
| `inventario.actualizar.ajuste` | actualizar | Sí | Spec |
| `inventario.analizar.alertas` | analizar | No | Spec |

### ventas

| Tool ID | Verbo | Auth | Madurez |
|---------|-------|------|---------|
| `ventas.consultar` | consultar | No | Spec |
| `ventas.analizar.resumen_hoy` | analizar | No | Wire |
| `ventas.cancelar` | cancelar | Sí | Spec · refund |

### dispositivos / telemetria / licencias

| Tool ID | Verbo | Auth | Madurez |
|---------|-------|------|---------|
| `dispositivos.consultar.este` | consultar | No | Wire |
| `dispositivos.analizar.salud` | analizar | No | Wire |
| `telemetria.consultar.cola` | consultar | No | Wire |
| `telemetria.analizar.errores` | analizar | No | Wire |
| `licencias.consultar` | consultar | No | Wire |
| `licencias.analizar.vencimiento` | analizar | No | Wire |

### occ / dashboard / reportes

| Tool ID | Verbo | Auth | Madurez |
|---------|-------|------|---------|
| `occ.consultar.pulso` | consultar | No | Wire |
| `occ.analizar.alertas` | analizar | No | Wire |
| `occ.consultar.contexto` | consultar | No | Wire |
| `dashboard.consultar.pulso` | consultar | No | Wire |
| `dashboard.analizar.atencion` | analizar | No | Wire |
| `reportes.consultar.disponibles` | consultar | No | Wire |
| `reportes.analizar.ventas_periodo` | analizar | No | Spec |

---

## 4. Tools rechazados (nunca publicar)

| Patrón | Código rechazo |
|--------|----------------|
| `db.*`, `*.sql`, `*isar*`, `query_raw`, `select …` | `raw_access_forbidden` |
| Verbo no canónico | `tool_not_found` / reject |
| Escritura sin auth | `authorization_required` |
| Escritura sin actor | `actor_required` |

---

## 5. Relación con runtime

El archivo [`EPOSONE_EASYAI_OPS_TOOL_CATALOG_V1.md`](../EPOSONE_EASYAI_OPS_TOOL_CATALOG_V1.md) es el **catálogo operativo** del scaffold.  
OPC-002 es el **catálogo de especificación S2** (incluye Spec/Future).  
Ante conflicto de IDs Wire: gana el runtime + ADR-017.

---

## 6. Criterio S2

- [x] Intenciones de la misión mapeadas a Tool IDs.  
- [x] Separación Wire vs Spec (no implementar Spec en S2).  
- [x] Auth y rechazos documentados.
