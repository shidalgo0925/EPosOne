# Spec Motor Comercial EPosOne V1

| Campo | Valor |
|-------|--------|
| **Estado** | Borrador — revisión Analista / P1 / P2 |
| **Fecha** | 19 jul 2026 |
| **Versión** | v1.0-draft |
| **Roadmap** | [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md) |
| **Depende de** | Modelo Comercial · Tax · Tip · Pagos · Print |
| **Siguiente** | Fase 4 — Motor de Totales |
| **Alcance** | Reglas de descuento, promoción y precio. **Sin** algoritmo de centavos final (eso es Totales) ni APIs. |

---

## 1. Propósito

Definir el **Motor Comercial**: el conjunto de reglas que modifican precios y bases **antes** (y de forma controlada) del cálculo fiscal y de propinas.

Responde: ¿qué descuentos, promociones y precios especiales pueden aplicar a un pedido, en qué orden, con qué límites y con qué auditoría?

Dual-mode: misma lógica; políticas locales o sync desde EN1.

---

## 2. Principios

| # | Regla |
|---|--------|
| 1 | El Motor Comercial **no** inventa impuestos ni propinas; solo altera bases comerciales. |
| 2 | Toda regla es una **política versionada** con scope Empresa → Sucursal → Caja. |
| 3 | Las reglas tienen **prioridad**, **exclusividad** y **apilamiento** explícitos. |
| 4 | El resultado se materializa en el pedido/venta como ajustes auditables (no “magia” en UI). |
| 5 | Sin política activa: solo precio de lista y descuentos manuales permitidos por permiso. |
| 6 | Ventas pasadas no se recalculan si cambia una promo. |

---

## 3. Entradas y salidas

### Entrada

- Pedido (líneas: producto, qty, precio lista, modificadores).
- Cliente (opc.: segmento / membresía).
- Contexto: sucursal, caja, fecha/hora local, canal (POS).
- Políticas comerciales vigentes + permisos del cajero.

### Salida (hacia Motor de Totales)

- Precio efectivo por línea.
- Descuentos de línea (monto/%).
- Descuentos / promos de documento (globales) con **prorrateo** declarado.
- Flags: líneas excluidas de promo, consumo mínimo, etc.
- Trace: qué reglas dispararon (código + versión).

---

## 4. Tipos de reglas comerciales

### 4.1 Descuento manual

| Variante | Descripción |
|----------|-------------|
| Línea — monto | Resta monto fijo a la línea. |
| Línea — % | % sobre (precio × qty). |
| Documento — % | % sobre subtotal elegible. |
| Documento — monto | Monto fijo sobre el ticket. |

Requisitos: permiso, tope máximo (%/monto), motivo opcional/obligatorio según política.

### 4.2 Cupón

- Código, vigencia, usos, compra mínima.
- Tipo: % o monto fijo.
- Elegibilidad: todo el ticket o categorías/productos.
- Apilamiento con otras promos: según política del cupón.

*(Hoy existe cupón premium mínimo; este spec lo formaliza.)*

### 4.3 Promoción automática

Dispara sin código si se cumplen condiciones.

| Tipo | Ejemplo |
|------|---------|
| Happy Hour | −20% en categoría Bar 17:00–19:00. |
| 2x1 / NxM | Lleva 2 paga 1 en producto X. |
| Combo | Productos A+B a precio pack. |
| Precio por horario | Precio distinto en franja. |
| Precio por sucursal | Lista de precios por scope. |
| Segmento / membresía | % socios (fase 2 operativa). |

### 4.4 Recargos comerciales (reserva)

Servicio, delivery, empaque: **modelo reservado**; implementación post-V1 salvo que Totales los necesite como capa vacía (monto 0).

---

## 5. Estructura de una política / regla

| Campo | Descripción |
|-------|-------------|
| Código / Nombre | Estable + etiqueta. |
| Tipo | manual_discount · coupon · happy_hour · bogo · combo · price_list · … |
| Activo / Vigencia / Versión | |
| Scope | Empresa / Sucursal / Caja |
| Prioridad | Entero; menor = se evalúa antes (o según convención congelada en Totales). |
| Stackable | Sí/No. Si No, bloquea otras del mismo grupo. |
| Grupo de exclusividad | Ej. `auto_promo` vs `coupon` vs `manual`. |
| Condiciones | Ver §6. |
| Beneficio | Ver §7. |
| Límites | Máx. % , máx. monto, usos por día, una vez por ticket. |
| Auditoría | Requiere motivo / aprobación encargado. |

---

## 6. Condiciones (match)

Una regla aplica si **todas** las condiciones activas se cumplen:

| Condición | Ejemplos |
|-----------|----------|
| Tiempo | Días semana, franja horaria (zona local negocio). |
| Catálogo | Productos, categorías, páginas POS. |
| Cantidad | Qty ≥ N en línea o en grupo. |
| Importe | Subtotal elegible ≥ mínimo. |
| Cliente | Contado / registrado / segmento. |
| Canal | Solo POS (V1). |
| Exclusiones | SKUs que nunca entran a la base de promo. |

---

## 7. Beneficio (efecto)

| Efecto | Descripción |
|--------|-------------|
| `%_off_line` | Descuento % en líneas elegibles. |
| `amount_off_line` | Monto en líneas (repartido si aplica). |
| `%_off_ticket` | % global sobre base elegible. |
| `amount_off_ticket` | Monto global. |
| `fixed_price_line` | Precio unitario forzado. |
| `bogo` | Unidades gratis / a precio reducido según NxM. |
| `combo_price` | Precio del conjunto. |

El Motor de Totales convierte estos efectos en montos monetarios redondeados.

---

## 8. Orden de evaluación (comercial)

Propuesta (se congela numéricamente en Motor de Totales):

```text
1. Precio de lista (o price_list / horario / sucursal)
2. Promos automáticas (prioridad + exclusividad)
3. Combos / BOGO
4. Cupones
5. Descuentos manuales de línea
6. Descuentos manuales de documento
7. Resultado → base para impuestos/propinas (según Totales)
```

Si dos reglas no son stackable y chocan: gana la de **mayor beneficio para el cliente** o la de **mayor prioridad** — **decisión abierta**; debe quedar una sola en Totales.

**Propuesta:** mayor prioridad (número menor) gana; si empate, mayor descuento.

---

## 9. Prorrateo de descuentos globales

Un descuento de documento debe **asignarse a líneas** para:

- Base imponible por línea (Tax).
- Reembolsos parciales.
- Reportes por producto.

Método propuesto V1: proporcional al subtotal elegible de cada línea (tras descuentos de línea).

Líneas excluidas de promo no reciben prorrateo de esa promo.

---

## 10. Permisos y auditoría

| Acción | Control |
|--------|---------|
| Descuento manual sobre tope | Requiere encargado. |
| Eliminar promo automática | Solo si la política lo permite. |
| Aplicar cupón inválido | Rechazo. |
| Trace | Cada ajuste: regla, usuario, timestamp, monto. |

---

## 11. Relación con otros motores

| Motor | Relación |
|-------|----------|
| Totales | Consume la salida de §3; aplica orden Pedido→Desc→Promo→Propina→Impuesto→Redondeo→Total (V6). |
| Fiscal | Usa bases ya descontadas según Tax Contract. |
| Propinas | Base tip puede excluir líneas “no propinables”. |
| Pagos | Cobra el total final; no conoce promos. |
| Recibo | Imprime descuentos y, si hay espacio, nombre de promo. |

---

## 12. Dual Mode

| | Standalone | Integrado |
|---|------------|-----------|
| Alta de promos | Admin local | EN1 BO |
| Price list | Local | EN1 |
| Evaluación en cobro | Motor local | Local + validación EN1 al sync |

---

## 13. Fuera de alcance V1 (implementación)

- Motor de membresías completo.
- Promos personalizadas por IA / campañas externas.
- Marketplace de cupones de terceros.
- Recargos hotel/delivery (solo reserva de modelo).

Sí entra en el **modelo**: happy hour, 2x1, combo, cupón, descuento manual, precio por horario/sucursal.

---

## 14. Criterios de aceptación

1. Tipos de regla y beneficios definidos.  
2. Condiciones de match claras.  
3. Prioridad / stack / exclusividad declarados.  
4. Prorrateo global definido.  
5. Trace de reglas en el resultado.  
6. Dual-mode explícito.  
7. Sin fórmulas de centavos finales (delegadas a Totales).

---

## 15. Decisiones abiertas

1. Conflicto stackable: ¿prioridad o mayor descuento? **Propuesta: prioridad, empate → mayor descuento.**  
2. ¿Cupón puede sumar a happy hour por default? **Propuesta: no, salvo `stackable=true` en ambos.**  
3. ¿BOGO reduce qty cobrada o agrega línea “bonus $0”? **Propuesta: ajuste de monto en líneas elegibles (más simple para tax).**

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Borrador V1: tipos, condiciones, beneficios, orden, prorrateo, dual-mode. |
