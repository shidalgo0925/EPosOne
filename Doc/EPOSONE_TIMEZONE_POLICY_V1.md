# EPosOne — Política oficial de Zona Horaria V1 (Fase 1)

**Fecha:** 16 jul 2026  
**Estado:** Implementada en cliente (Fase 1)  
**Fuente de zona:** `config.timezone` de provisioning EN1-02 (ej. `America/Panama`)  
**Contratos HTTP:** sin cambios inventados — ver delta request a P1

---

## Principio

1. El POS **no** es la fuente oficial de la hora.
2. **UTC** para almacenamiento y sync.
3. Zona IANA de **EN1** solo para **presentar** al cajero.
4. Un único servicio: `En1DateTimeService` (`lib/src/core/time/`).

---

## Fase 1 (este APK)

| Requisito | Implementación |
|-----------|----------------|
| Recibir timezone EN1 | `ProvisioningConfig.timezone` + bootstrap `organization.timezone` / `config.timezone` |
| Persistencia UTC | `nowUtc()` en Order / Sale / Cash create |
| Presentación local negocio | `formatLocal()` en recibos, historial, caja, chip sync |
| Drift > 2 min | Header HTTP `Date` (HEAD a base URL) · aviso no bloqueante tras PIN |
| Cambio zona SO | Detecta offset device ≠ EN1 · log + aviso |
| Auditoría | Prefs ring + UI en Este dispositivo |
| Sync timestamps | ISO con `Z` vía `toUtcIso` cuando se envíe |

**No implementado (Fase 2 — requiere contrato EN1):**

- Campos extra en `POST /devices/register` (`device_time`, `utc_offset`, …)
- `server_time` en heartbeat
- Documentar formalmente `organization.timezone` en bootstrap

---

## Servicio

```dart
En1DateTimeService.nowUtc();
En1DateTimeService.formatLocal(dt);
En1DateTimeService.toUtcIso(dt);
En1ClockGuard.checkAndWarn(context);
```

Fallback zona si aún no hay EN1: `America/Panama`.

---

## Criterios de aceptación Fase 1

- [x] Zona EN1 almacenada y usada solo para mostrar
- [x] Ventas/pedidos/caja nuevos en UTC
- [x] Pantallas/recibos en hora de zona EN1
- [x] Drift > 2 min advierte sin bloquear
- [x] Cambio de zona SO detectado y registrado
- [x] Conversiones centralizadas
- [x] Handoff delta listo para P1

---

*EasyTech · EPosOne Timezone Policy V1 Fase 1*
