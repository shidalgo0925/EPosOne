# LOCAL — Postura Standalone: correo + código de activación

| Campo | Valor |
|-------|--------|
| **Fecha** | 7 ago 2026 |
| **Estado** | **GO LOCAL aplicado** (ADR-035 v1.4 · EN1 PROD `075dec7`) |
| **Reporte** | `LOCAL_STANDALONE_ACTIVATION_V1_GO_REPORT.md` |

## Flujo definitivo (producto)

```text
QR comercial → /start → registro → verificar correo
  → EN1 emite código activación Standalone (6 dígitos)
  → descarga APK (+ correo con código)
  → abrir EP1 → Activar (correo + código) → redeem EN1
  → ADR-033 → READY_TO_SELL
```

El usuario Standalone **nunca** ve “código de aprovisionamiento”, Register ni Bootstrap.  
Eso queda solo en Connected.

## Contrato consumido por EP1

```http
POST /api/v1/activation/redeem
{ "email", "activation_code", "device_uuid", "product_code": "eposone" }
→ modality=standalone → ADR-033
```

## Reinstalación

Si EN1 reemite sobre la misma licencia, EP1 re-activa con email+código nuevo y reanuda ADR-033 según claims / draft local.
