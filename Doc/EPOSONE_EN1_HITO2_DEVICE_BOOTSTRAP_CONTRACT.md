# EPosOne ↔ EN1 — Contrato Device Bootstrap (Hito 2) v0.1

**Fecha:** 13 de julio de 2026  
**Estado:** 🟡 **BORRADOR CONGELABLE** — EN1 confirma/ajusta; luego freeze  
**Consumidor:** EPosOne APK (`features/platform/` bootstrap)  
**Productor:** EN1 API Dev (`https://appdev.easynodeone.com`)  
**Prerequisito:** Hito 1 Provisioning EN1-02 cerrado (`provisioning-v1.0`)  
**Org demo:** Itsmo Brew = **org 5**

> **Objetivo:** tablet recién provisionada descarga catálogo + imágenes + saldos desde EN1 y deja de depender del catálogo local Istmo.  
> **No incluye:** ventas→stock, transferencias, compras, conteos, reservas operativas, FE, CRM, IA.

---

## 0. Principios

1. Auth del dispositivo: `Authorization: Bearer {access_token}` del Hito 1.  
2. La jerarquía (Empresa/Sucursal/POS/Caja) ya viene del provisioning; Bootstrap **no** pide refs en el wizard.  
3. Pull **solo lectura** hacia la APK.  
4. Istmo local permanece en APK hasta E2E Bootstrap ✅; luego se desactiva/retira.  
5. Un hito · un contrato · un cierre · un GO.

---

## 1. Endpoints (pull)

Base: `{apiBaseUrl}` del dispositivo (ej. `https://appdev.easynodeone.com`)

| # | Método | Ruta | Uso Hito 2 |
|---|--------|------|------------|
| A | `GET` | `/api/v1/devices/config` | Refrescar config (opcional si ya está en store) |
| B | `GET` | `/api/eposone/products` | Catálogo completo de la org del dispositivo |
| C | `GET` | `/api/eposone/stock-balances` | Saldos por producto (y bodega si aplica) |
| — | — | `/static/uploads/eposone/products/...` | Descarga HTTP de `image_url` |

**Fuera de v1 (no obligatorio para cerrar Hito 2):**  
`GET /api/eposone/stock-movements`, `POST /api/eposone/stock-adjust`, CRUD productos.

### Headers comunes

```http
Accept: application/json
Authorization: Bearer <access_token>
```

### Auth — decisión pendiente EN1

El token de dispositivo (Hito 1) **debe** autorizar B y C para la org de la Caja provisionada.  
Si EN1 usa otro esquema, documentarlo aquí antes del freeze (no improvisar en APK).

---

## 2. Flujo APK (Device Bootstrap)

```
Provisionado (Hito 1)
    ↓
GET /api/eposone/products
    ↓
Mapear → Isar (categorías + productos)
    ↓
Descargar image_url → archivos locales → imagePath
    ↓
GET /api/eposone/stock-balances → actualizar stock local
    ↓
Marcar bootstrap OK (prefs)
    ↓
Desactivar catálogo Istmo local (isActive=false) si había seed
    ↓
UI ventas muestra catálogo EN1
```

---

## 3. Producto — shape esperado (`GET /api/eposone/products`)

Lista JSON (array o envelope `{ "data": [ ... ] }` / `{ "products": [ ... ] }`).

Campos **obligatorios** para v1:

| Campo EN1 | Tipo | Mapeo APK (Isar `Product`) |
|-----------|------|----------------------------|
| `product_ref` | string | `sku` + `localId` = `en1_{ref}` · `serverId` = ref |
| `name` | string | `name` |
| `unit_price` | number | `price` |
| `status` | string | `isActive` = active/enabled/… |

Campos **recomendados**:

| Campo EN1 | Mapeo APK |
|-----------|-----------|
| `description` | `description` |
| `barcode` | `barcode` |
| `category` | crear/buscar `Category` por nombre → `categoryId` |
| `cost_price` | `cost` |
| `currency` | BusinessConfig / ignorar si USD |
| `image_url` | descargar → `imagePath` |
| `min_stock` | `minStockAlert` |
| `tracks_inventory` | meta plataforma (sin campo Isar aún) |
| `uom` | meta plataforma |
| `purchase_uom` | meta plataforma |
| `pack_factor` | meta plataforma |
| `max_stock` | meta plataforma |
| `product_type` | meta plataforma (good/service/kit) |

**Ejemplo ítem:**

```json
{
  "product_ref": "ib-agua",
  "name": "Agua",
  "description": "",
  "product_type": "good",
  "status": "active",
  "unit_price": 1.25,
  "currency": "USD",
  "cost_price": 0.80,
  "barcode": null,
  "category": "Bebidas",
  "image_url": "/static/uploads/eposone/products/o5_abc.jpg",
  "tracks_inventory": true,
  "min_stock": 6,
  "max_stock": 48,
  "uom": "und",
  "purchase_uom": "pack",
  "pack_factor": 12
}
```

### Imágenes

| Regla | Detalle |
|-------|---------|
| URL relativa | Prefijar `{apiBaseUrl}` |
| URL absoluta | Usar tal cual |
| Fallo descarga | Producto se guarda; `imagePath` null / placeholder |
| Path local | `Documents/en1_product_images/{product_ref}.ext` |

---

## 4. Stock — shape esperado (`GET /api/eposone/stock-balances`)

| Campo EN1 | Uso APK |
|-----------|---------|
| `product_ref` (o equivalente) | Match con producto |
| `on_hand` | referencia |
| `reserved` | referencia |
| `available` | → `Product.stock` (cantidad vendible) |
| `warehouse_ref` / bodega | Si hay varios, v1 usa el de la sucursal/POS o el primero |

**Solo lectura.** No `reserve`/`deduct` desde venta en este hito.

---

## 5. Config (opcional refresh)

`GET /api/v1/devices/config` — misma forma EN1-02 (`business_name`, `currency`, `timezone`, org/branch/pos/register).  
Actualiza `ProvisioningStore` / `BusinessConfig` sin tocar Core de ventas.

---

## 6. Errores

Alinear con EN1-02 cuando sea posible:

```json
{ "error": "unauthorized" }
```

| HTTP | UX APK |
|------|--------|
| 401/403 | Token inválido — reprovisionar |
| 404 | URL/recurso incorrecto |
| 5xx | Servidor no disponible |
| Red/timeout | Mensajes Hito 1 |

---

## 7. Criterio de cierre Hito 2

Tablet limpia (o datos limpios):

1. Provisionar (Hito 1)  
2. Ejecutar Device Bootstrap  
3. Catálogo EN1 visible en ventas (SKUs `ib-*` org 5)  
4. Imágenes EN1 donde existan (`ib-agua`, etc.)  
5. Stock `available` reflejado  
6. Istmo local ya no es la fuente activa  

**No** se requiere vender ni descontar stock para cerrar v1.

---

## 8. Checklist freeze EN1 (antes de código APK “live” final)

- [ ] Device token autoriza `GET /api/eposone/products`  
- [ ] Device token autoriza `GET /api/eposone/stock-balances`  
- [ ] Envelope JSON documentado (array vs `data`)  
- [ ] Ejemplo real curl org 5 con 1 producto + 1 imagen  
- [ ] Confirmar campo exacto de match stock↔producto  

Tras OK → marcar este doc **CONGELADO v0.1** y programar APK.

---

## 9. Fuera de alcance (explícito)

❌ Ventas → stock · transferencias · compras · conteos · reservas reales  
❌ Licencias · FE · CRM · IA  
❌ Borrar assets Istmo del APK en el primer commit (solo desactivar tras E2E)  
❌ Cambios al POS Core salvo bugs  

---

*EasyTech · Hito 2 Device Bootstrap contract draft · 13 jul 2026*
