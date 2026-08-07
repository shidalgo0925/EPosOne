# LOCAL — Informe cierre rediseño Standalone (fase UX)

| Campo | Valor |
|-------|--------|
| **Fecha** | 7 ago 2026 |
| **Objetivo** | Activación → ADR-033 → READY_TO_SELL sin “aprovisionar caja” |
| **APK PROD** | **NO** (solo validación cuando handoff CODITO cierre) |
| **ADR-034** | **NO** |

## Archivos tocados

| Área | Archivos |
|------|----------|
| Docs | `Doc/EN1_COMMERCIAL_IMPL/STANDALONE_ACTIVATION_UX_REDESIGN_V1.md` · este informe |
| Extracción token | `activation_claims_store.dart` — **sin** heurística `length >= 20` |
| API redeem | `en1_activation_api.dart` — mensajes usuario |
| UI activación | `standalone_activation_screen.dart` — ACTIVAR EPOSONE |
| Arranque | `app_startup.dart` · `splash_screen.dart` |
| Deep link | `en1_deep_link.dart` — solo `/activate?token=` o `eposone://activate` |
| Asistente | `standalone_assistant_screen.dart` (sin cambio de alcance) |
| Tests | `activation_token_extract_test.dart` |

## Rutas

| Ruta | Uso |
|------|-----|
| `/platform/activate` | Entrada principal Standalone (scan / pendiente / manual) |
| `/platform/standalone/assistant` | ADR-033 tras redeem Standalone |
| `/platform/connect` | **Solo** Connected (código de caja) — explícito, no mezclado |

## App Link / QR (contrato vigente ADR-035)

- `https://eposone.easytech.services/activate?token=<TOKEN>`
- `eposone://activate?token=<TOKEN>`

Pendiente: handoff CODITO si cambia formato (Android App Links firmados, etc.).

## Estado persistido

| Estado | Store |
|--------|--------|
| Activación pendiente (token pre-redeem) | `en1_activation_pending_token_v1` |
| Activación consumida (claims) | `en1_activation_claims_v1` |
| Wizard draft | `standalone_assistant_draft_v1` |
| READY_TO_SELL | `standalone_ready_to_sell_v1` |

## Heurística eliminada

`string.length >= 20 → activation token` — **eliminada**.

## Criterio aún abierto

Cierre E2E real requiere token emitido por EN1 en ambiente de validación.  
No declarar PROD hasta handoff CODITO + prueba física: App Link → ADR-033 → venta.
