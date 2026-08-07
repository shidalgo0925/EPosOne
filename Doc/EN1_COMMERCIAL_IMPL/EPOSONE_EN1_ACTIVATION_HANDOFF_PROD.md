# EPOSOne — Handoff activación PROD (LOCAL)

| Campo | Valor |
|-------|--------|
| **Fuente** | CODITO handoff verificado · 7 ago 2026 |
| **EN1 commit** | `9c679c3` |
| **LOCAL base** | `9a84ba5` (+ redesign UX) |
| **Deploy extra** | No |

## Compatibilidad APK actual

| Forma | ¿OK con LOCAL? |
|-------|----------------|
| `https://eposone.easytech.services/activate?token=<manual_code>` | **Sí** |
| `eposone://activate?token=<manual_code>` + redeem `{token}` | **Sí** |
| `?token=<jti>` como body redeem | **No** → `activation_token_invalid` |
| Deep canónico `eposone://activate/<jti>` | Solo si LOCAL envía `activation_ref` (no en esta APK) |

**Para E2E sin cambiar EN1:** usar **manual_code** en `?token=`.

## Fixture prueba (no cliente)

| Campo | Valor |
|-------|--------|
| Org | 26 · E2E Standalone TEST `e93ca933` |
| Email | `e2e.standalone+e93ca933@easytech.services` |
| Password | `E2eStand408f539` (email verificado) |
| activation_ref (jti) | `43489a4599918446d37ad17b57f30856` |
| **manual_code** | `AD81-9E9F-6A15` |
| Legacy URL | `https://eposone.easytech.services/activate?token=AD81-9E9F-6A15` |
| Deep legacy | `eposone://activate?token=AD81-9E9F-6A15` |
| TTL | ~14d · single use · double redeem → 409 `activation_token_used` |

## Redeem

`POST /api/v1/activation/redeem` · Standalone OK · body `token` = **manual_code**.

## APK

Validación física PROD — **no** promover a canal público sin cierre E2E.
