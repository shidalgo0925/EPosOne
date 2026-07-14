# Handoff — Hito 1 Provisioning EN1-02 CERRADO

**Fecha cierre formal:** 13 de julio de 2026  
**Tag:** `provisioning-v1.0`  
**Commit base código:** `0ceac11` — Adapt EPosOne provisioning client to official EN1-02 contract  
**Repo:** `EPosOne` · rama `master`

---

## Decisión de cierre

| Criterio E2E | Estado | Notas |
|--------------|--------|-------|
| URL + código de Caja | ✅ | `https://appdev.easynodeone.com` · Itsmo org 5 |
| Register HTTP 201 | ✅ | Reportado Ops |
| Token + config | ✅ | |
| Empresa → Sucursal → POS → Caja | ✅ | Pantalla “Este dispositivo” |
| UUID estable | ✅ | |
| **Reinicio → omitir wizard → PIN** | ⏳ Evidencia Ops | Criterio de cierre; adjuntar captura/notas si falta |
| **Reprovision mismo UUID** | ○ Opcional | **No bloquea** el cierre formal (decisión 13 jul) |

**Cliente Provisioning + POS Core:** 🔒 **congelados**.  
No modificar salvo bug bloqueante del reinicio documentado.

**Catálogo actual en APK:** Istmo **local** + imágenes embebidas.  
**No** descarga productos/imágenes desde EN1 (Hito 2).

---

## Qué entregó este hito

| Entrega | Ubicación |
|---------|-----------|
| Contrato oficial EN1-02 | [`EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md`](EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md) |
| Cliente Flutter | `eposone/lib/src/features/platform/` |
| Wizard | Solo URL + código de Caja |
| Register | Header `X-EN1-Provisioning-Code` · body sin refs de jerarquía |
| Response | HTTP 201 · `access_token` + `device` + `config` anidados |
| Persistencia | `schemaVersion: 2` |
| Errores | `{ "error": "string" }` + UX amigable |
| APK piloto E2E | `eposone/epos1.apk` (local, no en git) |

---

## Qué NO incluye (siguiente hito)

- Sync down / Device Bootstrap (catálogo EN1, imágenes, stock)  
- Ventas → stock, transferencias, FE, CRM, IA, licencias  
- APK para las otras 3 tablets (tras ✅ Bootstrap)

---

## Siguiente GO (chat / trabajo aparte)

**Hito 2 — Device Bootstrap (Sync Down) v1**

1. EN1 congela contrato Device Bootstrap (sin lógica APK hasta aprobar).  
2. EPosOne consume contrato.  
3. E2E: provisionar → descargar catálogo/imágenes EN1 → vender sin depender de Istmo local.

Referencia previa productos/inventario EN1:  
[`EN1_EPOSONE_HANDOFF_2026-07-13_PRODUCTS_INVENTORY.md`](EN1_EPOSONE_HANDOFF_2026-07-13_PRODUCTS_INVENTORY.md)

---

## Disciplina

Un hito · un contrato · un cierre · un GO.  
Abrir **nuevo chat** exclusivo para Hito 2. No mezclar fixes de provisioning con Bootstrap.

---

*EasyTech · Cierre Hito 1 Provisioning EN1-02 · 13 jul 2026*
