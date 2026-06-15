# EPOSOne vs Loyverse — Especificación de paridad

**Fecha:** 10 de junio de 2026  
**Audiencia:** analistas, diseño, desarrollo, QA  
**Referencia de producto:** [Loyverse POS (es)](https://loyverse.com/es)  
**Capturas locales:** carpeta `_loyverse_ref/` (16 screenshots, **no commitear**)

---

## 1. Propósito

Este documento define **qué significa “paridad Loyverse”** para EPOSOne y sirve como backlog estructurado. No implica copiar la marca ni el back office de Loyverse: EPOSOne es producto **EasyTech Services** con back office futuro **EN1**, facturación electrónica Panamá (DGI) y sync propio.

**Objetivo operativo:** que un cajero acostumbrado a Loyverse TPV pueda vender, cobrar, consultar recibos y cerrar turno con la misma lógica de negocio, en layout adaptado a tablet/móvil con branding EasyTech (naranja `#F58220`, navy `#1A3A5C`).

---

## 2. Ecosistema Loyverse (contexto)

| Producto | Función |
|----------|---------|
| **Loyverse TPV** | Ventas en piso (Android/iOS) |
| **Back Office** | Web — catálogo, empleados, reportes, inventario avanzado |
| **Dashboard** | KPIs móviles |
| **KDS** | Pantalla de cocina |
| **CDS** | Pantalla para cliente en caja |
| **API / Marketplace** | Integraciones contables, e-commerce, pagos |

Modelo freemium: TPV base gratis; historial ilimitado, empleados e inventario avanzado de pago vía Back Office.

**Alcance EPOSOne:** replicar primero el **TPV operativo**; el equivalente a Back Office será **EN1** (roadmap separado).

---

## 3. Paridad estimada actual

| Ámbito | Paridad |
|--------|---------|
| Ecosistema Loyverse completo (TPV + BO + KDS + CDS + Dashboard) | **~55–60%** |
| TPV operativo (PIN → venta → cobro → recibo → caja) | **~85–88%** |
| Restaurante / tickets abiertos (guardar, split, merge, pre-cuenta) | **~90%** |
| Flujo crítico end-to-end con persistencia local | **✅ Funcional** |

> Última auditoría: jun 2026 (`master` post-L2). El checkout persiste ventas, descuenta stock, asocia cajero/caja y soporta tickets abiertos avanzados. Ver `EPOSONE_ARCHITECTURE_REVIEW.md` para el estado previo al rediseño Loyverse-style.

---

## 4. Matriz de funcionalidades

Leyenda: ✅ Implementado · ⚠️ Parcial · ❌ No implementado · 🔮 Roadmap EPOSOne (no Loyverse)

### 4.1 Arranque y seguridad

| Funcionalidad Loyverse | EPOSOne | Notas |
|------------------------|---------|-------|
| Splash / carga inicial | ✅ | `/splash` |
| Onboarding primera vez | ✅ | `/onboarding` — negocio, RUC, ITBMS |
| PIN por empleado | ✅ | `/pin` — hash local, no texto plano |
| Roles (cajero vs admin) | ⚠️ | `CashierRole.admin` → `/admin`; permisos granulares ❌ |
| Bloqueo de terminal | ✅ | Inactividad → vuelve a PIN |
| Multi-empleado en mismo dispositivo | ✅ | Selección implícita vía PIN |

### 4.2 Turno y caja

| Funcionalidad Loyverse | EPOSOne | Notas |
|------------------------|---------|-------|
| Apertura de turno obligatoria | ✅ | `/cash/open` |
| Monto inicial en caja | ✅ | |
| Cierre de turno | ⚠️ | `/cash-register` — cierre manual, sin flujo POS integrado |
| Arqueo (teórico vs real) | ⚠️ | Campos en entidad; UI básica |
| Gestión de tesorería (entradas/salidas) | ❌ | L4.1 |
| Resumen de turno (bruto, neto, reembolsos, por método) | ⚠️ | Conteo y total en `/cash-register`; sin desglose por método ni reembolsos |
| Ventas asociadas a turno/caja | ✅ | `cashRegisterId` en `Sale` |

### 4.3 Pantalla POS (ventas)

| Funcionalidad Loyverse | EPOSOne | Notas |
|------------------------|---------|-------|
| Grid productos + ticket lateral (tablet landscape) | ✅ | Row 6:4 @ ≥720px |
| Categorías en tabs/chips | ✅ | Filtro por categoría |
| Búsqueda de productos | ✅ | |
| Fotos en grid POS | ✅ | Si `product.imagePath` existe |
| Páginas POS personalizables | ❌ | |
| Añadir al carrito / cantidades | ✅ | Tap suma; qty +/- en ticket |
| ITBMS / impuesto configurable | ✅ | `BusinessConfig.taxRate` |
| Cliente en ticket | ✅ | `CustomerPickerTile` en panel ticket |
| Tipo de orden (Comer dentro / para llevar) | ✅ | `OrderType` en ticket y venta |
| **GUARDAR** ticket | ✅ | Isar `OpenTicket` + slots predefinidos |
| **TICKETS ABIERTOS** | ✅ | Sheet: abrir, cobrar, editar, mover, dividir, fusionar, pre-cuenta |
| Botón **COBRAR** prominente | ✅ | Navega a `/payment` |
| Escáner código de barras | ❌ | |
| Modificadores (extras, variantes) | ❌ | |
| Descuento por línea / ticket | ⚠️ | Modelo soporta `discount`; UI POS ❌ |
| Menú lateral (Ventas, Artículos, Recibos, Turno…) | ⚠️ | Bottom sheet desde POS |

### 4.4 Cobro

| Funcionalidad Loyverse | EPOSOne | Notas |
|------------------------|---------|-------|
| Pantalla split (ticket + pago) | ⚠️ | Pantalla dedicada; ticket resumido |
| Efectivo + montos rápidos | ✅ | B/.1, B/.5, B/.10, B/.20 + Exacto |
| Tarjeta | ✅ | |
| Yappy | ✅ | `PaymentMethod.yappy` |
| Transferencia / Otro | ✅ | |
| Cálculo de cambio | ✅ | |
| **DIVIDIR** cuenta | ✅ | Split por ítems o partes iguales al cobrar |
| Propina | ❌ | |
| Email recibo post-venta | ❌ | |
| **NUEVA VENTA** post-cobro | ✅ | Desde `/receipt/:id` |

### 4.5 Recibos e historial

| Funcionalidad Loyverse | EPOSOne | Notas |
|------------------------|---------|-------|
| Lista master-detail (tablet) | ✅ | `SalesHistoryScreen` lista + panel detalle |
| Búsqueda por recibo | ✅ | Número, cajero, total, método de pago (no por nombre de cliente) |
| Detalle: empleado, TPV, ITBMS, método | ⚠️ | Parcial en detalle/recibo |
| **REEMBOLSAR** | ✅ | Acción en detalle; revierte stock |
| Recibo visual post-venta | ✅ | `/receipt/:id` |
| Impresión térmica | ❌ | Deps en pubspec sin uso |
| PDF | ❌ | |

### 4.6 Catálogo (en TPV / menú)

| Funcionalidad Loyverse | EPOSOne | Notas |
|------------------------|---------|-------|
| Artículos CRUD | ✅ | `/products` |
| Categorías CRUD | ✅ | `/categories` |
| Modificadores (módulo) | ❌ | |
| Descuentos (módulo) | ❌ | |
| Inventario / stock | ✅ | Descuenta al vender si `trackInventory` |
| Alertas stock bajo | ❌ | |
| Etiquetas código de barras | ❌ | |

### 4.7 Clientes y lealtad

| Funcionalidad Loyverse | EPOSOne | Notas |
|------------------------|---------|-------|
| Base de clientes | ✅ | `/customers` |
| Historial compras por cliente | ❌ | |
| Programa de lealtad | ❌ | |
| Identificación por teléfono / barcode | ❌ | |

### 4.8 Hardware e integraciones

| Funcionalidad Loyverse | EPOSOne | Notas |
|------------------------|---------|-------|
| Impresoras Star/Epson/Sunmi BT | ❌ | L5 |
| Cajón de dinero | ❌ | |
| CDS / KDS | ❌ | L6 |
| Pagos integrados (SumUp, Zettle) | ❌ | |
| API pública | ❌ | Sync EN1 🔮 |
| Offline-first | ✅ | Isar local |
| Sync cloud post-offline | ❌ | Entidades `SyncEntity` preparadas |

### 4.9 Diferenciadores EPOSOne (no Loyverse)

| Funcionalidad | Estado |
|---------------|--------|
| Facturación electrónica DGI Panamá | 🔮 Roadmap |
| Back office EN1 / multiempresa SaaS | 🔮 Roadmap |
| Branding EasyTech | ✅ |
| Datos 100% locales sin cuenta Loyverse | ✅ |

---

## 5. Flujos de referencia

### 5.1 Loyverse TPV (objetivo UX)

```
PIN → Turno abierto → POS (grid + ticket)
  → [GUARDAR → Tickets abiertos] opcional
  → COBRAR → Pago (efectivo/tarjeta/Yappy/dividir)
  → Recibo (email / imprimir) → NUEVA VENTA
Menú → Recibos (master-detail, REEMBOLSAR)
Menú → Turno (tesorería, cierre, arqueo)
Menú → Artículos / Modificadores / Descuentos
```

### 5.2 EPOSOne (implementado hoy)

```
/splash → /onboarding (1ª vez) → /pin → /cash/open → /pos
  → [GUARDAR → /tickets/pick] → tickets abiertos (abrir, cobrar, editar, mover, dividir, fusionar, pre-cuenta)
  → /payment [/payment/split] → /receipt/:id → /pos (nueva venta)
Menú POS → /products, /sales (master-detail tablet + reembolso), /cash-register, /settings/open-tickets, /admin (admin)
Bloqueo por inactividad → /pin
```

Rutas definidas en `eposone/lib/src/core/router/app_router.dart`.

---

## 6. Roadmap de paridad (backlog)

Prioridad sugerida para acercarse al TPV Loyverse sin bloquear FE Panamá.

### L1 — POS core (tablet + tickets) ✅ Implementado (jun 2026)

**Meta:** experiencia de caja equivalente en tablet.

| ID | Historia | Estado |
|----|----------|--------|
| L1.1 | Layout tablet landscape | ✅ `PosScreen` Row 6:4 @720px |
| L1.2 | Ticket lateral en POS | ✅ `PosTicketPanel` — qty +/-, eliminar, totales |
| L1.3 | GUARDAR ticket | ✅ `OpenTicket` + `OpenTicketLine` en Isar |
| L1.4 | TICKETS ABIERTOS | ✅ `OpenTicketsSheet` + badge en AppBar |
| L1.5 | Cliente en ticket | ✅ `CustomerPickerTile` |
| L1.6 | Fotos en grid | ✅ `PosProductGrid` + `imagePath` |

**Open Tickets V1.1** (extensión L1, jun 2026): slots predefinidos, split/merge de tickets, pre-cuenta, aviso carrito sin guardar — ver §4.3 y §7.

### L2 — Cobro avanzado y recibos ✅ Implementado (jun 2026)

**Meta:** cobro y consulta de ventas equivalentes a Loyverse TPV.

| ID | Historia | Estado |
|----|----------|--------|
| L2.1 | Montos rápidos efectivo | ✅ Botones B/.1, B/.5, B/.10, B/.20, exacto |
| L2.2 | Dividir cuenta | ✅ Split por ítems o partes iguales |
| L2.3 | Reembolso | ✅ REEMBOLSAR; revierte stock |
| L2.4 | Recibos master-detail | ✅ Lista + detalle en tablet |
| L2.5 | Búsqueda recibo | ✅ Por número, cajero, total, método |

### L3 — Catálogo enriquecido

| ID | Historia | Criterio de aceptación |
|----|----------|------------------------|
| L3.1 | Modificadores | Grupos (ej. tamaño, extras); precio adicional |
| L3.2 | Descuentos | % o monto fijo; por línea y ticket |
| L3.3 | Páginas POS | Configurar layout de botones por categoría/página |
| L3.4 | Tipo de orden | ✅ Enum dine-in / takeaway / delivery en ticket y venta |

### L4 — Turno completo

| ID | Historia | Criterio de aceptación |
|----|----------|------------------------|
| L4.1 | Tesorería | Entradas/salidas de efectivo con motivo |
| L4.2 | Resumen de turno | Ventas brutas, reembolsos, descuentos, netas, por método |
| L4.3 | Cierre integrado en flujo POS | Desde menú cajero; obligatorio antes de salir |
| L4.4 | Arqueo visual | Esperado vs contado; diferencia destacada |

### L5 — Hardware

| ID | Historia | Criterio de aceptación |
|----|----------|------------------------|
| L5.1 | Impresión térmica BT | Recibo 58/80mm; al menos 1 driver (ESC/POS) |
| L5.2 | Escáner barcode | Cámara o BT → añadir producto |
| L5.3 | Email recibo | Share sheet / SMTP configurable |

### L6 — Ecosistema EasyTech

| ID | Historia | Criterio de aceptación |
|----|----------|------------------------|
| L6.1 | Sync EN1 | Subida ventas/catálogo; conflictos documentados |
| L6.2 | Dashboard KPIs | App o web ligera |
| L6.3 | KDS / CDS | Solo si vertical restaurante lo exige |
| L6.4 | FE DGI | Emisión comprobante fiscal Panamá |

---

## 7. Modelo de datos — extensiones previstas

Entidades actuales relevantes: `Sale`, `SaleItem`, `Product`, `Category`, `Customer`, `CashRegister`, `Cashier`, `BusinessConfig`.

| Feature L1–L4 | Entidad / campo sugerido |
|---------------|--------------------------|
| Tickets abiertos | ✅ `OpenTicket` + `OpenTicketLine` + `PredefinedTicket` |
| Dividir ticket abierto | ✅ `/tickets/:id/split` — mover líneas a otro ticket |
| Pre-cuenta | ✅ Diálogo informativo desde sheet o carrito activo |
| Fusionar tickets | ✅ Desde sheet tickets abiertos |
| Dividir cuenta (cobro) | ✅ `SplitBillScreen` — N pagos al cobrar |
| Modificadores | `ModifierGroup`, `Modifier`, línea con `modifiers[]` |
| Tesorería | `CashMovement` (type, amount, reason, registerId) |
| Tipo orden | `OrderType` enum en `Sale` / `OpenTicket` |

---

## 8. QA — checklist de regresión POS

Ejecutar en dispositivo Android tras cada fase. Marcado ✅ = verificado en desarrollo jun 2026; repetir en tablet T10 antes de release.

### Flujo base (L1)

- [x] Primer uso: onboarding → PIN default → abrir caja → vender
- [x] Venta efectivo con cambio correcto
- [x] Venta tarjeta / Yappy sin monto manual
- [x] Stock decrementa cuando `trackInventory = true`
- [x] Correlativo de recibo incrementa
- [x] Bloqueo por inactividad pide PIN
- [x] Admin accede a `/admin`; cajero no
- [x] Historial `/sales` muestra venta recién creada

### Cobro y recibos (L2)

- [x] Montos rápidos efectivo (B/.1, B/.5, B/.10, B/.20, Exacto)
- [x] Dividir cuenta al cobrar (por ítems y partes iguales)
- [x] Reembolso revierte stock cuando `trackInventory = true`
- [x] Master-detail recibos en tablet + búsqueda por número

### Tickets abiertos (V1 + V1.1)

- [x] Guardar ticket → slot predefinido o nombre libre
- [x] Abrir / cobrar / editar / mover ticket
- [x] Dividir ticket (mover líneas a otro ticket)
- [x] Fusionar dos tickets
- [x] Pre-cuenta desde sheet o carrito activo
- [x] Aviso al abrir otro ticket con carrito sin guardar

### Pendiente / regresión schema

- [ ] Impresión recibo y pre-cuenta (L5 — hoy stub)
- [ ] Descuento manual en POS (L3.2 — modelo listo, UI pendiente)
- [ ] Tras cambio de schema Isar (`PredefinedTicket`, campos extendidos): **borrar datos app** en upgrade desde builds pre-jun 2026

---

## 9. Referencias internas

| Recurso | Ubicación |
|---------|-----------|
| Arquitectura y auditoría | `EPOSONE_ARCHITECTURE_REVIEW.md` |
| README app | `eposone/README.md` |
| Tema / branding | `eposone/lib/src/core/theme/eposone_theme.dart` |
| Router | `eposone/lib/src/core/router/app_router.dart` |
| Persistencia venta | `eposone/lib/src/features/pos/presentation/providers/pos_provider.dart` |
| Capturas Loyverse | `_loyverse_ref/*.png` (local, gitignore) |

---

## 10. Decisiones de producto

1. **No clonar Back Office Loyverse** — EN1 es el destino para administración web.
2. **Priorizar TPV en tablet** — mayoría de clientes EasyTech usan tablet en caja.
3. **Offline-first no negociable** — sync es capa posterior (L6).
4. **FE Panamá es ventaja competitiva** — no está en Loyverse; planificar tras L4 (turno) o en paralelo con L5.
5. **Marca EasyTech** — no usar verde Loyverse; paleta naranja/navy propia.

---

*Documento vivo: actualizar paridad y checklist al cerrar cada fase L1–L6.*
