# EPosOne — Ownership Matrix de entidades locales (V1)

| Campo | Valor |
|-------|--------|
| **Fecha** | 5 ago 2026 |
| **Estado** | Borrador operativo — alinea código actual; se firma al cerrar E2E Hito 2.5 |
| **Origen** | [`EPOSONE_V6_PROG2_OFFICIAL_INSTRUCTION.md`](EPOSONE_V6_PROG2_OFFICIAL_INSTRUCTION.md) §4 |
| **Principio** | Una sola lógica de negocio. Standalone vs Integrado cambia **origen/owner**, no el motor. |

---

## Matriz

| Entidad | Standalone (quién escribe) | Integrado (quién escribe) | Sync |
|---------|----------------------------|---------------------------|------|
| Product | EPosOne CRUD local | EN1 maestro vía bootstrap (`en1_*`); APK no debe editar maestro EN1 | Pull (bootstrap / `catalogPull`) |
| Category | EPosOne | Derivada de catálogo EN1 en bootstrap | Pull (bootstrap) |
| Customer | EPosOne | EPosOne local (sin push EN1 live hoy) | Ninguno |
| Sale / SaleItem | EPosOne (ledger cobro) | EPosOne local; camino EN1 = Order Domain | Sale push no soportado |
| OpenTicket | EPosOne | EPosOne; se cierra al reconciliar Order paid/closed | Indirecto vía Order |
| Order / Item / Payment / Event | Local (poco uso) | EPosOne escribe + ownership dispositivo; EN1 acepta push / eventos admin | Push Order · pull/reconcile |
| Cashier | EPosOne CRUD | EN1 (bootstrap); UI APK lectura cuando hay catálogo EN1 | Pull cashiers |
| CashRegister (turno) | EPosOne | EPosOne + Cash Shift HTTP EN1 | Push `cashRegister` |
| CashMovement | EPosOne | EPosOne | Push no soportado |
| BusinessConfig | EPosOne onboarding/settings | EPosOne + merge provisioning/bootstrap (URL, jerarquía, TZ…) | Parcial |
| Coupon | EPosOne | EPosOne | Ninguno |
| DiscountProgramRecord | SYSTEM seed + LOCAL | Igual; `source=en1` solo lectura si llega | Pendiente contrato (Fase C) |
| SyncOperation | EPosOne (outbox) | EPosOne | Meta local |
| FiscalDocument | EPosOne (PAC local) | EPosOne | Ninguno |
| License snapshot | Defaults locales / ausente | EN1 en bootstrap | Pull |
| ProvisioningConfig | N/A | EN1 register + bootstrap | Pull EN1-02 |
| Modifier | EPosOne | EPosOne (no en bootstrap) | Ninguno |
| PosPage | EPosOne | Reconstruidas localmente desde categorías EN1 | Derivado post-pull |

---

## Reglas cortas

1. **EN1 administra maestros** (productos, cajeros, licencia) en Integrado.  
2. **EPosOne opera** (pedido, cobro, turno, impresión, offline, tickets).  
3. **Discount Domain** es SoT local hasta contrato HTTP congelado.  
4. No inventar endpoints: sync solo contra contratos en `Doc/`.

## Relacionado

- Dual Mode: [`EPOSONE_STANDALONE_INTEGRATED_MATRIX_V1.md`](EPOSONE_STANDALONE_INTEGRATED_MATRIX_V1.md)  
- Discount: [`ADR-015-EPOSONE-DISCOUNT-DOMAIN-V1.md`](ADR-015-EPOSONE-DISCOUNT-DOMAIN-V1.md)  
- Cajeros: [`EN1_EPOSONE_HITO25_CASHIER_CONTRACT.md`](EN1_EPOSONE_HITO25_CASHIER_CONTRACT.md)
