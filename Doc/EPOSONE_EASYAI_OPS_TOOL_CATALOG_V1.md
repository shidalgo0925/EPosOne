# EPosOne — Catálogo EasyAI Operations Tools V1

| Campo | Valor |
|-------|--------|
| **Fecha** | 5 ago 2026 |
| **ADR** | [`ADR-017`](ADR-017-EASYAI-OPERATIONS-CONNECTOR.md) |
| **Regla** | Solo tools · sin tablas · sin IA |
| **Fase** | **2** — escrituras con auth · consultar/analizar cableados |

Convención ID: `{contexto}.{verbo}` o `{contexto}.{verbo}.{recurso}`

Leyenda estado: **Pub** = publicado en registry · **Plan** = declarado stub · **Wire** = cableado a dominio vía `operationsConnectorProvider`

---

## Contextos

Ver ADR-017 §4.

---

## Herramientas por contexto

### caja

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `caja.consultar.estado` | consultar | Estado de caja / montos sesión | **Wire** |
| `caja.analizar.descuadre` | analizar | Teórico vs `counted_amount` | **Wire** |
| `caja.abrir` | abrir | Abrir caja (auth) | **Wire** |
| `caja.cerrar` | cerrar | Cerrar / arqueo (auth) | **Wire** |

### turnos

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `turnos.consultar.actual` | consultar | Turno abierto actual | **Wire** |
| `turnos.consultar.historial` | consultar | Últimos N turnos | **Wire** |
| `turnos.abrir` | abrir | Abrir turno | **Wire** |
| `turnos.cerrar` | cerrar | Cerrar turno | **Wire** |

### pedidos

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `pedidos.consultar.abiertos` | consultar | Tickets / orders abiertos | **Wire** |
| `pedidos.consultar.por_id` | consultar | Detalle pedido | **Wire** |
| `pedidos.crear` | crear | Alta pedido (auth) | Plan |
| `pedidos.actualizar` | actualizar | Modificar líneas | Plan |
| `pedidos.cancelar` | cancelar | Cancel / void según lifecycle | **Wire** |
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
| `ventas.analizar.resumen_hoy` | analizar | Totales del día de negocio | **Wire** |
| `ventas.cancelar` | cancelar | Anular / reembolso (auth) | Plan |

### dispositivos

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `dispositivos.consultar.este` | consultar | Snapshot 2.6 / UUID / modo | **Wire** |
| `dispositivos.analizar.salud` | analizar | Bootstrap/sync/errores | **Wire** |

### dashboard

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `dashboard.consultar.pulso` | consultar | Alias OCC Hoy | **Wire** |
| `dashboard.analizar.atencion` | analizar | Conteo señales atención | **Wire** |

### occ

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `occ.consultar.pulso` | consultar | `OccPulse` operacional | **Wire** |
| `occ.analizar.alertas` | analizar | Lista señales Fase A | **Wire** |
| `occ.consultar.contexto` | consultar | Árbol navegación OCC | **Wire** |

### reportes

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `reportes.consultar.disponibles` | consultar | Lista informes (no datos crudos) | **Wire** |
| `reportes.analizar.ventas_periodo` | analizar | Agregado periodo (sin SQL) | Plan |

> Solo `consultar` / `analizar`. Sin crear/actualizar tablas de reporting.

### telemetria

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `telemetria.consultar.cola` | consultar | Pendientes / fallos sync | **Wire** |
| `telemetria.analizar.errores` | analizar | Últimos errores bootstrap/sync | **Wire** |

### licencias

| Tool ID | Verbo | Descripción | Estado |
|---------|-------|-------------|--------|
| `licencias.consultar` | consultar | Snapshot + estado efectivo | **Wire** |
| `licencias.analizar.vencimiento` | analizar | Riesgo gracia/expiración | **Wire** |

---

## Inyección app

```dart
final connector = ref.read(operationsConnectorProvider);

// 1) Autorizar escritura (PIN o sesión POS)
final auth = await authorizeOpsWithPin(ref, pin: pin, cashierId: id);
// final auth = authorizeOpsFromPosSession(ref);

if (!auth.ok) { /* auth.code / auth.message */ }

// 2) Invocar tool
await connector.invoke(
  'caja.abrir',
  {'opening_amount': 50.0},
  session: auth.session!,
);
```

El provider traduce repos/OCC → Maps. EasyAI **nunca** recibe Isar.

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

Escrituras (`crear`/`actualizar`/`cancelar`/`cerrar`/`abrir`) exigen `OpsInvokeSession.authorized` + `actor_id` (vía `OpsAuth` PIN o sesión POS).
