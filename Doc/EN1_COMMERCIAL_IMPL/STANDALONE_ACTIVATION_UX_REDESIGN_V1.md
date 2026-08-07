# EPOSOne Standalone — Rediseño instalación / activación (LOCAL)

| Campo | Valor |
|-------|--------|
| **Fecha** | 7 ago 2026 |
| **Objetivo** | Activación → ADR-033 → READY_TO_SELL sin intervención técnica |
| **ADR** | 033 ACCEPTED · 035 ACCEPTED (transporte sujeto a handoff CODITO) |
| **Fuera** | ADR-034 Connected · APK pública PROD |

## Experiencia

```text
QR comercial → /start → … → licencia Standalone → APK
  → ABRIR EPOSONE → activación (App Link / QR) → asistente → READY_TO_SELL
```

Usuario **instala y activa**. No “aprovisiona una caja”.

## Contrato (fuente de verdad)

Hasta handoff CODITO completo, LOCAL consume solo lo ya publicado en ADR-035 / EN1:

- Transporte: `https://eposone.easytech.services/activate?token=` · `eposone://activate?token=`
- Device: `POST /api/v1/activation/redeem`
- Claims: `modality`, `implementation_strategy`, `license_id`, …

**Prohibido:** clasificar por `length >= 20` · inventar formatos · mezclar código de caja Connected en este camino.

## Entradas EP1

| Entrada | Comportamiento |
|---------|----------------|
| App Link / deep link activación | redeem silencioso → Standalone → ADR-033 |
| Escanear QR activación | igual |
| Manual | Solo bajo “Problemas para activar” |
| Código de caja Connected | Ruta **explícita** distinta (`/platform/connect`) — no Standalone |

## Primera apertura sin activación

Pantalla **ACTIVAR EPOSONE**: escanear · continuar pendiente · ayuda/manual.  
Sin URL EN1, Register, Bootstrap ni “código de caja” en el camino principal.

## Criterio de cierre

No basta redeem OK o wizard abre. Cierre = **activación recibida → ADR-033 → READY_TO_SELL** sin soporte técnico.

APK: solo validación cuando handoff CODITO esté cerrado; **NO PROD**.
