# EPOSOne P0 — Certificación funcional (orden LOCAL)

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **Foco** | Operación POS — no EasyAI |
| **Método** | [`ETS_PRODUCT_VALIDATION_METHOD_V1.md`](ETS_PRODUCT_VALIDATION_METHOD_V1.md) |
| **EasyAI** | En espera de paquete EIS en este repo (Gate 0 bloqueado) |

## Orden de certificación (un módulo a la vez)

| # | Módulo | Estado | Log / checklist |
|---|--------|--------|-----------------|
| 1 | **Caja** — apertura / cierre / arqueo | 🟡 Prep cerrada · funcional tablet pendiente | [`EPOSONE_P0_CAJA_PREP_CLOSE_2026-08-06.md`](EPOSONE_P0_CAJA_PREP_CLOSE_2026-08-06.md) · [`ETS_VALIDACION_CAJA_SPRINT_LOG.md`](ETS_VALIDACION_CAJA_SPRINT_LOG.md) · [`EPOSONE_P0_CAJA_CERT_CHECKLIST_V1.md`](EPOSONE_P0_CAJA_CERT_CHECKLIST_V1.md) |
| 2 | Pedidos + recibos | Pendiente | Reusar / cerrar ETS Pedido |
| 3 | Cancelación / Anulación / Devolución | Pendiente | — |
| 4 | Sync EP1 ↔ EN1 + Offline → Online | Pendiente | — |
| 5 | Licenciamiento | Pendiente | — |
| 6 | E2E Mexican Food | Pendiente | Cierra el P0 |

**P2 comercialización** (landing / video / APK / clientes) solo tras P0 certificado.

## Por qué caja primero

Sin turno abierto no hay jornada POS válida. El router ya exige `/cash/open`. Certificar arqueo/teórico evita falsos positivos en pedidos y sync.
