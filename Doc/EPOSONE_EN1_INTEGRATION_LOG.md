# Bitácora Integración EPosOne ↔ EN1

**Metodología:** hitos · ambos lados deben funcionar para cerrar.

Leyenda: 🔴 No iniciado · 🟡 En desarrollo · 🟢 Terminado · ✅ Validado  
Integración: 🔴 No probado · 🟡 Integrando · 🟢 Funciona · ✅ QA aprobado

| Hito | EN1 | EPosOne | Integración | Notas |
|------|-----|---------|-------------|-------|
| **1 Provisioning** | 🟢 EN1-02 | 🟢 **Congelado** `provisioning-v1.0` | ✅ **Cerrado** 13 jul | Handoff cierre; reinicio evidencia Ops |
| **2 Device Bootstrap** | 🟡 APIs productos/stock Dev | 🔴 stub | 🔴 | **Siguiente GO** — contrato primero |
| **3 Eventos up** | 🔴 | 🔴 stub | 🔴 | Ventas→stock etc. |
| **4 BackOffice ops** | 🟡 | N/A | 🔴 | |
| **5 QA 4 tablets** | 🔴 | 🔴 | 🔴 | Tras Bootstrap |

---

## Hito 1 — CERRADO / CONGELADO (13 jul 2026)

**Tag:** `provisioning-v1.0` · **Commit:** `0ceac11`  
**Handoff:** [`EPOSONE_HITO1_PROVISIONING_HANDOFF_CLOSED.md`](EPOSONE_HITO1_PROVISIONING_HANDOFF_CLOSED.md)  
**Contrato:** [`EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md`](EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md)

| Criterio | Estado |
|----------|--------|
| Register 201 + token + jerarquía + UUID | ✅ |
| Reinicio → PIN sin wizard | ⏳ Evidencia Ops (no reabrir código) |
| Reprovision | ○ Opcional — no bloquea cierre |
| Cliente + POS Core | 🔒 |

Catálogo en tablet = **Istmo local**. Sin pull EN1.

---

## Hito 2 — Device Bootstrap (próximo GO)

**Objetivo:** tablet provisionada deja de depender del catálogo Istmo local.

**v1 pull:** config · catálogo · precios · maestro inventario · `image_url` · saldos (`on_hand`/`reserved`/`available`).

**Fuera:** ventas→stock, transferencias, compras, FE, CRM, IA.

**Orden:** contrato EN1 congelado → consumo APK → E2E tablet nueva.

Handoff productos/inventario EN1 (referencia): [`EN1_EPOSONE_HANDOFF_2026-07-13_PRODUCTS_INVENTORY.md`](EN1_EPOSONE_HANDOFF_2026-07-13_PRODUCTS_INVENTORY.md)
