# ADR-036 — Modos de Operación de Caja y Cadena de Custodia del Efectivo

| Campo | Valor |
|-------|--------|
| **Estado** | **Aceptado** (decisión de producto) · implementación **bloqueada** hasta delta EN1 |
| **Fecha** | 10 de agosto de 2026 |
| **Prioridad** | Alta |
| **Tipo** | Arquitectura funcional y operativa |
| **Sistemas** | EP1 (APK) · EN1 (config, consolidación, auditoría) |
| **Default** | `SIMPLE` |
| **Relacionado** | Cash Shift HTTP v1 · Order Domain · Hito 2.5 cajero · [`ADR-016`](ADR-016-EPOSONE-OPERATIONS-CONTROL-CENTER.md) |

---

## 1. Contexto

EP1 permite que distintos vendedores/cajeros usen un mismo dispositivo identificándose con PIN.

Cada transacción puede conservar la identidad de quien la ejecutó. El modelo actual, basado en `cashRegisterId`, agrupa operaciones dentro del **mismo turno de caja**. Eso es correcto cuando la misma persona registra, cobra, custodia el efectivo y cierra.

El problema aparece cuando coexisten:

- varios vendedores de piso;
- dispositivos compartidos o individuales;
- una o varias cajas físicas;
- vendedores que reciben efectivo del cliente;
- cajeros responsables de recibir ese efectivo y custodiarlo.

Conocer solo quién vendió **no** basta para saber quién tenía la custodia del efectivo ante una diferencia.

---

## 2. Decisión

EPosOne soporta **dos modos** de operación de efectivo, configurables desde EN1 por **organización / sucursal**.

| Código | Nombre | Uso |
|--------|--------|-----|
| `SIMPLE` | Caja simple | Flujo actual: una persona hace el ciclo completo |
| `CHAIN_OF_CUSTODY` | Caja central con cadena de custodia | Vendedores de piso + responsable(s) de caja |

### Principio (congelado)

> EPosOne **no** asume que “quien vende”, “quien cobra” y “quien custodia la caja” son siempre la misma persona.  
> En operaciones simples pueden coincidir (`SIMPLE`).  
> Cuando hay piso / dispositivos compartidos / varios custodios, se habilita explícitamente `CHAIN_OF_CUSTODY`.

### Relación con dominios existentes (no reabrir)

> El **turno de caja** (`Cash Shift` / `cashRegisterId`) permanece como unidad de arqueo físico.  
> `CHAIN_OF_CUSTODY` **añade** eventos de custodia de efectivo entre vendedor y caja.  
> **No** redefine Order Domain `pedido.cobrado` ni el contrato Cash Shift HTTP v1.

---

## 3. Modo A — `SIMPLE` (Caja simple)

Flujo:

```text
Pedido → Despachado → Cobrado/Pagado
```

- El cobro finaliza financieramente la operación y **afecta directamente** el efectivo esperado del turno (comportamiento actual).
- No requiere transferencia de custodia.
- Ejemplos: pequeño comercio, caja fija, propietario-operador, restaurante con cajero único.

**Default de toda org/sucursal nueva o sin flag:** `SIMPLE`.

---

## 4. Modo B — `CHAIN_OF_CUSTODY`

Flujo:

```text
PEDIDO → DESPACHADO → COBRADO → CONFIRMADO EN CAJA
```

Cada estado es un hecho operativo y, cuando corresponde, un cambio de responsabilidad sobre el efectivo.

### 4.1 Semántica de estados

| Estado | Significado | Responsable |
|--------|-------------|-------------|
| PEDIDO | Se genera la operación | Vendedor |
| DESPACHADO | Mercancía/servicio entregado | Vendedor / despacho |
| COBRADO | El vendedor recibió el dinero del cliente | Vendedor |
| CONFIRMADO EN CAJA | Caja recibió, verificó y aceptó el dinero | Responsable de caja |

**Diferencia fundamental:**

- `COBRADO` ≠ el efectivo ya está en el cajón.  
  Significa: dinero pasó del **cliente → vendedor**.
- `CONFIRMADO EN CAJA` = dinero pasó del **vendedor → responsable de caja**.

### 4.2 Alcance de medios de pago (v1)

- Cadena de custodia física aplica a **efectivo (cash)** únicamente.
- Tarjeta / otros medios: no generan “pendiente de entregar a caja”; el cobro financiero sigue las reglas Order Domain.
- Pagos mixtos: solo la porción **cash** entra a pendiente / confirmación.

---

## 5. Cadena de custodia (eventos)

En modo B, cada transición registra como mínimo:

- transacción / pedido;
- estado anterior → estado nuevo;
- usuario responsable;
- `cashier_contact_id` (cuando aplique);
- dispositivo / POS;
- fecha y hora (timezone contract);
- importe;
- método de pago;
- caja / turno relacionado cuando corresponda.

Propiedades:

- auditables;
- no eliminables;
- correcciones / anulaciones = **nuevos eventos** (no borrar evidencia).

EN1 debe poder reconstruir la secuencia completa.

Ejemplo:

```text
18:02 — Ana — Pedido — $100
18:08 — Ana — Despachado — $100
18:15 — Ana — Cobrado efectivo — $100
18:18 — María / Caja 1 — Confirmado en caja — $100
```

Entre 18:15 y 18:18 los $100 están bajo custodia de Ana.  
A las 18:18 la custodia pasa a Caja 1 / María.

### 5.1 Shape conceptual del evento (delta EN1 pendiente)

Entidad / evento de custodia (**aparte** de `pedido.cobrado`), p. ej.:

- `cash_custody.collected` — vendedor declara cobro cash al cliente  
- `cash_custody.confirmed_at_register` — caja confirma recepción  

El shape HTTP exacto lo congela EN1; EP1 **no inventa** el payload.

---

## 6. Regla contable del efectivo

| Estado | Venta/cobro | Efectivo esperado del cajón (turno) |
|--------|-------------|--------------------------------------|
| `COBRADO` sin confirmar | Cuenta como cobro realizado; queda **pendiente de entregar** | **No** incrementa |
| `CONFIRMADO EN CAJA` | Transferencia aceptada | **Sí** incrementa el esperado del turno de esa caja |

Separa explícitamente:

- dinero en vendedores;
- dinero físicamente confirmado en cajas.

---

## 7. Confirmación bilateral

1. Vendedor: declara que cobró al cliente (`COBRADO`).
2. Cajero: confirma que recibió el efectivo (`CONFIRMADO EN CAJA`).

El vendedor **no** puede auto-confirmar recepción en caja, salvo que su rol tenga a la vez responsabilidad autorizada sobre esa caja.

---

## 8. Vistas operativas (EP1)

### Vendedor — EFECTIVO PENDIENTE DE ENTREGA

Ejemplo: Ana — 3 ops — $245 pendientes.

### Caja — PENDIENTES DE RECIBIR EN CAJA

El cajero identifica la operación, verifica importe y confirma.

---

## 9. Diferencias y responsabilidad

El ADR **no** afirma automáticamente sustracción. Determina **en qué tramo** aparece la diferencia.

| Cadena | Lectura |
|--------|---------|
| … → Cobrado → **no** confirmado | Efectivo cobrado pendiente bajo custodia del **vendedor** |
| … → Cobrado → Confirmado en caja | Transferencia aceptada; diferencias posteriores = ámbito del **turno/caja** |

---

## 10. Cierre del vendedor (modo B)

Resumen visible:

- ventas realizadas;
- cobros realizados;
- efectivo entregado y confirmado;
- efectivo pendiente de entregar.

Un vendedor **no** debería completar su cierre operativo con pendiente > 0, salvo excepción autorizada y auditada.

---

## 11. Cierre de caja (turno)

El responsable cierra el **turno de caja**, no el cierre individual de cada vendedor.

Efectivo esperado del cajón =

- operaciones `CONFIRMADO EN CAJA` (cash);
- + fondos / entradas / salidas del turno;
- **sin** inflar con cobros solo `COBRADO` pendientes.

Al cierre pueden coexistir:

| Concepto | Ejemplo |
|----------|---------|
| Esperado físicamente en caja | $2,850 |
| Efectivo pendiente en vendedores | $150 |
| Cobros cash totales | $3,000 |

Así el cajero no aparece con faltante de $150 que aún está en manos de vendedores.

---

## 12. Dispositivos compartidos

La identidad operativa pertenece al **usuario / PIN**, no al dispositivo.

- Tablet A → Ana PIN → ops de Ana.  
- Carlos PIN → nuevas ops de Carlos.  

Cambiar de usuario **no** abre un turno nuevo por sí solo (invariante Cash Shift).

---

## 13. Múltiples cajas

Una operación cobrada se confirma en la **caja que recibió** el efectivo (turno activo de esa caja).

v1 EP1: device provisionado a una caja (`register_ref`); la confirmación ocurre en el POS de esa caja.  
Selección libre “entregar a Caja N” desde cualquier device = fase posterior (requiere contrato EN1).

---

## 14. Responsabilidades EP1 / EN1

| Actor | Responsabilidad |
|-------|-----------------|
| **EP1** | PIN, pedido, despacho, cobro, pendientes, confirmación, arqueo, cierre; registro local de eventos |
| **EN1** | Modo por org/sucursal; recepción de eventos; trazabilidad; análisis; políticas de excepción |

EN1 **no** es necesario en línea para completar una entrega física de efectivo en operación normal (offline-first).

---

## 15. Offline

La cadena funciona sin EN1:

- eventos locales con identidad, secuencia, timestamps, importes, caja, vendedor, receptor, estado;
- sync posterior sin reconstruir ni borrar la cadena.

---

## 16. Invariantes

1. No hay `CONFIRMADO_EN_CAJA` sin cobro cash previo.  
2. Todo cobro cash identifica quién recibió del cliente.  
3. Toda confirmación identifica quién recibió en caja.  
4. `COBRADO` y `CONFIRMADO_EN_CAJA` son eventos distintos en modo B.  
5. Cambiar de dispositivo no cambia la identidad del responsable.  
6. Cambiar de usuario en un device no cambia el turno de caja por sí mismo.  
7. Una operación confirmada no desaparece del historial.  
8. Correcciones = nuevos eventos.  
9. Cierre de caja = efectivo confirmado en esa caja (+ movimientos de turno).  
10. Efectivo cobrado no entregado permanece explícitamente pendiente.  
11. Default sin config EN1 = `SIMPLE`.  
12. EP1 no implementa modo B sin flag + shape de eventos congelados por EN1.

---

## 17. Configuración conceptual

```text
cash_operation_mode: SIMPLE | CHAIN_OF_CUSTODY
```

Fuente de verdad: EN1 (org / sucursal) → bootstrap / políticas hacia EP1.

---

## 18. Secuencia de implementación

| Paso | Dueño | Entrega |
|------|-------|---------|
| 1 | Este ADR | Decisión aceptada |
| 2 | EN1 | Flag + contrato eventos de custodia (delta) |
| 3 | EP1 | UI pendientes + confirmación bilateral + esperado = solo confirmado **si** modo B |
| 4 | Ambos | E2E: Ana cobra → María confirma → Z de María cuadra; pendiente Ana no ensucia el cajón |

**Prohibido (hasta paso 2):** reinterpretar Cash Shift HTTP o Order Domain payloads para simular custodia.

---

## 19. Consecuencias

### Positivas

- Comercios simples siguen rápidos.  
- Comercios con piso tienen trazabilidad real de efectivo.  
- Cierres de caja dejan de cargar faltantes “fantasma”.

### Negativas / costo

- Más estados y UI en modo B.  
- Requiere trabajo EN1 (config + sync de eventos) antes del GO EP1 modo B.

### Neutrales

- Turno de caja y Order Domain se mantienen; la custodia es capa adyacente.

---

## 20. Decisión final

**Aceptado.**

EPosOne adopta `SIMPLE` | `CHAIN_OF_CUSTODY` como capacidad configurable.  
Implementación EP1 del modo B **espera** handoff EN1 (flag + contrato de eventos). Hasta entonces, EP1 permanece en comportamiento `SIMPLE` (flujo actual).
