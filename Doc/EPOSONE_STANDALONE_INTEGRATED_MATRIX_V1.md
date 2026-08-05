# EPosOne — Matriz Standalone / Integrado (Dual Mode V1)

| Campo | Valor |
|-------|--------|
| **Fecha** | 5 ago 2026 |
| **Estado** | Borrador operativo post–Discount Domain / Hito 2.6 |
| **SoT arquitectura** | [`ADR-008`](ADR-008-EPOSONE-COMMERCIAL-ENGINE.md) · Ownership [`EPOSONE_OWNERSHIP_MATRIX_V1.md`](EPOSONE_OWNERSHIP_MATRIX_V1.md) |

---

## Una APK · dos orígenes

| Dimensión | Standalone | Integrado (EN1) |
|-----------|------------|-----------------|
| Arranque | Wizard negocio local | Provisioning EN1-02 + Bootstrap Hito 2 |
| Catálogo | Local / seed demo | Pull EN1 (productos, precios, imágenes, stock snapshot) |
| Cajeros | CRUD local + PIN local | Catálogo EN1 + PIN verifiers; APK no edita maestro |
| Turno / caja | Local | Local + push Cash Shift |
| Pedido / cobro | Local (Sale ledger) | Order Domain + eventos + sync cola |
| Offline | Completo | Completo; cola + idempotencia al reconectar |
| Impuestos / tip / totales | Mismo Commercial Engine | Mismo engine; políticas futuras vía sync |
| Descuentos | Discount Domain local (SYSTEM/LOCAL) | Mismo; EN1 solo lectura cuando exista contrato |
| Licencia | Sin snapshot / defaults | Snapshot EN1 en bootstrap |
| Diagnóstico | Este dispositivo (2.6) | Idem + conectividad / cola / errores EN1 |
| Admin políticas comerciales V6 | Local (cuando freeze) | EN1; APK no edita maestro |

---

## Lo que **no** cambia entre modos

- UX del cajero (PIN → turno → POS → cobro → recibo).  
- Cálculo Totals / Pricing / DiscountResolver.  
- Regla: UI no inventa % libres (Discount Domain).  
- Order lifecycle: cancel / void / refund por eventos (sin DELETE físico de pedido confirmado).

---

## Cutover Standalone → Integrado

Asistente de vinculación **sin reinstalar** (principio ADR-008).  
Detalle de migración de datos = proyecto explícito post-freeze V6; no inventar aquí.

---

## Criterio de cierre documental

- [ ] Ownership Matrix firmada con evidencia E2E  
- [ ] Esta matriz revisada Analista / P1 / P2  
- [ ] Gaps de sync (Sale/Customer/CashMovement push) explícitos o cerrados en roadmap
