# ADR-037 — Cierre operativo Las Terrazas (EP1 slice)

| Campo | Valor |
|-------|--------|
| **Estado** | **Aceptado parcialmente** · EP1 DEV implementó lo local · resto espera EN1 |
| **Fecha** | 16 de agosto de 2026 |
| **Origen** | Instalación Las Terrazas VIP 507 |
| **Relacionado** | [`ADR-036`](ADR-036-CASH-OPERATION-MODES-CHAIN-OF-CUSTODY.md) · Order Domain · Cash Shift HTTP v1 · Bootstrap Hito 2 |
| **PROD** | Fuera de alcance hasta GO explícito |

---

## 1. Qué es de EP1 vs qué no corresponde

| Decisión | Dueño | En este commit |
|----------|-------|----------------|
| D1 Pedidos: Mis / Todos + autoría local | **EP1** | Sí |
| D2–D4 Cadena de custodia + confirmar recepción + arqueo EN1 | **EN1** + delta contrato | **No me corresponde** hasta handoff |
| D5 Catálogo ACTIVE / INACTIVE | **EP1** respeta sync; EN1 es autoridad | Sí (dejar de reactivar INACTIVE) |
| D6–D7 TEST / Preparar operación real / purga | **EN1** autoriza; EP1 ejecuta con contrato | **No me corresponde** hasta contrato |
| Auditoría central `TEST_PERIOD_CLOSED` | **EN1** | **No me corresponde** |

ADR-036 sigue vigente: default `SIMPLE`. `CHAIN_OF_CUSTODY` **no** se implementa torciendo Order HTTP ni Cash Shift HTTP.

---

## 2. Hallazgo (instalación) → gap EP1 confirmado

1. Tickets abiertos = hopper de **todo el dispositivo**. Cualquier mesera veía pedidos ajenos sin etiqueta de autor. Default debe ser **Mis pedidos**.
2. Bootstrap EN1 **reactivaba** productos `isActive=false` al armar menú Comida/Bar → SKUs dados de baja seguían vendibles.
3. `Order.organizationId` / `posRef` / `registerRef` existían pero **no** se sellaban al crear desde POS. `Order.cashierId` se **sobrescribía** al re-guardar (perdía created_by).

---

## 3. Implementado en EP1 (DEV)

### D1 — Pedidos

- UI tickets: **Mis pedidos** / **Todos**. Default = Mis.
- Badge del icono = cantidad de **mis** tickets.
- En Todos (y tickets ajenos): línea **Por: {nombre}**.
- Tickets sin `cashierId` no entran en Mis (aparecen en Todos como “sin autor”).
- Al re-guardar un pedido abierto, **no se pisa** `Order.cashierId` (created_by congelado). Eventos de update siguen con el actor actual.
- Al crear Order desde POS se sella, si hay provisioning: `organizationId`, `posRef`, `registerRef`.

### D5 — Catálogo

- `_rebuildPosPagesForEn1` **ya no** fuerza `isActive: true`.
- Menú POS = productos EN1 **ACTIVE**.
- INACTIVE permanece en Isar: tickets/ventas históricas no se borran.
- Restaurar un ticket abierto **sí** permite líneas de un SKU ya INACTIVE (pedido existente, no venta nueva de grilla).

---

## 4. Bloqueado — no inventar HTTP

Hasta que EN1 congele delta:

- `cash_operation_mode` SIMPLE \| CHAIN_OF_CUSTODY  
- eventos `PENDING_HANDOFF` / `CONFIRMED_IN_CASH_REGISTER` / `REVERSED`  
- operación administrativa **Confirmar recepción de dinero**  
- lifecycle TEST / OPERATIONAL + `TEST_PERIOD_CLOSED` + protocolo de purga  
- `is_test` / `test_session_id` en sync

EP1 **no** suma cobro a “caja central” de forma distinta a SIMPLE hasta ese flag.

---

## 5. Criterios E2E que EP1 ya puede certificar en tablet

| Caso | EP1 ahora |
|------|-----------|
| 1 Mesera B no mezcla autoría en “Mis pedidos” | Sí |
| 4 Producto INACTIVE desaparece del menú; ticket/venta histórica intactos | Sí (tras sync bootstrap) |
| 2–3 Custodia / diferencia | No — EN1 |
| 5–7 TEST / Go-Live / protección OPERATIONAL | No — EN1 |

---

## 6. Entrega LOCAL

- Código POS + bootstrap + Order stamp  
- Test: `open_ticket_authorship_test.dart`  
- Este ADR  
- Pendiente: APK DEV + prueba en Las Terrazas
