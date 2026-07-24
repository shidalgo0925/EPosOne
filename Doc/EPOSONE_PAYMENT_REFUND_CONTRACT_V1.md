# Contrato de Pagos y Reembolsos EPosOne V1

| Campo | Valor |
|-------|--------|
| **Estado** | Borrador — revisión Analista / P1 / P2 |
| **Fecha** | 19 jul 2026 |
| **Versión** | v1.0-draft |
| **Roadmap** | [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md) |
| **Depende de** | [`EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md`](EPOSONE_COMMERCIAL_BUSINESS_MODEL_V1.md) · Tip · Tax |
| **Siguiente** | Contrato de Recibo |
| **Relacionado (operativo)** | Order Domain — `OrderPayment` 0..N · tender methods POS actuales |
| **Alcance** | Reglas de cobro y devolución. **Sin** payloads HTTP nuevos ni tablas. |

---

## 1. Propósito

Definir cómo se **cobra** el total de una venta (uno o varios métodos), cómo se maneja el **cambio**, los **parciales/abonos**, las **cancelaciones** y los **reembolsos**, igual en Standalone e Integrado.

El catálogo de métodos es **configurable por política**; los códigos actuales del POS (`cash`, `visa`, `yappy`…) son el set inicial de referencia, no un hardcode eterno.

---

## 2. Principios

| # | Regla |
|---|--------|
| 1 | Un cobro completo cubre el **total calculado** (incluye propina si aplica). |
| 2 | **Pago mixto** = N líneas de pago (tenders) cuya suma aplicada = total (salvo CxC/parcial permitido). |
| 3 | Solo métodos con `allows_change` pueden generar **cambio**. |
| 4 | La venta (y el pedido) conservan tenders **estructurados**, no un único “método colapsado”. |
| 5 | Reembolsos operan sobre el **snapshot** de pagos e impuestos de la venta origen. |
| 6 | Dual-mode: misma política; origen local o EN1. |
| 7 | Idempotencia: un mismo cobro/reembolso no se aplica dos veces. |

---

## 3. Contrato / política de pagos

### 3.1 Datos generales

| Campo | Descripción |
|-------|-------------|
| Nombre / Código | Identificador de la política. |
| Activo / Vigencia / Versión | Igual que otras políticas. |
| Métodos habilitados | Subconjunto del catálogo (§4). |
| Permite mixto | Sí/No (default Sí). |
| Permite parcial / abono | Sí/No. |
| Permite CxC | Sí/No (requiere cliente registrado). |
| Moneda | Alineada a la empresa. |

### 3.2 Scope

Empresa → Sucursal → **Caja** (una caja puede restringir métodos: solo efectivo, sin crédito, etc.).

### 3.3 Origen

| Modo | Edición | Aplicación |
|------|---------|------------|
| Standalone | Admin local | Motor + UI local |
| Integrado | EN1 BO | Snapshot + sync de pagos |

---

## 4. Catálogo de métodos (tenders)

Cada método declara:

| Atributo | Descripción |
|----------|-------------|
| Código | Estable (`cash`, `visa`, `yappy`…). |
| Nombre | Etiqueta UI/recibo. |
| Activo | En esta política. |
| Permite cambio | Solo efectivo (u otros que se configuren). |
| Referencia | `none` · `optional` · `required` (auth, voucher, last4…). |
| Requiere cliente | Ej. crédito cliente. |
| Afecta gaveta | Si abre caja registradora. |
| Es cuenta por cobrar | No liquida cash; deja saldo. |
| Preparado / futuro | Gift card, depósito (modelo listo; operación completa fase 2). |

### 4.1 Set inicial de referencia (ya en POS)

| Código | Nombre | Cambio | Referencia |
|--------|--------|--------|------------|
| `cash` | Efectivo | Sí | none |
| `visa` | Visa | No | required |
| `mastercard` | Mastercard | No | required |
| `clave` | Clave | No | required |
| `yappy` | Yappy | No | required |
| `ach` | ACH | No | required |
| `voucher` | Vale | No | optional |
| `customer_credit` | Crédito Cliente | No | none/cliente |
| `gift_card` | Gift Card | No | required (preparado) |
| `other` | Otros | No | optional |

Se pueden agregar métodos sin cambiar el contrato base (nueva fila de catálogo).

---

## 5. Tipos de cobro

### 5.1 Pago único

Una línea tender = total. Cambio solo si el método lo permite y el monto recibido &gt; total.

### 5.2 Pago múltiple (mixto)

Varias líneas; reglas:

1. Métodos no-efectivo **no pueden exceder** el saldo restante.
2. Efectivo puede exceder el resto → genera **cambio**.
3. Referencias obligatorias deben estar completas antes de confirmar.
4. Suma de montos **aplicados** (sin el vuelto) = total a cobrar.

### 5.3 Pago parcial / abono

Si la política lo permite:

- Se registra un cobro &lt; total del pedido.
- El pedido queda con **saldo pendiente**.
- No se cierra como venta completa hasta saldo 0 (o se convierte en CxC).

Detalle de estados de pedido: Order Domain (ya congelado); este contrato no lo reabre.

### 5.4 Cuenta por cobrar (CxC)

- Requiere cliente registrado.
- Método `customer_credit` (u otro marcado CxC) deja el monto como deuda.
- Límites de crédito, aging y cobro posterior: fase 2 (modelo preparado).

### 5.5 Gift Card / Depósitos

- **Preparados** en catálogo y en este contrato.
- Emisión, saldo y redención completa: fuera de implementación V1; no bloquear el diseño.

---

## 6. Cambio (vuelto)

| Regla | Detalle |
|-------|---------|
| Quién | Solo tenders con `allows_change`. |
| Cálculo | `recibido_efectivo − saldo_cubierto_por_efectivo`. |
| Impresión | Mostrar cambio solo si &gt; 0. |
| Caja | El efectivo esperado en gaveta = recibido − cambio. |

---

## 7. Cancelaciones

| Momento | Regla |
|---------|--------|
| Antes de confirmar cobro | Se descarta el intento; no hay tender persistido. |
| Pedido anulado (Order Domain) | Si había abonos, deben revertirse o reasignarse según política (propuesta: reembolso de abonos). |
| Post-venta | No es cancelación: es **reembolso** (§8). |

---

## 8. Reembolsos

### 8.1 Tipos

| Tipo | Descripción |
|------|-------------|
| Total | Devuelve el 100% de la venta (líneas + impuestos + propina del snapshot). |
| Parcial | Por líneas/cantidades/monto; recalcula o prorratea según Motor de Totales + Tax. |

### 8.2 Ruta de dinero

| Política | Comportamiento |
|----------|----------------|
| `mirror_original` | Devolver por los mismos métodos y proporciones del cobro origen. |
| `cash_only` | Todo el reembolso en efectivo (si hay caja). |
| `choose` | Encargado elige métodos hasta cubrir el monto a devolver. |

**Propuesta V1:** `mirror_original` con fallback a efectivo si un método no es reversible en caja (tarjeta/Yappy sin integración de void).

### 8.3 Límites

- No reembolsar más que lo cobrado neto ya reembolsado.
- Múltiples reembolsos parciales hasta agotar saldo reembolsable.
- Motivo / permiso de encargado: recomendado; detalle en fase permisos.
- Inventario: si `trackInventory`, restaurar cantidades de líneas devueltas (ya existe en refund total local).

### 8.4 Fiscal

El reembolso fiscal sigue el Contrato Fiscal (snapshot). Documento nota de crédito: Contrato de Recibo / FE posterior.

---

## 9. Persistencia del cobro (requisito de modelo)

Toda venta cobrada debe conservar:

```text
tenders[]:
  - code
  - label
  - amount_applied   (sin vuelto)
  - amount_received  (si aplica)
  - change
  - reference
  - paid_at
  - cashier_id
```

**Gap actual a cerrar en implementación (post-freeze):** `Sale` hoy colapsa a un solo `PaymentMethod` y el mixto queda en notes. El Order Domain ya tiene `OrderPayment` 0..N — la venta local debe alinearse.

---

## 10. Propina y pagos

El total a cubrir = total comercial + propina (según Tip Policy).

No se exige tender separado “solo propina” en V1; la propina va dentro del total. Reportes de propina usan el snapshot de Tip, no el método de pago.

---

## 11. Impresión

El Contrato de Recibo muestra:

```text
Métodos de pago:
  Efectivo     20.00
  Visa         50.00
  Yappy        15.00
Cambio          2.00    (solo si aplica)
```

Una línea por tender; referencias opcionales según política de impresión.

---

## 12. Caja / turno

- Cada tender con `afecta_gaveta` impacta el efectivo del turno.
- Cierre de caja consolida por código de método (no por el enum colapsado).
- Reembolsos en efectivo reducen efectivo esperado.

---

## 13. Dual Mode

| Evento | Standalone | Integrado |
|--------|------------|-----------|
| Cobro | Local | Local + sync pagos a EN1 |
| Reembolso | Local | Local + evento/sync EN1 |
| Catálogo métodos | Política local | Política EN1 |

---

## 14. Fuera de alcance V1

- Liquidación real de gift card / depósitos.
- Void automático con adquirente bancario.
- CxC aging, intereses, estados de cuenta.
- Propina post-cargo en voucher bancario.

---

## 15. Criterios de aceptación

1. Mixto con N tenders y cambio solo en efectivo.  
2. Referencias required/optional respetadas.  
3. Parcial/abono y CxC definidos (aunque CxC operativa sea fase 2).  
4. Reembolso total/parcial + ruta de dinero.  
5. Snapshot estructurado de tenders obligatorio.  
6. Dual-mode explícito.  
7. Sin inventar HTTP: alinear a Order Domain existente en implementación.

---

## 16. Decisiones abiertas

1. ¿Reembolso tarjeta sin void = obligatorio efectivo? **Propuesta: sí, con motivo.**  
2. ¿Un mismo método dos veces en mixto (dos Visa)? **Propuesta: permitir (dos referencias).**  
3. ¿Saldo pendiente de abono bloquea cierre de turno? **Propuesta: advertencia, no bloqueo duro (configurable).**

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Borrador V1: catálogo, mixto, parcial, CxC/gift preparado, cambio, reembolsos, persistencia tenders, caja. |
