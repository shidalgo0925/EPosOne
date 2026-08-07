# GO LOCAL — EP1 Standalone Activation v1 (email + código)

| Campo | Valor |
|-------|--------|
| Fecha | 2026-08-07 |
| EN1 PROD | `075dec7` · ADR-035 v1.4 |
| LOCAL commit | `ccba984` |
| Contrato | `POST /api/v1/activation/redeem` `{ email, activation_code, device_uuid, product_code }` |
| Alcance | Solo Standalone · Connected intacto (`/platform/connect`) |

## Objetivo cumplido

Cliente que se registró en `/start`, recibió código de 6 dígitos e instaló el APK puede:

1. Abrir EP1 → **Activar EPOSOne** (correo + código + Activar)
2. Redeem EN1 → `modality=standalone`
3. Persistencia local de claims + `PlatformMode.local`
4. Continuar a ADR-033 → negocio local (p. ej. Café Amor) → READY_TO_SELL

**EP1 no busca** Organización / Sucursal / POS / Caja en EN1 en este camino.  
**No ejecuta** Register / Bootstrap Connected.

## Cambios

| Área | Cambio |
|------|--------|
| `en1_activation_api.dart` | `redeemWithEmailCode` — body canónico v1.4; errores tipados (`activation_code_*`, `email_mismatch`, …) |
| `activation_claims_store.dart` | Pending email+código para reanudación de formulario; claims post-redeem |
| `standalone_activation_screen.dart` | UX principal: Correo + 6 dígitos + Activar (sin QR/token-first) |
| `standalone_assistant_screen.dart` | Si ya READY_TO_SELL → `/pin` (no vuelve a pedir código) |
| `app_startup.dart` | Ya reanudaba asistente / PIN según claims + draft (sin cambio de contrato) |
| Deep links `?token=` | Legado; pantalla canónica ignora token |
| Connected | Solo vía enlace «Instalación Connected» → `/platform/connect` |

## Legacy eliminado / aislado

| Antes | Ahora |
|-------|--------|
| Redeem `{ token }` como camino principal | Eliminado del cliente activo |
| Heurística por longitud de código | No existe en Standalone |
| Pantalla QR / “pegar enlace” / scan-first | Reemplazada por formulario email+código |
| App Link `activate?token=` | Transporte legado; no UX PROD Standalone |
| `/platform/connect`, Register, Bootstrap | Fuera del camino Standalone |

## Persistencia / reanudación

| Estado | Al reabrir |
|--------|------------|
| Claims Standalone válidos + no READY | → `/platform/standalone/assistant` (step del draft) |
| READY_TO_SELL | → `/pin` (no pide código) |
| Formulario a medias (antes de redeem OK) | Prefill email + código pending |
| Sin claims | → `/platform/activate` |

## E2E obligatorio (PROD) — checklist manual

1. `/start` → registro → verificar correo  
2. Email con código 6 dígitos  
3. Instalar **APK de validación** (este GO)  
4. Abrir EP1 → correo + código → Activar  
5. Redeem OK → ADR-033  
6. Crear negocio localmente (p. ej. Café Amor)  
7. READY_TO_SELL  

**No** publicar APK PROD definitivo hasta confirmar este E2E.

## APK de validación

| Campo | Valor |
|-------|--------|
| Path | `eposone/build/app/outputs/flutter-apk/app-release.apk` |
| Build | `flutter build apk --release` · ~93.1 MB |
| Uso | Solo validación E2E PROD — **no** promoción pública hasta E2E OK |

Tests: `flutter test test/features/platform/activation_token_extract_test.dart` — OK.
