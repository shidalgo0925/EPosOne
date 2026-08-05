# ADR-016 — Operations Control Center (OCC)

| Campo | Valor |
|-------|--------|
| **Estado** | **Fase A en curso** — shell OCC + Hoy + enlaces (código); madurez B–D pendiente |
| **Fecha** | 5 de agosto de 2026 |
| **Prioridad** | Pilar de producto · **no desplaza** cierre E2E P0 / Hito 2.5 |
| **SoT** | Este ADR + decisión ETS “Control Operacional ≠ reportes” |
| **Relacionado** | [`ADR-008`](ADR-008-EPOSONE-COMMERCIAL-ENGINE.md) · [`ADR-014`](ADR-014-EPOSONE-INSTALLATION-PROVISIONING-BOOTSTRAP.md) · [`ADR-015`](ADR-015-EPOSONE-DISCOUNT-DOMAIN-V1.md) · Cash Shift [`EN1_EPOSONE_CASH_SHIFT_HTTP_CONTRACT.md`](EN1_EPOSONE_CASH_SHIFT_HTTP_CONTRACT.md) · Ownership [`EPOSONE_OWNERSHIP_MATRIX_V1.md`](EPOSONE_OWNERSHIP_MATRIX_V1.md) · Diagnóstico 2.6 |

---

## 1. Decisión

EPosOne adopta el dominio **Operations Control (Control Operacional)** como pilar de producto.

Nombre de producto / módulo:

**Operations Control Center (OCC)**  
Español UI: **Centro de Control**

No se llama “Cash Shift Center”, “Centro de reportes” ni “Dashboard de informes”.

### Principio arquitectónico (congelado)

> **El Centro de Control nunca será un conjunto de reportes.**  
> Es una **superficie operacional** construida sobre los dominios del sistema.

Consecuencia: los reportes históricos (ventas, turnos, empleados) pueden seguir existiendo como *informes*; el OCC responde preguntas de **estado y atención ahora**, no de “cuánto vendí el mes pasado”.

---

## 2. Analogía NOC

Como un NOC de telecomunicaciones, el OCC responde:

| Pregunta operacional | Ejemplos |
|----------------------|----------|
| ¿Qué está caído / offline? | Dispositivo, sync, impresora, delivery |
| ¿Qué requiere atención? | Turno abierto de más, caja descuadrada, cola sync, licencia por vencer |
| ¿Dónde está el problema? | Sucursal · POS · Caja · Cajero · Pedido |

EPOSOne opera **una** organización.  
EN1 reutiliza el **mismo** modelo con agregación **multi-organización**. Solo cambia el nivel de zoom.

---

## 3. Alcance del dominio (no solo turnos)

El OCC observa / actúa sobre (mínimo conceptual):

| Área | Dominios fuente |
|------|-----------------|
| Caja / turnos | CashRegister · Cash Shift · arqueos · bitácoras |
| Pedidos | Order Domain · OpenTicket · lifecycle |
| Pagos | OrderPayment · medios · parciales |
| Sincronización | SyncOperation · cola · últimos errores |
| Dispositivos | Provisioning · bootstrap · Hito 2.6 |
| Cajeros | Catálogo local / EN1 · sesión |
| Licencias | License snapshot |
| Alertas | Señales derivadas de lo anterior |
| Futuro | KDS · Delivery · Marketplace · Reservas · eCommerce → **widgets**, no “reporte X” |

Cash Shift es un **subconjunto** (sección Cajas), no el nombre del dominio.

---

## 4. IA de navegación (escalable)

**No** top-level:

```text
Dashboard · Cierres · Excepciones · Arqueos
```

**Sí** top-level OCC:

```text
Centro de Control
├── Hoy              ← pulso ejecutivo / atención inmediata
├── Operación        ← pedidos, sync, dispositivos, salud
├── Cajas            ← cierres · arqueos · bitácoras (Cash Shift aquí)
├── Pagos            ← medios, fallos, conciliación ligera
├── Alertas          ← inbox operacional
└── Auditoría        ← bitácora / quién · qué · cuándo
```

Widgets nuevos (cocina, delivery…) se cuelgan bajo **Hoy / Operación / Alertas** sin rediseñar el árbol.

---

## 5. Dual Mode

| | Standalone | Integrado EN1 |
|--|------------|---------------|
| Datos | Isar / local | Mismos contratos + sync; EN1 agrega multi-sucursal en BO |
| Lógica de señales | Una vez en capa OCC / adapters | Misma; origen de datos cambia |
| UI cajero | OCC en APK (gerente / admin) | OCC en APK + OCC multi-tenant en EN1 |

**Prohibido:** inventar HTTP OCC en EN1 desde P2. Consumir solo contratos congelados (Cash Shift, Order, Bootstrap, License, …).

---

## 6. Roadmap de madurez (historia del producto)

| Fase | Objetivo | Contenido típico |
|------|----------|------------------|
| **A — Visibilidad** | Ver la operación | Navegación OCC · **Hoy** (KPIs + deep links) · acceso a arqueos/cierres existentes |
| **B — Control** | Actuar sobre excepciones | Alertas · bitácora · excepciones de caja/sync/dispositivo |
| **C — Inteligencia** | Priorizar | Medios de pago · salud operativa · rankings / insights |
| **D — Conciliación** | Cerrar el ciclo financiero | Banco · depósitos · conciliación |

Fase A **no** implementa inteligencia ni banco.

---

## 7. Separación de responsabilidades

| Superficie | Rol |
|------------|-----|
| **OCC** | Estado · atención · drill-down operacional |
| **Reportes** (`ReportsHub`) | Históricos / agregados de periodo |
| **Este dispositivo (2.6)** | Diagnóstico técnico de **este** endpoint; alimenta OCC Operación, no lo reemplaza |
| **POS Core** | Vender; OCC no altera el flujo de cobro |

---

## 8. Fuentes locales ya existentes (Fase A — inventario)

| Señal | Fuente actual (aprox.) |
|-------|-------------------------|
| Turno abierto / cierre | `CashRegister` · Cash Shift HTTP |
| Pedidos / tickets | Order Domain · OpenTicket |
| Cola sync / errores | `SyncOperation` · pantalla 2.6 |
| Dispositivo / bootstrap | Provisioning · `En1BootstrapRepository` · DeviceInfo |
| Cajeros | Local / `En1CashierCatalogStore` |
| Licencia | `LicenseService` |
| Ventas periodo | Sale ledger / reportes (solo deep link, no duplicar informe) |

Detalle vivo: [`EPOSONE_OCC_SOURCE_INVENTORY_V1.md`](EPOSONE_OCC_SOURCE_INVENTORY_V1.md).

---

## 9. Fuera de alcance inmediato

- Rediseñar reportes como OCC.  
- Multi-tenant OCC dentro de la APK.  
- Inventar APIs “operations-control” en EN1.  
- Fase B–D sin cerrar Visibilidad + evidencia P0.  
- Kitchen/Delivery widgets hasta existir dominio fuente.

---

## 10. Consecuencias

1. Todo trabajo UI de “centro de cierres” se reclasifica bajo **OCC → Cajas**.  
2. Nuevas pantallas de monitoreo siguen el árbol §4.  
3. EN1 puede espejar el mismo árbol a escala portfolio.  
4. P0 E2E (Hito 2.5 C–E) **sigue primero**; OCC Fase A es paralelo solo con GO explícito de implementación.

---

## 11. Criterio de aceptación ADR

- [x] Nombre OCC / Centro de Control  
- [x] Principio ≠ reportes  
- [x] Árbol de navegación §4  
- [x] Fases A–D por madurez  
- [x] Dual Mode + no inventar HTTP  
- [x] Implementación Fase A (código) — shell + Hoy + deep links (`/operations-control`)
