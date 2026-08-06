# EPosOne — Reaprovisionamiento UX (Local)

| Campo | Valor |
|-------|--------|
| **Fecha** | 5 ago 2026 |
| **Estado** | Implementado |
| **Contrato** | EN1-02 `POST /api/v1/devices/register` (sin endpoints nuevos) |
| **ADR** | ADR-014 (bootstrap obligatorio tras register/reprovision) |

---

## Flujo

```text
Este dispositivo
  → Reaprovisionar (confirmación)
  → /platform/connect?reprovision=1
  → URL prellenada + código de Caja
  → POST register (mismo UUID · token nuevo)
  → InstallationLifecycle.onDeviceRegistered
  → /platform/bootstrap (obligatorio)
```

## Desconectar EN1

```text
Este dispositivo → Desconectar EN1
  → clear token/config/cajeros EN1
  → reset lifecycle + wizard
  → lock sesión → /platform/welcome
```

## Router

`/platform/connect` accesible con sesión activa (no redirige a `/pos`).
