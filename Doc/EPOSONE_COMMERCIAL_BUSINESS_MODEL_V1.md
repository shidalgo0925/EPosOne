# Modelo Comercial EPosOne V1

| Campo | Valor |
|-------|--------|
| **Estado** | Borrador — revisión Analista / P1 / P2 |
| **Fecha** | 19 jul 2026 |
| **Roadmap** | [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md) |
| **Relacionado** | Operación vs Admin · Order Domain Spec · ADR-007 Licenciamiento |
| **Alcance** | Modelo de negocio. **Sin** tablas, APIs ni payloads. |
| **Siguiente** | Fase 2 — Contratos (Fiscal, Propinas, Pagos, Recibo) |

---

## 1. Propósito

Responder: **¿Cómo funciona un negocio dentro de EPosOne?**

Este documento es la base del Sprint Comercial V6. Los contratos, motores y el ADR-008 se derivan de aquí; no al revés.

---

## 2. Principios cerrados

| # | Principio |
|---|-----------|
| 1 | **Un solo modelo comercial** para Standalone e Integrado. |
| 2 | La diferencia entre modos es solo el **origen de los datos**, no la lógica. |
| 3 | Toda regla de negocio se define **una vez** (contratos / políticas) y se aplica en ambos modos. |
| 4 | EPosOne es **operación** (vende, cobra, imprime, opera offline). |
| 5 | EN1 es **administración y auditoría** cuando el negocio está Integrado. |
| 6 | En Standalone, el POS administra lo mismo en local (admin básica). |
| 7 | Offline first: vender nunca depende de Internet. |
| 8 | No hay EPosOne Lite / Pro: un producto, modos de organización distintos. |

---

## 3. Dual Mode

### 3.1 Modo Standalone (Solo POS)

Un comercio descarga EPosOne, configura su negocio y vende **sin EN1**.

- Origen de maestros y políticas: **base local**.
- Quién administra: el dueño/encargado **en la tablet**.
- Sync: no aplica (salvo futura vinculación).

### 3.2 Modo Integrado (Plataforma EN1)

El negocio vincula EPosOne a EN1.

- Origen de maestros y políticas: **EN1** (fuente oficial).
- Quién administra: BackOffice EN1.
- El POS deja de editar maestros/políticas; **aplica el snapshot** sincronizado.
- Al sincronizar operaciones, EN1 puede **recalcular y validar** totales según las mismas reglas.

### 3.3 Vinculación (cutover)

Un cliente puede empezar Standalone y meses después contratar EN1:

- No reinstala.
- No cambia de forma de trabajar.
- Ejecuta un **asistente de vinculación**.
- A partir de entonces EN1 administra configuración y datos maestros.

### 3.4 Resumen

| Componente | Standalone | Integrado |
|------------|------------|-----------|
| Productos, clientes, cajeros | Local | EN1 → sync |
| Impuestos, propinas, pagos, recibo | Local | EN1 → sync |
| Cálculo de totales | Motor local | Mismo motor local + validación EN1 al sync |
| Licencia | Local / trial | EN1 (caja) |
| Edición de políticas en POS | Sí | No |

---

## 4. Jerarquía del negocio

```text
Empresa (Organización)
  └── Sucursal
        └── POS (punto de venta / estación)
              └── Caja (register) ← licencia pertenece aquí
                    └── Dispositivo(s)
                    └── Turno / Cajero
```

| Concepto | Rol de negocio |
|----------|----------------|
| **Empresa** | Dueño legal del negocio. RUC, razón social, moneda, país. |
| **Sucursal** | Ubicación operativa. Dirección, zona horaria, políticas por defecto. |
| **POS** | Estación de trabajo (barra, mesa, food truck). Ownership de pedidos abiertos. |
| **Caja** | Unidad fiscal/comercial que abre y cierra turnos. Objeto de la licencia. |
| **Cajero** | Persona que se identifica (PIN) y opera la caja en un turno. |
| **Turno** | Periodo abierto de una caja con un cajero (o secuencia de cajeros). |

Una venta siempre ocurre en el contexto: **Empresa · Sucursal · POS · Caja · Cajero · Turno**.

---

## 5. Actores

| Actor | Qué hace |
|-------|----------|
| **Cajero / Operador** | Toma pedidos, cobra, imprime, abre/cierra caja según permisos. |
| **Encargado** | Además: descuentos, anulaciones, ajustes permitidos por política. |
| **Administrador** | En Standalone: configura empresa, productos, contratos. En Integrado: lo hace en EN1. |
| **Cliente** | Consumidor final o registrado (RUC/cédula). Puede ser “CLIENTE CONTADO”. |
| **Mesero** (opcional) | Atribución de pedido / propina en restaurante. |

---

## 6. Catálogo y cliente

### 6.1 Producto

Unidad vendible. Tiene precio, unidad, categoría comercial y **categoría fiscal** (qué impuestos aplican).

Puede pertenecer a páginas/menús (Comida, Bar, etc.) sin cambiar el modelo comercial.

### 6.2 Cliente

- **Contado:** sin documento; se imprime como consumidor final.
- **Registrado:** nombre, documento, teléfono opcional; sirve para crédito, CxC, fidelización futura.

---

## 7. Cadena operativa (venta)

```text
Pedido
  → (opcional) Descuentos / Promociones
  → Cálculo comercial (impuestos, propinas, recargos)
  → Cobro (uno o varios pagos)
  → Venta / cierre comercial
  → Recibo / Factura (documento impreso o fiscal)
  → Caja (movimientos del turno)
  → (Integrado) Sync → EN1 valida / audita / reporta
```

### 7.1 Pedido

Intención de compra: líneas de productos, cantidades, modificadores, mesa/etiqueta opcional.

- Editable mientras esté abierto.
- Dueño operativo: el POS que lo creó (salvo reglas de cobro en otra caja autorizada).

### 7.2 Cobro

Aplicación de uno o más **métodos de pago** contra el total calculado.

- Pago único o mixto.
- Pago parcial / abono cuando la política lo permita.
- Cambio solo donde el método lo permita (p. ej. efectivo).

### 7.3 Venta

Resultado comercial inmutable (o con ciclo de reembolso controlado) de un cobro exitoso:

- Totales congelados (snapshot).
- Líneas, impuestos aplicados, propinas, pagos.
- Referencias a caja, cajero, turno, cliente.

### 7.4 Documento (Recibo / Factura)

Representación imprimible o fiscal de la venta. Su **contenido** lo define el Contrato de Recibo; sus **números fiscales** pueden depender del Contrato Fiscal / FE (fase posterior).

### 7.5 Caja

Acumula movimientos del turno: ventas, pagos por método, entradas/salidas, cierre.

---

## 8. Contratos comerciales y políticas

### 8.1 Idea central

Un **contrato** (o política comercial) es un conjunto versionado de reglas de negocio.

Tipos (mínimo V1 del sprint):

| Tipo | Qué regula |
|------|------------|
| **Fiscal** | Impuestos, categorías, redondeo fiscal, vigencia. |
| **Propinas** | Si aplica, cómo se calcula, si es obligatoria/sugerida, distribución. |
| **Pagos** | Métodos permitidos, mixto, parciales, reembolsos, CxC. |
| **Recibo** | Secciones de impresión, mensajes, QR, papel. |

Más adelante (Motor Comercial): promociones, descuentos avanzados, happy hour, combos.

### 8.2 Asignación (scope)

Una política se asigna a uno o más niveles:

```text
Empresa  →  Sucursal  →  Caja
```

La más específica gana (caja > sucursal > empresa), salvo que el contrato diga lo contrario.

### 8.3 Origen

| Modo | Dónde se crea/edita | Dónde se aplica |
|------|---------------------|-----------------|
| Standalone | Local (admin POS) | Motor local |
| Integrado | EN1 BO | Snapshot en POS + validación EN1 |

**Mismo modelo de datos** en ambos modos.

### 8.4 Vigencia

Toda política tiene: nombre, código, activo, vigencia desde/hasta, versión.

Cambiar una política no reescribe ventas pasadas: las ventas guardan el **resultado calculado** (y, cuando exista, la versión de política aplicada).

---

## 9. Qué calcula el negocio (visión)

Sin detallar el algoritmo aún (eso es Fase 4 — Motor de Totales), el negocio reconoce estas capas:

| Capa | Concepto |
|------|----------|
| Subtotal | Suma de líneas (precio × cantidad − descuentos de línea). |
| Descuentos / promociones | Globales o por regla comercial. |
| Propinas | Según contrato de propinas (antes/después de impuesto según regla). |
| Impuestos | Según contrato fiscal y categoría del producto (pueden ser varios por línea). |
| Recargos | Cargos adicionales (servicio, delivery, etc. — fase posterior). |
| Redondeo | Según política. |
| Total | Monto a cobrar. |
| Pagos | Distribución del total en métodos. |
| Cambio | Si aplica. |

El orden exacto se congela en el **Motor de Totales**, con ejemplos de Panamá.

---

## 10. Escenarios de negocio (mismo modelo)

| Escenario | Particularidades (configuración, no otro producto) |
|-----------|-----------------------------------------------------|
| Restaurante | Mesa, mesero, propina, división de cuenta. |
| Cafetería | Ticket rápido, propina opcional. |
| Food Truck | Pedido + cobro; admin local frecuente. |
| Estación de combustible | Cantidad decimal, unidad, impuestos por producto. |
| Retail | Cliente registrado, varios métodos, reembolsos. |

---

## 11. Límites de este documento

**Incluye:** conceptos, roles, modos, jerarquía, cadena Pedido→Venta→Caja, idea de contratos/políticas.

**No incluye:** tablas, APIs, payloads HTTP, tasas fijas, layout de recibo, algoritmo de centavos, implementación Flutter/EN1.

Esos se definen en Fases 2–5 del V6.

---

## 12. Decisiones abiertas (para Analista / P1 / P2)

1. ¿El “Contrato Comercial” genérico es un contenedor de políticas, o cada tipo (Fiscal, Propina, …) es independiente con el mismo motor de asignación?  
   **Propuesta:** independientes + motor de políticas unificado (scope + vigencia + versión).
2. ¿En Integrado, si EN1 recalcula distinto al POS offline, gana EN1 siempre o hay ventana de tolerancia?  
   **Propuesta:** gana EN1; divergencias se registran y se notifican (detalle en Motor de Totales).
3. ¿Recargos (servicio hotelero, delivery) entran en V1 del Motor Comercial o fase 2?  
   **Propuesta:** fase 2; el modelo ya reserva el concepto.

---

## 13. Criterio de aprobación

Este modelo se considera **aprobado** cuando Analista + P1 + P2 confirman:

- Dual Mode y origen de datos.  
- Jerarquía Empresa→…→Caja/Cajero/Turno.  
- Cadena Pedido → Cobro → Venta → Documento → Caja.  
- Contratos/políticas como unidad de regla de negocio.  
- Listo para redactar Contrato Fiscal (Fase 2.1) sin reabrir estos conceptos.

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Borrador V1: dual-mode, jerarquía, cadena operativa, contratos/políticas, límites y abiertas. |
