# Contrato de Propinas EPosOne V1

| Campo | Valor |
|-------|--------|
| **Estado** | Borrador — revisión Analista / P1 / P2 |
| **Fecha** | 19 jul 2026 |
| **Versión** | v1.0-draft |
| **Roadmap** | [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md) |
| **Depende de** | [`EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md`](EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md) · [`EPOSONE_TAX_CONTRACT_V1.md`](EPOSONE_TAX_CONTRACT_V1.md) |
| **Siguiente** | Contrato de Pagos |
| **Alcance** | Políticas de propina. **Sin** tablas SQL ni payloads HTTP. |

---

## 1. Propósito

Definir cuándo y cómo se calcula, presenta, modifica y distribuye la **propina** en una venta, de forma idéntica en Standalone e Integrado (solo cambia el origen de la política).

La propina **nunca se mezcla con impuestos** en impresión ni en reportes.

---

## 2. Principios

| # | Regla |
|---|--------|
| 1 | Un **Contrato de Propinas** es una política versionada (scope Empresa → Sucursal → Caja). |
| 2 | Si la empresa **no usa propinas**, el contrato está inactivo o en modo `none`: el POS no ofrece propina. |
| 3 | La propina es una capa comercial distinta de impuestos, descuentos y recargos. |
| 4 | El cajero solo hace lo que la política permite (modificar, eliminar, omitir). |
| 5 | Ventas pasadas conservan el monto de propina del snapshot; no se recalculan con políticas nuevas. |
| 6 | El **orden exacto** respecto a impuestos lo congela el Motor de Totales; este contrato declara la **base** y el **modo de aplicación**. |

---

## 3. Datos generales de la política

| Campo | Descripción |
|-------|-------------|
| Nombre | Ej. “Propina restaurante sugerida 10%”. |
| Código | Estable (ej. `TIP-REST-SUG-10`). |
| Activo | Sí/No. |
| Vigencia | Desde / hasta. |
| Versión | Incrementa al publicar cambios. |
| Empresa usa propinas | Master switch; si No → modo `none`. |

### Origen

| Modo | Edición | Aplicación |
|------|---------|------------|
| Standalone | Admin local POS | Motor local |
| Integrado | EN1 BO | Snapshot POS + validación EN1 |

---

## 4. Modo de aplicación

| Modo | Comportamiento en cobro |
|------|-------------------------|
| `none` | No se muestra propina. Equivale a “No aplica”. |
| `optional` | El cajero puede agregar o dejar en cero. |
| `suggested` | Se proponen % o montos; el cajero puede aceptar, cambiar o (si se permite) quitar. |
| `mandatory` | Debe haber propina ≥ mínimo de la política antes de confirmar cobro. |

### Permisos de edición

| Permiso | Si está OFF |
|---------|-------------|
| Permitir modificar | Solo se acepta el valor sugerido/automático. |
| Permitir eliminar / poner en cero | No se puede quitar propina (salvo rol autorizado — fase permisos). |
| Permitir monto personalizado | Solo chips/porcentajes de la política. |

---

## 5. Cálculo

### 5.1 Método

| Método | Descripción |
|--------|-------------|
| `percent` | Porcentaje sobre la base (§5.2). |
| `fixed` | Monto fijo por cuenta / por comensal (configurable). |
| `tiered` | Escalonada por rangos de consumo (tabla de tramos). |
| `by_consumption` | Reglas según umbral de consumo mínimo. |
| `auto_percent` | Se aplica sola al entrar a cobro (suele ir con `mandatory` o `suggested`). |

Una política activa declara **un método principal** y, si es `suggested`, una lista de opciones (ej. 10%, 15%, 20% + “Otro monto” si está permitido).

### 5.2 Base de cálculo

| Base | Significado |
|------|-------------|
| `subtotal_gross` | Suma líneas antes de descuentos. |
| `subtotal_net` | Tras descuentos de línea. |
| `subtotal_after_promos` | Tras descuentos/promos globales asignados. |
| `pre_tax_total` | Base comercial antes de impuestos. |
| `post_tax_total` | Tras impuestos (propina sobre total con impuesto). |

La política elige **una** base. El Motor de Totales usará esa elección de forma determinista.

**Propuesta default V1 (restaurante PA):** `suggested` + `percent` sobre `post_tax_total` (como hoy en el POS), configurable por contrato.

### 5.3 Consumo mínimo / exclusiones

| Regla | Descripción |
|-------|-------------|
| Consumo mínimo | No sugerir/obligar propina si la base &lt; umbral. |
| Excluir productos | SKUs o categorías (ej. retail empaque) fuera de la base. |
| Excluir impuestos | La base puede ser solo neto de ciertas líneas. |
| Excluir propina previa | En división de cuenta, no duplicar. |

### 5.4 Redondeo

Misma precisión monetaria que el Motor de Totales (propuesta: 2 decimales half-up sobre el monto de propina).

---

## 6. Momento de captura

| Momento | Uso |
|---------|-----|
| En pantalla de cobro | Default V1. |
| En el pedido (antes de cobro) | Opcional futuro (mesa). |
| Post-pago ajuste | Solo con permiso y auditoría (fuera de V1 mínimo). |

La propina forma parte del **total a cobrar** cuando está definida antes de confirmar pagos.

---

## 7. Distribución (atrribución)

Opcional en V1 de impresión; obligatorio declarar el modelo para reportes futuros.

| Destino | Descripción |
|---------|-------------|
| Meseros | Pool o por empleado del pedido. |
| Cajeros | Quien cobró. |
| Cocina / Barra | Porcentaje del pool. |
| Delivery | Repartidor. |
| Fondo común | Sin atribución individual. |
| Personalizada | Tabla de % que suma 100%. |

Si no hay distribución configurada: se registra propina a nivel venta/turno sin split (suficiente para V1 de cobro).

---

## 8. División de cuenta

| Caso | Regla |
|------|-------|
| Split por ítems | Propina se calcula sobre el subtotal/total de la parte cobrada, según la misma política. |
| Split igual | Propina por parte o propina total prorrateada (la política elige; **propuesta:** calcular por parte). |
| Re-cobro parcial | No arrastrar propina ya cobrada a la parte restante. |

Detalle fino → Motor de Totales + Contrato de Pagos.

---

## 9. Relación con impuestos y pagos

| Tema | Regla |
|------|--------|
| Gravamen de propina | Si la propina genera impuesto, será una regla fiscal explícita (raro en PA retail; default **no gravar propina**). |
| Métodos de pago | La propina se incluye en el total; los tenders cubren total con propina. No hay “propina en Yappy” separada salvo que el Contrato de Pagos lo defina después. |
| Reembolso | La propina del snapshot se revierte proporcionalmente con el reembolso (Contrato de Pagos). |

---

## 10. Impresión

El Contrato de Recibo debe poder mostrar, según política de impresión:

```text
Propina sugerida     5.00
Propina pagada       4.00
```

o

```text
Propina              No aplica
```

o

```text
Propina              4.00
```

Nunca sumar propina dentro de la línea de ITBMS/ISC.

---

## 11. Snapshot en la venta

Conservar:

- Código y versión del contrato de propinas.
- Modo (`suggested`, etc.) y método (`percent`…).
- Base usada y valor de base.
- Porcentaje o monto fijo elegido.
- Monto de propina.
- Quién la modificó (cajero), si aplica.
- Distribución aplicada (si existe).

---

## 12. Fuera de alcance V1

- Tip pooling avanzado y liquidación de personal.
- Propina automática por canal delivery externo.
- Integración con terminal bancaria “tip line” del voucher.
- Propinas post-cierre de turno.

---

## 13. Criterios de aceptación

1. Empresa puede desactivar propinas por completo.  
2. Obligatoria / sugerida / opcional están definidos.  
3. Base de cálculo es configurable (no hardcode solo post-tax).  
4. Modificar/eliminar respetan permisos de la política.  
5. Exclusiones y consumo mínimo están previstos.  
6. Impresión separada de impuestos.  
7. Dual-mode explícito.

---

## 14. Decisiones abiertas

1. Default base: ¿`post_tax_total` o `pre_tax_total`? **Propuesta: post_tax (compatibilidad UX actual), configurable.**  
2. ¿Propina obligatoria puede ser 0 con autorización de encargado? **Propuesta: sí, con auditoría (fase permisos).**  
3. ¿Distribución entra en freeze V1 o se deja “registrada / no liquidada”? **Propuesta: modelo declarado; liquidación fase 2.**

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Borrador V1: modos, cálculo, base, permisos, distribución, split, impresión, snapshot. |
