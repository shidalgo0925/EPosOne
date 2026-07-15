# Decisión de Arquitectura — Operación vs Administración

**Estado:** Aprobado  
**Fecha:** 14 de julio de 2026  
**Audiencia:** Programador 1 (EN1) · Programador 2 (EPosOne) · Producto  
**Master Plan:** [`EPOSONE_MASTER_PLAN_V3.md`](../EPOSONE_MASTER_PLAN_V3.md)  
**Hito 3 (siguiente tras Bootstrap):** [`EPOSONE_EN1_HITO3_ORDER_LIFECYCLE_BRIEF.md`](EPOSONE_EN1_HITO3_ORDER_LIFECYCLE_BRIEF.md)

---

## 1. Objetivo

Mantener **un único EPosOne** y **un único EN1** que sirvan tanto a un Food Truck con una tablet como a una cadena con BackOffice, **sin** crear EPosOne Lite / Pro ni duplicar lógica de inventario.

> La diferencia entre un negocio pequeño y uno grande no estará en el software, sino en **cómo se utiliza** y en el **modo de organización**.

---

## 2. Principio fundamental

| Sistema | Rol |
|---------|-----|
| **EPosOne** | Sistema de **ejecución / operación** — vende y opera |
| **EN1** | Sistema de **gestión / administración** — administra, controla y audita |

- **EN1** es la fuente oficial de existencias, Kardex, costos, compras, transferencias, conteos y configuración.
- **EPosOne** genera **eventos de negocio**; **no** escribe Kardex ni actualiza tablas de inventario oficiales.
- Offline: venta local → cola → EN1 procesa → actualiza inventario → publica stock → POS consulta referencia.

```
Pedido cobrado
    ↓
Venta / evento (POS)
    ↓
Cola sync
    ↓
EN1 recibe evento
    ↓
EN1 descuenta inventario · crea Kardex · actualiza stock
    ↓
EN1 publica nuevo stock (bootstrap / push)
```

---

## 3. Separación de responsabilidades

### 3.1 EPosOne — Operación (sí)

- Abrir / modificar pedido  
- Agregar productos · cobrar · imprimir  
- Abrir / cerrar caja  
- Consultar disponibilidad básica (referencia)  
- Trabajar offline · sincronizar con EN1  
- Clientes: consulta y alta rápida  

### 3.2 EPosOne — No administración ERP (no estándar)

No debe convertirse en mini-ERP. En modos corporativos **no** pantallas de:

- Crear bodegas · ajustes masivos · conteos físicos  
- Órdenes de compra · transferencias entre bodegas  
- Costos · Kardex · lotes · vencimientos  

### 3.3 EN1 — Administración (sí)

Productos · categorías · bodegas · ajustes · conteos · transferencias · compras · recepciones · Kardex · stock min/max · proveedores · costos · reportes · configuración · auditoría.

---

## 4. Tres escenarios (no dos productos)

| Escenario | Ejemplos | Quién administra |
|-----------|----------|------------------|
| **1 — Solo POS** | Food truck, kiosco, café pequeña | Administración **básica** en la tablet (no hay PC) |
| **2 — POS + BackOffice** | Restaurante, mini súper, ferretería | EN1 administra; POS opera |
| **3 — Multi-sucursal / corporativo** | Cadenas, hoteles, franquicias | Todo en EN1; POS casi sin admin |

**No hay** EPosOne Lite / Pro. Hay **un EPosOne** con capacidades según **modo de organización** + **rol**.

---

## 5. Modo de organización + capacidades

La decisión **no** depende solo del rol del cajero. También de la configuración de la organización (EN1 o setup inicial):

| Modo | ID sugerido | Capacidades admin en POS |
|------|-------------|--------------------------|
| Solo POS | `pos_only` | Administración básica habilitada |
| POS + BackOffice | `pos_backoffice` | Admin POS reducida / apagada |
| Corporativo | `corporate` | POS = operación pura |

### Niveles de usuario (referencia)

| Función | Operador | Encargado | Administrador |
|---------|----------|-----------|---------------|
| Vender / cobrar / caja | ✅ | ✅ | ✅ |
| Crear / editar producto | ❌ | ✅* | ✅* |
| Cambiar precios | ❌ | ✅* | ✅* |
| Ver existencias (ref.) | ✅ | ✅ | ✅ |
| Ajuste rápido inventario | ❌ | ✅* | ✅* |
| Conteo físico | ❌ | ❌ | ❌** |
| Transferencias / compras | ❌ | ❌ | ❌** |
| Configuración del negocio | ❌ | ❌ | ✅* |

\* Solo si el **modo de organización** lo permite (p. ej. `pos_only`).  
\*\* Siempre EN1 (BackOffice), no POS.

### Administración básica (excepción Solo POS)

Funciones simples, claramente etiquetadas, **no** ERP:

- Crear / editar producto · cambiar precio  
- Ver existencias · **ajuste rápido** de inventario (motivo + auditoría)  
- Alta rápida de clientes  

Toda modificación = **evento** → cola → EN1 persiste y genera Kardex / auditoría cuando hay conectividad.

**Ajuste rápido:** deshabilitado por defecto en modos 2/3; requiere autorización; genera auditoría en EN1 al sync.

---

## 6. Inventario — regla dura

| Actor | Puede |
|-------|-------|
| EN1 | Fuente oficial · Kardex · costos · compras · transferencias · conteos |
| POS | Consultar stock de referencia · generar eventos de venta / ajuste rápido |
| POS | **No** actualizar tablas de inventario oficiales ni calcular Kardex |

Excepción operativa: ajuste rápido (evento), no escritura directa de Kardex.

---

## 7. Pedido = entidad principal

Todo inicia con un **Pedido**. Ventas, inventario, caja y facturación son **consecuencias**.

- Usuarios **no** administran estados: ejecutan **acciones**.  
- El sistema cambia el estado interno.

| Acción | Estado (ejemplo) |
|--------|------------------|
| Crear pedido | Borrador |
| Enviar | En preparación |
| Marcar listo | Listo |
| Entregar | Entregado |
| Cobrar | Cobrado |
| Anular | Anulado |
| Devolver | Devuelto |

### Cancelaciones (tres escenarios)

| Momento | Tratamiento |
|---------|-------------|
| Antes de preparación | Modificación del pedido · sin movimiento inventario · sin auth especial |
| Después de preparación | Anulación · motivo + usuario + fecha/hora · auth según política |
| Después de entrega | Devolución · puede generar NC / ajuste / merma según producto |

### Sync POS ↔ EN1 (no solo ventas)

Ciclo de vida del Pedido vía eventos, p. ej.:

`pedido.creado` · `producto.agregado` · `producto.eliminado` · `cantidad.modificada` · `pedido.enviado` · `pedido.listo` · `pedido.entregado` · `pedido.cobrado` · `pedido.anulado` · `pedido.devuelto`

EN1 = fuente oficial del Pedido una vez sincronizado; historial completo; un pedido puede iniciarse en un POS y cobrarse en otro o en BackOffice.

---

## 8. Congelados / fuera de alcance inmediato

| Congelado | Motivo |
|-----------|--------|
| POS Core (flujo cajero) | Solo bugs |
| Provisioning EN1-02 | Tag `provisioning-v1.0` |
| Device Bootstrap cliente (tras cierre Hito 2) | No reabrir sin GO |

**No implementar ahora (post-Hito 3):** inventario operativo completo · transferencias · compras · FE DGI · CRM · IA.

---

## 9. Relación con hitos

| Hito | Contenido |
|------|-----------|
| **1** | Provisioning — ✅ cerrado |
| **2** | Device Bootstrap (catálogo / imágenes / saldos ref.) — EPosOne avanzado; cerrar E2E |
| **3** | **Operación del Pedido** (redefinido) — ver brief Hito 3 |
| **Luego** | Inventario operativo desde eventos · caja avanzada · FE · analítica |

**Antes:** Hito 3 = “Ventas → Stock”.  
**Ahora:** Hito 3 = ciclo de vida del Pedido + sync bidireccional. El descuento de stock oficial es **consecuencia en EN1** de eventos (base en Hito 3; inventario completo en hitos posteriores).

---

*Documento de decisión · EasyTech · 14 jul 2026*
