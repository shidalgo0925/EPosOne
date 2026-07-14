# Bitácora Integración EPosOne ↔ EN1

**Metodología:** hitos · ambos lados deben funcionar para cerrar.  
**Última actualización:** 13 jul 2026

Leyenda: 🔴 No iniciado · 🟡 En desarrollo · 🟢 Terminado · ✅ Validado

| Hito | EN1 | EPosOne | Integración | Notas |
|------|-----|---------|-------------|-------|
| **1 Provisioning** | 🟢 EN1-02 | 🟢 `provisioning-v1.0` | ✅ Cerrado | 🔒 no reabrir |
| **2 Device Bootstrap** | 🟡 APIs productos/stock | 🟡 Cliente pull + UI | 🟡 GO abierto | Contrato draft |
| **3 Eventos up** | 🔴 | 🔴 | 🔴 | Después Bootstrap |
| **4 BackOffice** | 🟡 | N/A | 🔴 | |
| **5 QA 4 tablets** | 🔴 | 🔴 | 🔴 | Tras Bootstrap |

---

## Hito 1 — CERRADO

Tag `provisioning-v1.0` · [`EPOSONE_HITO1_PROVISIONING_HANDOFF_CLOSED.md`](EPOSONE_HITO1_PROVISIONING_HANDOFF_CLOSED.md)

---

## Hito 2 — Device Bootstrap — GO ABIERTO (13 jul 2026)

**Contrato:** [`EPOSONE_EN1_HITO2_DEVICE_BOOTSTRAP_CONTRACT.md`](EPOSONE_EN1_HITO2_DEVICE_BOOTSTRAP_CONTRACT.md) (draft → freeze EN1)

**Objetivo:** provisionar → descargar catálogo/imágenes/saldos EN1 → vender sin Istmo activo.

### EPosOne (en curso)

| Entrega | Estado |
|---------|--------|
| Contrato draft en repo | 🟢 |
| `En1BootstrapApi` / `Repository` | 🟢 **`GET /api/v1/devices/bootstrap`** (no BO) |
| Botón “Descargar catálogo EN1” | 🟢 EN1 Cloud + Este dispositivo |
| Desactivar productos `istmo_*` tras bootstrap | 🟢 |
| Meta uom/pack/max en prefs | 🟢 |
| E2E tablet org 5 | ⏳ Probar tras fix endpoint |

**Importante:** `/api/eposone/products` = BackOffice → 401 con Device Token. Contrato oficial = `/api/v1/devices/bootstrap`.
