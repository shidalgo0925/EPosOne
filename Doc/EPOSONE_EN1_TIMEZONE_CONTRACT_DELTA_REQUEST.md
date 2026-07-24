# Solicitud de delta de contrato — Zona horaria (EPosOne → EN1)

**Fecha:** 16 jul 2026  
**De:** P2 (EPosOne)  
**Para:** P1 (EN1)  
**Motivo:** Completar política oficial de TZ; Fase 1 del POS ya opera con `config.timezone` existente y drift vía header `Date`.

> **No implementar en P2 hasta que este delta sea oficial y congelado.**

---

## 1. Provisioning — `POST /api/v1/devices/register` (campos opcionales)

Además del body EN1-02 actual, aceptar (opcionales, diagnóstico):

```json
{
  "device_uuid": "...",
  "device_name": "...",
  "platform": "android",
  "app_version": "...",
  "timezone": "America/Panama",
  "utc_offset": -300,
  "device_time": "2026-07-17T02:15:00Z",
  "auto_time_enabled": true,
  "auto_timezone_enabled": true
}
```

| Campo | Tipo | Notas |
|-------|------|-------|
| `timezone` | string IANA | Zona reportada por el device / preferencia local |
| `utc_offset` | int minutos | Offset del SO al registrar |
| `device_time` | ISO UTC | Reloj del device en el momento del register |
| `auto_time_enabled` | bool | Si el SO lo expone |
| `auto_timezone_enabled` | bool | Si el SO lo expone |

Response ya incluye `config.timezone` — **mantener**.

---

## 2. Bootstrap — `GET /api/v1/devices/bootstrap`

Documentar y garantizar:

```json
{
  "config": {
    "timezone": "America/Panama",
    "organization": {
      "id": 5,
      "name": "...",
      "timezone": "America/Panama"
    }
  }
}
```

Prioridad en cliente (ya preparada): `organization.timezone` → `config.timezone`.

---

## 3. Heartbeat / ping — `server_time`

En el response del heartbeat (o extensión del probe de sync), incluir:

```json
{
  "server_time": "2026-07-17T02:15:00.000Z"
}
```

El POS usará esto en lugar del header HTTP `Date` (más fiable que Cloudflare edge).

Umbral de aviso en POS: **2 minutos** de drift (no bloquea).

---

## 4. Criterio de cierre P1

1. Register acepta campos opcionales sin romper clientes viejos.
2. Bootstrap documenta `timezone` / `organization.timezone`.
3. Heartbeat (o endpoint acordado) devuelve `server_time` UTC.
4. Paquete handoff en `Doc/` + tag/commit de referencia.

Tras eso, P2 implementa **Fase 2** del cliente.

---

## Referencias

- Política cliente: `Doc/EPOSONE_TIMEZONE_POLICY_V1.md`
- Provisioning congelado: `Doc/EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md`
- Bootstrap congelado: `Doc/EPOSONE_EN1_HITO2_DEVICE_BOOTSTRAP_CONTRACT.md`

---

*EasyTech · Delta request timezone · 16 jul 2026*
