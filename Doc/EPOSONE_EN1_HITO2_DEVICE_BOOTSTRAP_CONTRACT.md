# EPosOne ↔ EN1 — Contrato Device Bootstrap (Hito 2) v1.0

**Fecha:** 14 de julio de 2026  
**Estado:** ✅ **OFICIAL** — endpoint device bootstrap  
**Consumidor:** EPosOne APK (`features/platform/` bootstrap)  
**Productor:** EN1 API Dev (`https://appdev.easynodeone.com`)  
**Prerequisito:** Hito 1 Provisioning EN1-02 cerrado (`provisioning-v1.0`)  
**Org demo:** Itsmo Brew = **org 5**

> **Objetivo:** tablet provisionada descarga config + catálogo + stock + imágenes con **Device Token**.  
> **No incluye:** ventas→stock, transferencias, FE, CRM, IA.

---

## Endpoint oficial (único para Device Token)

```http
GET {apiBaseUrl}/api/v1/devices/bootstrap
Accept: application/json
Authorization: Bearer <DeviceToken>
```

- `DeviceToken` = `access_token` de `POST /api/v1/devices/register` (Hito 1).  
- **No** usar login BackOffice / sesión Flask.  
- **No** usar `GET /api/eposone/products` (eso es BO + `login_required` → 401 con Device Token).

### Base URL

La misma del provisioning (Wizard / EN1 Cloud). Ejemplo Dev:

`https://appdev.easynodeone.com`

---

## Flujo APK

```
Provisionado (Hito 1) · Device Token guardado
    ↓
Usuario: Descargar catálogo EN1
    ↓
GET /api/v1/devices/bootstrap
    ↓
Persistir config + productos + UOM/meta + stock + imágenes
    ↓
Desactivar catálogo local Istmo (isActive=false)
    ↓
POS vende con catálogo EN1 (offline-first)
```

---

## Shape de respuesta (flexible)

Envelope opcional: raíz o `{ "data": { ... } }`.

| Bloque | Claves aceptadas por el cliente |
|--------|----------------------------------|
| Config | `config`, `device_config` |
| Productos | `products`, `catalog.products`, `items` |
| Stock | `stock_balances`, `stock`, `balances`, `inventory.*` |

### Producto (campos)

| Campo | Uso APK |
|-------|---------|
| `product_ref` | SKU / `localId` = `en1_{ref}` |
| `name`, `description`, `status`, `product_type` | |
| `unit_price`, `cost_price`, `currency` | precio / costo |
| `barcode`, `category` | |
| `image_url` | descarga local |
| `tracks_inventory`, `min_stock`, `max_stock` | alerta + meta |
| `uom`, `purchase_uom`, `pack_factor` | meta plataforma |
| `available` / `on_hand` / `stock` | stock si viene en el ítem |

### Stock (lista aparte)

`product_ref` + `available` (o `on_hand`) → `Product.stock`.

### Imágenes

Relative → prefijar `{apiBaseUrl}`. Fallo → producto sin imagen.

---

## Errores

```json
{ "error": "unauthorized" }
```

| HTTP | UX |
|------|-----|
| 401/403 | Reprovisionar Device Token |
| 404 | URL / ruta incorrecta |
| 5xx | Reintentar |

---

## Criterio de cierre

1. APK provisionada · EN1 Conectado  
2. Descargar catálogo EN1 → `GET /api/v1/devices/bootstrap` OK  
3. Productos Itsmo Brew (org 5) en POS  
4. Ya no se usa Istmo local como fuente activa  
5. POS opera normal offline con catálogo descargado  

---

## Fuera de alcance

❌ `/api/eposone/products` · ventas→stock · transferencias · FE · CRM · IA · tocar Core / provisioning  

---

*EasyTech · Hito 2 Device Bootstrap contrato oficial v1.0 · 14 jul 2026*
