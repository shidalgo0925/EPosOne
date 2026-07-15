#!/usr/bin/env python3
"""Exporta catálogo seed Istmo → paquete handoff EN1 (CSV/JSON + imágenes)."""

from __future__ import annotations

import csv
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "eposone/lib/src/core/database/istmo_seed_data.dart"
IMG_MAP = ROOT / "eposone/lib/src/core/database/istmo_product_images.dart"
FILENAME_MAP = ROOT / "eposone/assets/catalog/istmo/filename_map.json"
ASSETS = ROOT / "eposone/assets/catalog/istmo"
ITSBREW = ROOT / "ItsBrew"
OUT = ROOT / "Doc/EN1_HANDOFF_ISTMO_MENU"
OUT_IMG = OUT / "images"

CAT_NAMES = {
    "istmo_cat_entradas": "Entradas",
    "istmo_cat_platos": "Platos Fuertes",
    "istmo_cat_pizzas": "Pizzas",
    "istmo_cat_acomp": "Acompañamientos",
    "istmo_cat_postres": "Postres",
    "istmo_cat_cerv_istmo": "Cervezas Istmo",
    "istmo_cat_cocteles": "Cócteles",
    "istmo_cat_vinos": "Vinos y Espumantes",
    "istmo_cat_licores": "Licores",
    "istmo_cat_cerv": "Cervezas",
    "istmo_cat_bebidas": "Bebidas",
}

CAT_ALIAS = {
    "cEnt": "istmo_cat_entradas",
    "cPlat": "istmo_cat_platos",
    "cPizza": "istmo_cat_pizzas",
    "cAcomp": "istmo_cat_acomp",
    "cPost": "istmo_cat_postres",
    "cCervI": "istmo_cat_cerv_istmo",
    "cCoct": "istmo_cat_cocteles",
    "cVino": "istmo_cat_vinos",
    "cLic": "istmo_cat_licores",
    "cCerv": "istmo_cat_cerv",
    "cBeb": "istmo_cat_bebidas",
}


def parse_dart_string_map(path: Path, const_name: str) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    m = re.search(rf"const Map<String, String> {const_name} = \{{(.*?)\n\}};", text, re.S)
    if not m:
        raise SystemExit(f"No encontré {const_name}")
    body = m.group(1)
    return dict(re.findall(r"'([^']+)':\s*'([^']+)'", body))


def resolve_image_file(
    product_key: str,
    product_images: dict[str, str],
    category_images: dict[str, str],
    filename_map: dict[str, str],
) -> tuple[str | None, str | None]:
    """Return (source_path_relative_hint, friendly_filename)."""
    mapped = product_images.get(product_key)
    if not mapped:
        return None, None
    hash_name = category_images[mapped] if mapped.startswith("cat_") else mapped
    short = filename_map.get(hash_name, hash_name)
    # Prefer short name in assets
    for candidate in (ASSETS / short, ASSETS / hash_name, ITSBREW / hash_name):
        if candidate.is_file():
            return str(candidate), f"{product_key}.jpg"
    return None, f"{product_key}.jpg"


def main() -> None:
    seed = SEED.read_text(encoding="utf-8")
    product_images = parse_dart_string_map(IMG_MAP, "istmoProductImages")
    category_images = parse_dart_string_map(IMG_MAP, "istmoCategoryImages")
    filename_map = json.loads(FILENAME_MAP.read_text(encoding="utf-8-sig"))

    # p('key', 'Name', 8.56, cEnt, description: '...')
    pat = re.compile(
        r"p\(\s*'([^']+)'\s*,\s*'((?:\\'|[^'])*)'\s*,\s*([0-9.]+)\s*,\s*(\w+)\s*"
        r"(?:,\s*description:\s*'((?:\\'|[^'])*)')?\s*\)",
        re.S,
    )

    products = []
    OUT.mkdir(parents=True, exist_ok=True)
    if OUT_IMG.exists():
        shutil.rmtree(OUT_IMG)
    OUT_IMG.mkdir(parents=True)

    missing_images = []
    for key, name, price, cat_alias, desc in pat.findall(seed):
        cat_id = CAT_ALIAS.get(cat_alias, cat_alias)
        cat_name = CAT_NAMES.get(cat_id, cat_id)
        src, friendly = resolve_image_file(key, product_images, category_images, filename_map)
        image_file = ""
        if src and friendly:
            dest = OUT_IMG / friendly
            shutil.copy2(src, dest)
            image_file = f"images/{friendly}"
        else:
            missing_images.append(key)

        products.append(
            {
                "product_ref": key,
                "sku": f"IST-{key}",
                "name": name.replace("\\'", "'"),
                "description": (desc or "").replace("\\'", "'"),
                "category": cat_name,
                "category_ref": cat_id.replace("istmo_cat_", ""),
                "unit_price": float(price),
                "currency": "USD",
                "tax_included": True,
                "organization_hint": "Itsmo Brew / org 5",
                "image_file": image_file,
                "tracks_inventory": False,
            }
        )

    categories = [
        {"category_ref": cid.replace("istmo_cat_", ""), "name": name, "sort_order": i + 1}
        for i, (cid, name) in enumerate(CAT_NAMES.items())
    ]

    # CSV products
    csv_path = OUT / "products.csv"
    with csv_path.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=[
                "product_ref",
                "sku",
                "name",
                "description",
                "category",
                "category_ref",
                "unit_price",
                "currency",
                "tax_included",
                "image_file",
                "tracks_inventory",
            ],
        )
        w.writeheader()
        for p in products:
            w.writerow({k: p[k] for k in w.fieldnames})

    (OUT / "products.json").write_text(
        json.dumps({"organization": "Itsmo Brew", "org_id_hint": 5, "products": products}, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    (OUT / "categories.csv").write_text(
        "category_ref,name,sort_order\n"
        + "\n".join(f"{c['category_ref']},{c['name']},{c['sort_order']}" for c in categories)
        + "\n",
        encoding="utf-8-sig",
    )

    readme = f"""# Handoff menú Istmo / Itsmo Brew → EN1

**Destino:** org demo **5** · `https://appdev.easynodeone.com`  
**Origen:** seed APK EPosOne (`istmo_seed_data.dart`) + imágenes `assets/catalog/istmo/`  
**NO es la DB del POS.** Solo lista + fotos para que **P1** cargue el catálogo en EN1.

## Contenido

| Archivo | Uso |
|---------|-----|
| `products.csv` | Importar / cargar productos (Excel / script P1) |
| `products.json` | Misma data en JSON |
| `categories.csv` | Categorías |
| `images/{{product_ref}}.jpg` | Foto por producto (cuando existe) |

**Productos:** {len(products)}  
**Imágenes copiadas:** {len(products) - len(missing_images)}  
**Sin imagen propia (faltantes):** {len(missing_images)}

## Flujo

1. **P1** crea categorías + productos en EN1 (org 5) usando `product_ref` del CSV.
2. Sube cada foto de `images/` al producto correspondiente.
3. **P2** en tablet: **Descargar catálogo EN1** (pedidos locales **no** se borran).
4. Vender solo productos EN1 (`product_ref` = columna del CSV).

## Reglas

- Precios con **ITBMS incluido** (`tax_included=true`).
- `product_ref` estable = clave Istmo (ej. `ceviche`, `istmo_burger`) — **no** cambiar al azar.
- No subir DB Isar ni PDF “automágico”.
"""
    if missing_images:
        readme += "\n## Sin imagen dedicada\n\n" + ", ".join(missing_images) + "\n"

    (OUT / "README.md").write_text(readme, encoding="utf-8")
    print(f"OK -> {OUT}")
    print(f"  products={len(products)} images={len(list(OUT_IMG.glob('*.jpg')))} missing={len(missing_images)}")


if __name__ == "__main__":
    main()
