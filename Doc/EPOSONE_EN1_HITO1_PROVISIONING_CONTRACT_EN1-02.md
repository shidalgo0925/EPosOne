# EPosOne ↔ EN1 — Contrato Provisioning EN1-02 (oficial)

**Fecha:** 10 de julio de 2026  
**Consumidor:** EPosOne APK (`features/platform/`)  
**Productor:** EN1 API  
**Estado:** Oficial — cliente Flutter adaptado a EN1-02  
**Supersede:** contrato v0.1 (`EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT.md`)

> El código de provisioning está **asociado a una Caja** en EN1.  
> La tablet solo pide **URL + código**. No solicita Empresa / Sucursal / POS / Caja.

---

## Base URL

Configurada en el dispositivo (Wizard). Ejemplo DEV: `https://appdev.easynodeone.com`

| Método | Ruta |
|--------|------|
| `POST` | `/api/v1/devices/register` |
| `GET` | `/api/v1/devices/config` |

---

## 1. Registrar / reprovisionar dispositivo

### Request

```http
POST {baseUrl}/api/v1/devices/register
Content-Type: application/json
Accept: application/json
X-EN1-Provisioning-Code: <código de la caja>
```

```json
{
  "device_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "device_name": "EPosOne-550e8400",
  "platform": "android",
  "device_model": "Sunmi",
  "android_version": "13",
  "app_version": "1.0.0+1"
}
```

| Campo | Obligatorio | Notas |
|-------|-------------|-------|
| `device_uuid` | sí | UUID estable local |
| `device_name` | sí | Nombre amigable |
| `platform` | sí | p.ej. `android` |
| `app_version` | sí | |
| `device_model` | no | Si aplica |
| `android_version` | no | Si Android |

**No enviar:** `organization_id`, `branch_ref`, `pos_ref`, `register_ref`, `activation_code`, `provisioning_code` en body.

### Response éxito — HTTP **201**

```json
{
  "access_token": "<token>",
  "token_type": "Bearer",
  "device": {
    "uuid": "...",
    "name": "...",
    "status": "active",
    "organization_id": 1,
    "branch_ref": "...",
    "pos_ref": "...",
    "register_ref": "..."
  },
  "config": {
    "config_version": 1,
    "business_name": "...",
    "currency": "USD",
    "timezone": "America/Panama",
    "organization": { "id": 1, "name": "..." },
    "branch": { "ref": "...", "name": "..." },
    "pos": { "ref": "...", "name": "..." },
    "register": { "ref": "...", "name": "..." },
    "device": { "uuid": "...", "name": "...", "status": "active" }
  }
}
```

### Reprovisionamiento (mismo `device_uuid`)

- Reutiliza el mismo dispositivo (no duplica).
- Responde **201**.
- **Rota** `access_token` (el anterior deja de valer).
- Incrementa `config_version`.
- El APK **debe** guardar el nuevo token automáticamente.

---

## 2. Obtener configuración

```http
GET {baseUrl}/api/v1/devices/config
Authorization: Bearer <access_token>
Accept: application/json
```

Sin headers de auth adicionales.

---

## 3. Errores

Formato real EN1:

```json
{ "error": "device_uuid_required" }
```

`error` es un **string** (código). HTTP típicos: 400 / 401 / 403 / 404 / 5xx.

El APK muestra mensaje UX amigable y registra el código técnico en log.

---

## 4. Persistencia local (APK)

- SharedPreferences · `en1_provisioning_config_v1` · `schemaVersion: 2`
- Guarda: token, organization, branch, pos, register, device, `config_version`
- Schema v1 (contrato plano) se limpia → exige re-provision EN1-02

---

## 5. Fuera de alcance

- Sync catálogo / clientes / inventario / ventas (Hito 2)
- Cambios al POS Core
- Wizard con campos de jerarquía

---

## 6. Criterio E2E

Tablet limpia → URL + código → 201 + token + config → “Este dispositivo” → reinicio → omite wizard → PIN.

---

*EasyTech · Contrato EN1-02*
