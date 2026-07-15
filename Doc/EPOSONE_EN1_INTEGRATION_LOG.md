# Bitácora Integración EPosOne ↔ EN1

**Metodología:** hitos · ambos lados deben funcionar para cerrar.  
**Última actualización:** 15 jul 2026  
**Roadmap activo:** [`EPOSONE_EN1_ROADMAP_V5.md`](EPOSONE_EN1_ROADMAP_V5.md)  
**GO P2:** [`EPOSONE_EN1_HITO3B_ORDER_OPERATION_GO.md`](EPOSONE_EN1_HITO3B_ORDER_OPERATION_GO.md)  
**UX-01:** [`EPOSONE_EN1_HITO3B1_UX01_STATUS.md`](EPOSONE_EN1_HITO3B1_UX01_STATUS.md)

Leyenda: 🔴 No iniciado · 🟡 En curso · 🟢 GO / activo · ✅ Validado · ⏸ Pausado

| Hito | Nombre | EN1 | EPosOne | Integración | Notas |
|------|--------|-----|---------|-------------|-------|
| **1** | Provisioning EN1-02 | 🟢 | 🟢 | ✅ | 🔒 |
| **2** | Device Bootstrap | 🟢 | 🟢 | ✅ | 🔒 · páginas Comida/Bar |
| **3** | Order Domain EN1 | ✅ | — | ✅ contrato | tag `eposone-order-domain-v1.0` |
| **3B** | Operación Pedido APK | soporte | ✅ cliente | 🟡 E2E | HTTP contra contrato congelado |
| **UX-01 / 3B.1** | UX + sync operación | — | ✅ | 🟡 checklist | dirty, auto-sync, chip, cola |
| **3C** | Sync estable | soporte | 🟡 cliente listo | 🟡 pruebas tablet | Ver checklist roadmap |
| **3.5** | Validación operativa | ⏸ | ⏸ | ⏸ | Tras E2E 3C |
| **5** | Inventario operativo | ⏸ | ⏸ | ⏸ | Tras 3.5 |
| **6** | Caja y pagos | ⏸ | ⏸ | ⏸ | |
| **7** | Facturación | ⏸ | ⏸ | ⏸ | |

**Docs EN1 (canónicos en `Doc/`):** `EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md` · `EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md` · `EPOSONE_EN1_ROADMAP_V5.md`

---

## Hito 1 — ✅ CERRADO

Tag `provisioning-v1.0`

---

## Hito 2 — ✅ CERRADO

`GET /api/v1/devices/bootstrap` · 401 diagnosticado (ruta BO incorrecta en APK antigua). Congelado.  
15 jul: páginas POS Comida/Bar desde categorías EN1; `isActive` Activo/Inactivo ES/EN.

---

## Hito 3 — ✅ Order Domain EN1 (P1)

| Entrega | Ref |
|---------|-----|
| Spec funcional + A–E | Congelada |
| Order Domain Spec v1.0 | Congelada |
| Tablas + `/api/v1/orders*` | commit `36a0eb1` |
| Contrato HTTP | commit `987bba7` · tag **`eposone-order-domain-v1.0`** |

P1 ahora: **solo soporte** (bugs / validaciones / perf). Sin ampliar dominio.

---

## Hito 3B / UX-01 — ✅ cliente P2 (15 jul 2026)

Contrato recibido en `Doc/`. Cliente HTTP Order Domain operativo.

Entregado P2:
- Ciclo de vida pedido (guardar → sync; no solo cobro).
- `Order.dirty` + auto-sync 30s + sync inmediato en eventos.
- Chip EN1 + overlay progress + cola P/E/C/Error.
- Cobro POS → Order Domain; Sale legacy desactivado en cola.
- Handoff menú Istmo: `Doc/EN1_HANDOFF_ISTMO_MENU/`.

**Pendiente:** checklist E2E tablet + confirmación BO (cierre formal 3C).

Regla: [`EPOSONE_EN1_HANDOFF_RULE.md`](EPOSONE_EN1_HANDOFF_RULE.md)

---

## Después

**3C** pruebas estabilidad → **3.5** validación operativa → **Hito 5** Inventario.

---

## Congelados

Provisioning · Bootstrap · Catálogo contrato · Order Domain HTTP · ampliar dominio Orders · Inventario/FE/KDS en este sprint
