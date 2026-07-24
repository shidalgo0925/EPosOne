# EPosOne — License Engine V1.0 (infraestructura APK)

| Campo | Valor |
|-------|--------|
| Estado | **Implementado lado P2** — 24 jul 2026 |
| ADR | [`ADR-007-EPOSONE-COMMERCIAL-LICENSING.md`](ADR-007-EPOSONE-COMMERCIAL-LICENSING.md) |
| Dueño de licencia | **EN1** (Caja / register) |
| APK | Consume · almacena · valida · aplica features |

---

## Principios

1. **Una sola APK** — no hay builds por plan.
2. **EN1 crea** la licencia; la tablet **nunca** inventa Trial/comercial.
3. **Offline-first** — snapshot local + gracia.
4. Preguntar **`FeatureManager.isEnabled`**, nunca `if (plan == ANNUAL)`.
5. Sin portal / pago / renovación en V1.0 APK (solo infraestructura).

---

## Módulo

```
lib/src/features/licensing/
  domain/   LicenseSnapshot · enums · GraceManager · Validator · FeatureManager · LicenseService
  data/     LicenseRepository · LicenseMapper · LicenseAuditStore
  presentation/  LicenseStatusScreen · providers
```

Ruta UI: `/platform/license` (también desde Este dispositivo).

---

## Bootstrap (consumo tolerante)

Si `GET /api/v1/devices/bootstrap` incluye:

```json
{
  "license": {
    "type": "TRIAL",
    "status": "ACTIVE",
    "plan": "trial_45",
    "activation_method": "EN1",
    "issued_at": "...",
    "starts_at": "...",
    "expires_at": "...",
    "grace_until": "...",
    "features": ["sales", "payments"],
    "limits": { "maxRegisters": 1 },
    "signature": "..."
  }
}
```

→ `LicenseService.applyFromBootstrap`.

Si **no** viene `license`: no se crea Trial local; Standalone sigue operable con features core por defecto.

**Trial days:** lo define EN1 (ADR-007 = 45 días). La APK no hardcodea 15/30/45.

---

## Activation methods (modelo listo)

| Método | V1.0 cableado |
|--------|----------------|
| `EN1` (bootstrap/sync) | ✅ |
| `SIGNED_FILE` | Enum + campo; sin UI import |
| `ACTIVATION_CODE` | Enum; **no** happy path (ADR-007) |
| `FACTORY` | Enum |

---

## Grace (local)

| Tipo | Gracia default APK |
|------|---------------------|
| Trial | 0 días |
| Mensual / Anual | 30 días |
| Perpetua | Sin vencimiento comercial |
| Offline validation window | 30 días desde `lastValidation` (ADR-007) |

Estados efectivos: `ACTIVE` → `GRACE` → `EXPIRED` (+ `SUSPENDED` / `REVOKED` remotos).

---

## Pendiente P1

Contrato HTTP License congelado + tag (envelope bootstrap/sync oficial). Hasta entonces el parser es **tolerante** y no bloquea bootstrap sin bloque `license`.

---

## Fuera de V1.0 APK

- Compra / pasarela / portal cliente  
- Ingreso de códigos / archivo firmado (canales excepcionales futuros)  
- Bloqueo duro de ventas en cada ticket (política de escalones = spec conjunta)
