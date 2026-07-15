# Handoff menú Istmo / Itsmo Brew → EN1

**Destino:** org demo **5** · `https://appdev.easynodeone.com`  
**Origen:** seed APK EPosOne (`istmo_seed_data.dart`) + imágenes `assets/catalog/istmo/`  
**NO es la DB del POS.** Solo lista + fotos para que **P1** cargue el catálogo en EN1.

## Contenido

| Archivo | Uso |
|---------|-----|
| `products.csv` | Importar / cargar productos (Excel / script P1) |
| `products.json` | Misma data en JSON |
| `categories.csv` | Categorías |
| `images/{product_ref}.jpg` | Foto por producto (cuando existe) |

**Productos:** 110  
**Imágenes copiadas:** 110  
**Sin imagen propia (faltantes):** 0

## Flujo

1. **P1** crea categorías + productos en EN1 (org 5) usando `product_ref` del CSV.
2. Sube cada foto de `images/` al producto correspondiente.
3. **P2** en tablet: **Descargar catálogo EN1** (pedidos locales **no** se borran).
4. Vender solo productos EN1 (`product_ref` = columna del CSV).

## Reglas

- Precios con **ITBMS incluido** (`tax_included=true`).
- `product_ref` estable = clave Istmo (ej. `ceviche`, `istmo_burger`) — **no** cambiar al azar.
- No subir DB Isar ni PDF “automágico”.
