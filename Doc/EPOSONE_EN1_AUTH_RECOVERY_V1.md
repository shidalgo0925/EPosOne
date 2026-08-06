# EPosOne — Auth recovery EN1 (401 / revocación → Connect)

| Campo | Valor |
|-------|--------|
| **Fecha** | 5 ago 2026 |
| **Estado** | Implementado |
| **Track** | B |

## Comportamiento

| Señal | Acción APK |
|-------|------------|
| HTTP 401/403 / `DEVICE_UNAUTHORIZED` en bootstrap o refresh config | Limpia token · conserva URL · cierra sesión · `/platform/connect?reprovision=1` |
| `device.status` revoked/disabled/inactive | Igual al evaluar lifecycle |
| Licencia bloquea operar | Bootstrap UI: Ver licencia + Reaprovisionar |

Código: `en1_device_auth_recovery.dart` · `StartupRoute.connect`
