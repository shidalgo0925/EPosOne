# EPosOne — Catálogo EasyAI Operations Tools V1

| Campo | Valor |
|-------|--------|
| **Fecha** | 5 ago 2026 |
| **ADR** | [`ADR-017`](ADR-017-EASYAI-OPERATIONS-CONNECTOR.md) |
| **Regla** | Solo tools · sin tablas · sin IA |

Convención ID: `{contexto}.{verbo}` o `{contexto}.{verbo}.{recurso}`

Leyenda estado: **Pub** = publicado en registry · **Plan** = declarado · **Wire** = cableado a dominio

---

## Contextos

Ver ADR-017 §4.

---

## Herramientas por contexto

### caja

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `caja.consultar.estado` | consultar | Estado de caja / montos sesión | Plan |
| `caja.analizar.descuadre` | analizar | Señal descuadre teórico vs contado | Plan |
| `caja.abrir` | abrir | Abrir caja (auth) | Plan |
| `caja.cerrar` | cerrar | Cerrar / arqueo (auth) | Plan |

### turnos

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `turnos.consultar.actual` | consultar | Turno abierto actual | **Pub** |
| `turnos.consultar.historial` | consultar | Últimos N turnos | Plan |
| `turnos.abrir` | abrir | Abrir turno | Plan |
| `turnos.cerrar` | cerrar | Cerrar turno | Plan |

### pedidos

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `pedidos.consultar.abiertos` | consultar | Tickets / orders abiertos | Plan |
| `pedidos.consultar.por_id` | consultar | Detalle pedido | Plan |
| `pedidos.crear` | crear | Alta pedido (auth) | Plan |
| `pedidos.actualizar` | actualizar | Modificar líneas | Plan |
| `pedidos.cancelar` | cancelar | Cancel / void según lifecycle | Plan |
| `pedidos.cerrar` | cerrar | Cobrar / cerrar | Plan |

### clientes

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `clientes.consultar` | consultar | Buscar / ficha | Plan |
| `clientes.crear` | crear | Alta cliente | Plan |
| `clientes.actualizar` | actualizar | Editar ficha | Plan |

### inventario

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `inventario.consultar.stock` | consultar | Saldo producto | Plan |
| `inventario.actualizar.ajuste` | actualizar | Ajuste (auth) | Plan |
| `inventario.analizar.alertas` | analizar | Bajo mínimo | Plan |

### productos

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `productos.consultar` | consultar | Catálogo / SKU | Plan |
| `productos.crear` | crear | Alta (Standalone; Integrado EN1-owned) | Plan |
| `productos.actualizar` | actualizar | Precio/ficha según ownership | Plan |

### ventas

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `ventas.consultar` | consultar | Venta por id / periodo corto | Plan |
| `ventas.analizar.resumen_hoy` | analizar | Totales del día | Plan |
| `ventas.cancelar` | cancelar | Anular / reembolso (auth) | Plan |

### dispositivos

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `dispositivos.consultar.este` | consultar | Snapshot 2.6 / UUID / modo | Plan |
| `dispositivos.analizar.salud` | analizar | Bootstrap/sync/errores | Plan |

### dashboard

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `dashboard.consultar.pulso` | consultar | Alias OCC Hoy | **Pub** (vía occ) |
| `dashboard.analizar.atencion` | analizar | Conteo señales atención | **Pub** |

### occ

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `occ.consultar.pulso` | consultar | `OccPulse` operacional | **Pub** / **Wire** |
| `occ.analizar.alertas` | analizar | Lista señales Fase A | Plan |
| `occ.consultar.contexto` | consultar | Árbol navegación OCC | **Pub** |

### reportes

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `reportes.consultar.disponibles` | consultar | Lista informes (no datos crudos) | Plan |
| `reportes.analizar.ventas_periodo` | analizar | Agregado periodo (sin SQL) | Plan |

> Solo `consultar` / `analizar`. Sin crear/actualizar tablas de reporting.

### telemetria

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `telemetria.consultar.cola` | consultar | Pendientes / fallos sync | Plan |
| `telemetria.analizar.errores` | analizar | Últimos errores bootstrap/sync | Plan |

### licencias

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `licencias.consultar` | consultar | Snapshot + estado efectivo | Plan |
| `licencias.analizar.vencimiento` | analizar | Riesgo gracia/expiración | Plan |

---

## Verbos no publicados (V1)

Cualquier otro verbo (`eliminar`, `exportar_sql`, `query_raw`, …) → **rechazado** por el Connector.

---

## Sesión de invocación (mínimo)

```json
{
  "actor_id": "cashier_local_or_en1",
  "role": "admin|cashier",
  "channel": "easyai",
  "authorization_token": null
}
```

Escrituras (`crear`/`actualizar`/`cancelar`/`cerrar`/`abrir`) exigen auth explícita en Fase 2.
