# Gate 2 — LOCAL Asistente APK (arranque)

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **Estado** | **Implementado (MVP)** · tag contrato `eposone-onboarding-p0-v1.4` |
| **Freeze** | [`GATE1_HTTP_FROZEN_FOR_LOCAL.md`](GATE1_HTTP_FROZEN_FOR_LOCAL.md) |
| **Remoto** | `en1-codito` → Easy-NodeOne |

## Entregado

| Item | Estado |
|------|--------|
| Pack `Doc/EN1_ONBOARDING_P0/` importado | ✅ |
| Welcome 4 caminos (sin Modo Local) | ✅ |
| Cliente Login / Session / Issue-code (User Bearer) | ✅ |
| Selección org + caja → Register existente | ✅ |
| Camino C: código + pegar + QR → Register | ✅ |
| Restore = Login + select (composición sin `/restore`) | ✅ |
| Crear negocio → abre https://eposone.easytech.services/start | ✅ |
| Convergencia Register → Bootstrap → PIN | ✅ |
| Register / Bootstrap / Sync / Licencias / Cashiers intactos | ✅ (solo consumidores) |

## Tokens

- User Bearer: `OnboardingUserSessionStore` · solo `/api/v1/onboarding/*`
- Device Bearer: `ProvisioningStore` · operación POS (sin cambio)

## Rutas nuevas

- `/platform/onboarding/login`
- `/platform/onboarding/select`
- Welcome / Connect actualizados

## Próximo

- Validar contra appdev (login real + issue-code + register)
- APK release para CODITO Gate 2 sign-off
