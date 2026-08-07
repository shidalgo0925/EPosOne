# Gate 2 / Sprint LOCAL P0.19–P0.30 — estado

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **Pack Ana** | [`EPOSONE_P0_LOCAL_SPRINT_V1.md`](../EPOSONE_P0_LOCAL_SPRINT_V1.md) |
| **Freeze** | Gate1 + QR Contract (`eposone://provision?code=`) |

## Entregado en este sprint (código)

| ID | Item | Estado |
|----|------|--------|
| P0.20 | Deep link `app_links` + intent-filters | ✅ |
| P0.21 | Bootstrap checklist visible | ✅ |
| P0.22 | Reintentar + Cancelar (sin borrar token) | ✅ |
| P0.23 | No re-register tras fallo bootstrap | ✅ (ya existía) |
| P0.24 | Auto-reintento si offline | ✅ (timer 5s × 8) |
| P0.27 | Mensajes código expirado/usado/revocado | ✅ (heurística + codes) |
| P0.28 | `userFacingError` + sanitize connect/caja | ✅ parcial |
| P0.29 | “EPOSOne está listo” | ✅ |
| P0.30 | Checklist E2E doc | ✅ doc |
| P0.19 | Consumidor reaprovisionamiento completo | ⏳ EN1 P0.17 |
| P0.25–26 | PIN/caja + licencia | ✅ / soft |

## Gate 2 previo (intactos)

Welcome 4 caminos · Login/Session/Issue · Register · Bootstrap · defaults PRD.
