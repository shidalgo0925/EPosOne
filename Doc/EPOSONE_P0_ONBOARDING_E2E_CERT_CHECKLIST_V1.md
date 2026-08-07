# EPOSOne P0 — Checklist certificación E2E onboarding (LOCAL)

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **ID** | P0.30 |
| **Ambiente** | PRD `eposone.easytech.services` |
| **APK** | Build LOCAL con defaults PRD |

Marcar solo con evidencia (fecha · device · resultado).

---

## Casos Ana

| # | Caso | Pasos | OK |
|---|------|-------|----|
| 1 | Nuevo negocio | Portal/start → Register → Bootstrap → PIN → Caja → Venta | ☐ |
| 2 | Código manual | Pegar provision code → Register → Bootstrap → PIN | ☐ |
| 3 | QR técnico | Escanear / deep link `eposone://provision?code=` → Register… | ☐ |
| 4 | Reaprovisionamiento | Login → org → device → nuevo code → Register → Bootstrap | ☐ |
| 5 | Reinstalación | Desinstalar APK → instalar → restore/reprovision → operar | ☐ |
| 6 | Cambio de tablet | Device B reemplaza A; A invalido; B opera | ☐ |
| 7 | Bootstrap interrumpido | Fallar mid-bootstrap → Reintentar (sin re-register) → listo | ☐ |
| 8 | Sin Internet en Bootstrap | Offline → mensaje claro → reintento auto/manual → OK | ☐ |

## Extras Gate 2

| # | Caso | OK |
|---|------|----|
| A | Camino Welcome “Crear negocio” abre `/start` | ☐ |
| B | Login onboarding → issue → register | ☐ |
| C | Código expirado / usado → mensaje amigable (no stack) | ☐ |
| D | Post-bootstrap “EPOSOne está listo” → PIN | ☐ |

## Criterio de cierre

Todos los casos 1–8 en PRD sin intervención técnica + P0.19 alineado al freeze EN1 P0.17.
