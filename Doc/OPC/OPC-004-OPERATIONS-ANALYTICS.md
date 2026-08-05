# OPC-004 — Operations Analytics Catalog

| Campo | Valor |
|-------|--------|
| **ID** | OPC-004 |
| **Padre** | [OPC-000](OPC-000-EPOSONE-OPERATIONS-CONNECTOR.md) |
| **Estado** | Inventario S2 · qué podrá utilizar EasyAI |
| **Fecha** | 5 ago 2026 |

---

## 1. Propósito

Inventariar **indicadores** disponibles (o derivables) para EasyAI **sin SQL** y sin acceso a tablas.

Analytics ≠ OCC: OCC es pulso “ahora”; analytics son **métricas** (hoy / periodo / turno).

---

## 2. Catálogo de indicadores

| Indicador | Descripción | Fuente / Tool | EasyAI puede | Madurez |
|-----------|-------------|---------------|--------------|---------|
| **Ventas brutas** | Total ventas completadas | `ventas.analizar.resumen_hoy` · reportes | Sí (agregado) | Wire / Spec |
| **Ventas netas** | Bruto − devoluciones | mismo | Sí | Wire |
| **Pedidos abiertos** | Conteo tickets/orders abiertos | `occ.consultar.pulso` · `pedidos.consultar.abiertos` | Sí | Wire |
| **Pedidos cerrados (día)** | Conteo sales completed | resumen ventas / reportes | Sí (agregado) | Spec |
| **Diferencias de caja** | counted − expected | `caja.analizar.descuadre` · close | Sí | Wire |
| **Tiempo promedio ticket** | Edad media abiertos / ciclo | OpenTicket.saved_at · Order ages | Futuro (umbral OCC) | Spec |
| **Descuentos** | Monto / programa aplicado | Discount Domain · sale.discount | Sí (agregado futuro) | Spec |
| **Devoluciones** | Count + monto refund | resumen_hoy · Order refund | Sí | Wire parcial |
| **Sincronización** | pending / failed / last_sync | `telemetria.consultar.cola` | Sí | Wire |
| **Offline** | EN1 offline / device | `dispositivos.analizar.salud` · OCC | Sí | Wire |
| **Telemetría errores** | Bootstrap / provisioning / sync | `telemetria.analizar.errores` | Sí | Wire |
| **Estado operativo** | attention_count + alerts | `occ.*` / `dashboard.*` | Sí | Wire |
| **Licencia riesgo** | grace / expired | `licencias.analizar.vencimiento` | Sí | Wire |
| **Propinas** | tips_total día | resumen_hoy | Sí | Wire |
| **Medios de pago** | Mix cash/card/… | ShiftSummary / reportes | Spec | Spec |

---

## 3. Qué EasyAI **no** debe hacer con analytics

| Prohibido | Motivo |
|-----------|--------|
| Query ad hoc Isar/SQL | Rompe Connector |
| Reinterpretar tax engine | ADR-008 / Totals |
| Sustituir reportes históricos por OCC | OCC ≠ reportes |
| Inventar KPIs fiscales | Fuera de S2 |

---

## 4. Agrupación para EasyAI

```text
Pulso (ahora)     → OCC / dashboard / telemetría / licencia
Turno (sesión)    → caja / turnos / diferencias
Día de negocio    → ventas resumen_hoy / propinas / refunds
Periodo           → reportes.analizar.* (Spec)
Salud plataforma  → dispositivos / sync / offline
```

---

## 5. Criterio S2

- [x] Indicadores de la misión listados.  
- [x] Identificado uso EasyAI vs prohibiciones.
