# OPC-005 — Operations Dashboard Catalog

| Campo | Valor |
|-------|--------|
| **ID** | OPC-005 |
| **Padre** | [OPC-000](OPC-000-EPOSONE-OPERATIONS-CONNECTOR.md) |
| **Estado** | Documentación S2 · **no implementar pantallas** |
| **Fecha** | 5 ago 2026 |
| **SoT UI** | [`ADR-016`](../ADR-016-EPOSONE-OPERATIONS-CONTROL-CENTER.md) · [`EPOSONE_OCC_SOURCE_INVENTORY_V1.md`](../EPOSONE_OCC_SOURCE_INVENTORY_V1.md) |

---

## 1. Propósito

Documentar la información disponible para el **Centro de Control (OCC)** y el pulso tipo dashboard, de modo que EasyAI sepa qué puede leer **sin** construir pantallas en S2.

Principio congelado: **OCC ≠ reportes**.

---

## 2. Navegación OCC (producto)

```text
Centro de Control
  ├── Hoy
  ├── Operación
  ├── Cajas
  ├── Pagos
  ├── Alertas
  └── Auditoría
```

Tool: `occ.consultar.contexto` → árbol nav.

---

## 3. Inventario de superficie

### KPIs (pulso)

| KPI | Señal | Tool / fuente |
|-----|-------|---------------|
| Turno abierto | shift_open / shift_label | `occ.consultar.pulso` |
| Pedidos abiertos | open_tickets | mismo |
| Sync pendiente | pending_sync | mismo |
| Sync fallido | failed_sync | mismo |
| Atención | attention_count | `dashboard.analizar.atencion` |
| Link EN1 | link_label | pulso |
| Licencia | license_label | pulso |

### Resúmenes

| Resumen | Contenido | Notas |
|---------|-----------|-------|
| Hoy | KPIs + cajero actual | Fase A OCC |
| Turno | opening / expected / sales count | `caja.consultar.estado` |
| Ventas día | gross / net / tips / refunds | `ventas.analizar.resumen_hoy` |
| Dispositivo | uuid / versión / modo | `dispositivos.consultar.este` |

### Alertas

| Alerta | Código típico | Fuente |
|--------|---------------|--------|
| Cola sync | `sync_pending` | OCC / telemetría |
| Sync fallido | `sync_failed` | mismo |
| Bootstrap | `bootstrap` | Device 2.6 |
| Provisioning | `provisioning` | mismo |
| EN1 offline | `en1_offline` | link |
| Licencia | `license` | gracia/expirada |
| Descuadre | (al cerrar / analizar) | caja |

Tool: `occ.analizar.alertas`.

### Excepciones

| Excepción | Dominio | EasyAI |
|-----------|---------|--------|
| Pedido atascado (edad) | Order / OpenTicket | Spec · umbral futuro OCC B |
| Caja abierta excesiva | Cash Shift | Spec |
| Descuadre material | Cash close | Wire vía analizar/cerrar |
| Refund / void del día | Order / Sale | Spec analytics |

### Tendencias

| Tendencia | Disponibilidad S2 |
|-----------|-------------------|
| Ventas vs ayer / semana | Spec · `reportes.analizar.*` |
| Tasa de sync fail | Spec · telemetría histórica |
| Frecuencia descuadres | Spec · historial turnos |

S2 **no** implementa series temporales; solo las identifica como oportunidades de lectura vía tools futuros.

---

## 4. Qué EasyAI consume vs qué es UI POS

| EasyAI (Connector) | UI POS (OCC shell) |
|--------------------|--------------------|
| Tools de pulso / alertas / salud | Pantallas Hoy/Operación/… |
| Sin deep-link obligatorio | Deep links a caja / dispositivo |
| No pinta gráficos en S2 | Widgets Fase A+ |

---

## 5. Criterio S2

- [x] KPIs, resúmenes, alertas, excepciones, tendencias identificados.  
- [x] Sin pantallas nuevas.
