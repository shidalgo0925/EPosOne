# OPC-001 — Operations Context Catalog

| Campo | Valor |
|-------|--------|
| **ID** | OPC-001 |
| **Padre** | [OPC-000](OPC-000-EPOSONE-OPERATIONS-CONNECTOR.md) |
| **Estado** | Inventario S2 · documentación |
| **Fecha** | 5 ago 2026 |

---

## 1. Propósito

Inventariar **todos los Contextos** que EasyAI puede consultar vía Operations Connector.

Un Context es un **namespace operacional**, no una tabla. EasyAI obtiene datos solo mediante Tools del Context (OPC-002).

---

## 2. Convención

| Campo | Descripción |
|-------|-------------|
| **Context ID** | Identificador estable (`snake` / lowercase) |
| **EIS alias** | Nombre EIS cuando CODITO lo publique (TBD) |
| **Fuente dominio** | Dominio EPOSOne detrás de la fachada |
| **Consulta EasyAI** | Qué puede saber (lectura) |
| **Escritura** | Si hay tools write (auth) |
| **Madurez** | `Wire` = expuesto en scaffold · `Spec` = documentado S2 · `Future` = roadmap |

---

## 3. Catálogo de contextos

### 3.1 Organización / jerarquía (provisioning)

| Context ID | Fuente | Qué puede consultar EasyAI | Madurez |
|------------|--------|----------------------------|---------|
| `organizacion` | Provisioning / BusinessConfig | `organization_id`, nombre negocio, moneda, timezone EN1 | Spec |
| `sucursal` | Provisioning `branchRef` | Id / nombre sucursal | Spec |
| `pos` | Provisioning `posRef` | Id / nombre POS | Spec |

> Hoy embebidos en `dispositivos.consultar.este` y licencia. Contextos dedicados = tools futuros sin romper Dual Mode.

### 3.2 Operación de caja

| Context ID | Fuente | Qué puede consultar EasyAI | Madurez |
|------------|--------|----------------------------|---------|
| `caja` | CashRegister · ShiftSummary | Estado abierto, montos, teórico, descuadre | Wire |
| `turnos` | Mismo CashRegister (Cash Shift) | Turno actual, historial, open/close | Wire |
| `cajero` | PosSession · Cashier / EN1 catalog | Quién opera, rol, contact_id | Spec (vía sesión tools) |

### 3.3 Comercial / pedido

| Context ID | Fuente | Qué puede consultar EasyAI | Madurez |
|------------|--------|----------------------------|---------|
| `pedidos` | OpenTicket · Order Domain | Abiertos, detalle, cancel/void lifecycle | Wire (parcial) |
| `ventas` | Sale ledger | Resumen día, venta por id (plan) | Wire (resumen) |
| `clientes` | Customer | Buscar / ficha | Spec |
| `productos` | Catalog bootstrap | SKU / precio / categoría | Spec |
| `inventario` | Stock | Saldo / alertas mínimo | Spec |

### 3.4 Plataforma / salud

| Context ID | Fuente | Qué puede consultar EasyAI | Madurez |
|------------|--------|----------------------------|---------|
| `dispositivos` | DeviceRegistry · 2.6 | UUID, modo, versión, salud | Wire |
| `sincronizacion` | SyncOperation · EN1 link | Alias preferido: ver `telemetria` | Spec (alias) |
| `telemetria` | Sync · bootstrap errors | Cola, fallos, últimos errores | Wire |
| `licencias` | LicenseService | Snapshot, efectivo, riesgo vencimiento | Wire |

### 3.5 Superficies de control / informes

| Context ID | Fuente | Qué puede consultar EasyAI | Madurez |
|------------|--------|----------------------------|---------|
| `dashboard` | Alias OCC Hoy | Pulso + atención | Wire |
| `occ` | OCC ADR-016 | Pulso, alertas, nav Hoy/…/Auditoría | Wire |
| `reportes` | Reports hub | Lista informes disponibles; agregados sin SQL | Wire (lista) |

---

## 4. Mapa Context → información permitida

| Context | Campos / señales típicas (lectura) | Prohibido |
|---------|--------------------------------------|-----------|
| `caja` / `turnos` | open, register_id, opening/expected/counted, difference, cashier | Filas Isar raw |
| `pedidos` | id, label, status, order_type, saved_at, linked_order | Payload SQL |
| `ventas` | sale_count, gross/net, tips, business_date | Dump ledger completo ad hoc |
| `dispositivos` | uuid, app_version, mode, link, bootstrap_done | Secrets / access_token |
| `telemetria` | pending, failed, by_kind, error summaries | Stack traces internos |
| `licencias` | type, plan, effective_status, expires/grace | Signature privada |
| `occ` / `dashboard` | shift_open, open_tickets, pending_sync, attention_count, alerts[] | Embebido de reportes históricos |
| `reportes` | id, title, route | Ejecutar SQL del informe |

---

## 5. Relaciones entre contextos

```text
organizacion
  └── sucursal
        └── pos
              └── dispositivos (este)
                    ├── caja / turnos / cajero
                    ├── pedidos → ventas / clientes
                    ├── productos → inventario
                    ├── licencias
                    └── telemetria / sincronizacion
occ / dashboard  ──observa──►  (caja, pedidos, telemetria, licencias, dispositivos)
reportes         ──histórico──► ventas / turnos / empleados (fuera de OCC)
```

---

## 6. Dual Mode

| Context | Standalone | Integrado EN1 |
|---------|------------|---------------|
| Catálogo / productos | Local | Bootstrap EN1 |
| Cajeros | Local PIN | EN1 catalog + PIN |
| Pedidos | OpenTicket local | + Order Domain sync |
| Licencias | Puede no haber snapshot | Snapshot EN1 |
| Sync | Cola local mínima | Cola + link EN1 |

EasyAI **no** elige modo: el Connector resuelve detrás del tool.

---

## 7. Criterio S2

- [x] Contextos de la misión inventariados (org→reportes).  
- [x] Claridad de qué puede consultar EasyAI.  
- [x] Sin exposición de tablas.
