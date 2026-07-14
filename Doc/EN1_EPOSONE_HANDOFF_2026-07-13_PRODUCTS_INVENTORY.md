# Handoff EN1 → EPosOne — Productos + Inventario (13 jul 2026)

**Silo:** Dev EN1 · `https://appdev.easynodeone.com`  
**Org de prueba de negocio:** Itsmo Brew = **org 5** (no confundir con org 1 “Easy NodeOne - Dev”)  
**Audiencia:** Programador APK (EPosOne)  
**Provisioning:** EN1-02 sigue **congelado** — Wizard solo URL + código de Caja

---

## Mensaje corto (APK)

EN1 Dev (appdev) — Itsmo org 5.

- Productos: además de SKU/precio/barcode/costo/categoría/imagen/min, ahora hay `uom`, `purchase_uom`, `pack_factor`, `max_stock`. Ver `GET /api/eposone/products`.
- Inventario: saldos con `on_hand`, `reserved`, `available`.
- Kardex: `GET /api/eposone/stock-movements`.
- Imágenes: URL relativa `/static/uploads/eposone/products/...`
- Provisioning sigue EN1-02: solo URL + código de caja.
- **Sync catálogo/ventas no está**; cuando lo hagamos será GO aparte.
- Probar Productos + Inventario logueado en Itsmo Brew en appdev.

---

## 1. Maestro de productos (alineado con ficha APK)

Campos en `core_product` / DTO / API EPosOne / BO:

| Campo | Notas |
|-------|-------|
| `product_ref` (SKU) | obligatorio |
| `name`, `description`, `product_type`, `status` | good / service / kit |
| `unit_price`, `currency`, `cost_price` | |
| `barcode`, `category`, `image_url` | |
| `tracks_inventory` | |
| `min_stock`, `max_stock` | alertas en inventario |
| `uom` | UOM venta (default `und`) |
| `purchase_uom` | UOM compra (ej. pack, caja) |
| `pack_factor` | und de venta por 1 UOM compra |

| Superficie | Ruta |
|------------|------|
| BO | `/admin/eposone/section/products` |
| API lista/alta | `GET/POST /api/eposone/products` |
| API ítem | `GET\|PATCH\|DELETE /api/eposone/products/<ref>` |
| API imagen | `POST /api/eposone/products/<ref>/image` (multipart `image_file`) |

**Ejemplo Itsmo `ib-agua`:** `uom=und`, `purchase_uom=pack`, `pack_factor=12`, min 6, max 48, imagen subida.

---

## 2. Imágenes

| Tema | Detalle |
|------|---------|
| Path público | `/static/uploads/eposone/products/o{org}_{hash}.ext` |
| Prioridad | archivo > URL > conservar / clear |
| Permisos escritura | usuario `nodeone` |

---

## 3. Inventario (BO + API)

Ya existía en Core: saldos `on_hand` / `reserved` / `available` y movimientos.  
Ahora visible/usable:

- Inventario BO: nombres producto/bodega, UOM, alerta bajo mín. / sobre máx.
- Kardex (lista movimientos)
- `GET /api/eposone/stock-balances`
- `GET /api/eposone/stock-movements` (**nuevo**)
- `POST /api/eposone/stock-adjust` (ajuste manual)

**Tipos de movimiento:** `adjust`, `reserve`, `release`, `deduct`, `return`.

---

## 4. Demo Itsmo (org 5) — útil para pruebas APK

| Pieza | Detalle |
|-------|---------|
| Jerarquía | centro → POS → `caja-01` + bodega |
| Productos | `ib-*` (café, agua, etc.) |
| Stock | seed en varios SKUs; `ib-agua` con foto + UOM/empaque |
| Provisioning | código por Caja (EN1-02) |

---

## 5. Qué NO tocar / no asumir

| Tema | Estado |
|------|--------|
| Sync fino catálogo o venta→stock APK↔EN1 | **Aún no** — roadmap después E2E APK; GO aparte |
| Transferencias, cupos | No cerrado |
| Relatic | Otro carril (certificados); no mezclar |
| Working tree Dev EN1 | Mucho EPosOne sin commit (productos + inventario + CRUDs previos) |
| Cliente provisioning APK / POS Core | 🔒 Congelados (`0ceac11`) |

---

## 6. Relación con Hitos EPosOne

| Hito | Impacto de este handoff |
|------|-------------------------|
| **1 Provisioning E2E** | Sin cambio — sigue URL + código Caja |
| **2 Sync down** | Cuando abra: mapear productos (`uom`/`pack_factor`/`max_stock`/imagen) + saldos |
| **3 Eventos up** | Venta → `deduct` / return; no implementar ahora |

---

*EasyTech · Handoff EN1 productos/inventario · 13 jul 2026*
