# EPosOne — Discount Domain ↔ EN1 (pendiente contrato)

| Campo | Valor |
|-------|--------|
| **Estado** | Documentado — **sin HTTP** hasta handoff P1 congelado |
| **Fecha** | 5 ago 2026 |
| **ADR** | [`ADR-015`](ADR-015-EPOSONE-DISCOUNT-DOMAIN-V1.md) |

---

## Principios

- No inventar endpoints ni DTOs EN1.
- `source=EN1` → solo lectura en APK.
- `source=LOCAL` → CRUD Standalone.
- `source=SYSTEM` → seed legal; no eliminar.

## Interfaces locales (preparación)

- `DiscountProgramRepository` (list / get / upsert local / deactivate)
- `DiscountCatalogPort` (futuro pull EN1 → mismos modelos)
- Marcadores `source`, `version`, `effective_from` / `effective_to`

## Cuando exista contrato

Pull en bootstrap/sync: programas + estado + versiones.  
Conflictos: versión EN1 gana para `source=EN1`.  
Asignaciones cliente: Fase C.

## Mientras tanto

Fase A/B operan 100% offline/local con seed SYSTEM + programas LOCAL.
