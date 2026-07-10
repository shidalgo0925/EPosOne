# EPosOne ↔ EN1 — Contrato Provisioning v0.1 (Hito 1)

> ⚠️ **SUPERSEDED** por [`EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md`](EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md) (10 jul 2026).  
> Conservado solo como histórico del delta. El cliente Flutter consume **EN1-02**.

**Fecha:** Julio 2026  
**Consumidor:** EPosOne APK (`features/platform/`)  
**Productor:** EN1 API (CODITO)  
**Estado:** Obsoleto — no usar para integración

> **Fuera de este contrato (aún):** renovación de token / refresh. EN1 debe definir duración, refresh vs reauth y políticas de expiración antes de implementarlo en Flutter.

---

## Base URL

Configurada en el dispositivo (Wizard / prefs). **No** hardcodeada en el APK.

Ejemplo: `https://en1.ejemplo.com`

Rutas relativas fijas del contrato:

| Método | Ruta |
|--------|------|
| `POST` | `/api/v1/devices/register` |
| `GET` | `/api/v1/devices/config` |

---

## 1. Registrar dispositivo

### Request

`POST {baseUrl}/api/v1/devices/register`  
Headers: `Content-Type: application/json`, `Accept: application/json`

```json
{
  "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "model": "SM-T870",
  "os": "Android 14",
  "app_version": "1.0.0+1",
  "activation_code": "ACT-9F3K-2M7P"
}
```

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `uuid` | string | sí | UUID estable del dispositivo (generado en APK) |
| `model` | string | sí | Modelo / host |
| `os` | string | sí | Sistema operativo |
| `app_version` | string | sí | Versión APK |
| `activation_code` | string | sí | Código emitido en BackOffice EN1 |

### Response 200 OK

Cuerpo plano **o** envelope `{ "data": { ... } }`.

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "device_id": "dev_01HX...",
  "empresa_id": "emp_01HX...",
  "sucursal_id": "suc_01HX...",
  "pos_id": "pos_01HX...",
  "caja_id": "caja_01HX...",
  "empresa_name": "Istmo Demo",
  "sucursal_name": "Sucursal Centro",
  "pos_name": "POS Terraza",
  "caja_name": "Caja 1"
}
```

**Aliases aceptados por el cliente EPosOne** (compatibilidad):

| Canónico | Alias |
|----------|-------|
| `access_token` | `token` |
| `device_id` | `dispositivo_id` |
| `empresa_id` | `company_id` |
| `sucursal_id` | `branch_id` |
| `pos_id` | `punto_venta_id` |
| `caja_id` | `cash_register_id` |
| `empresa_name` | `company_name` |
| `sucursal_name` | `branch_name` |
| `pos_name` | `punto_venta_name` |
| `caja_name` | `cash_register_name` |

Campos de nombre son opcionales; IDs y `access_token` son **obligatorios**.

### Ejemplo envelope

```json
{
  "data": {
    "access_token": "...",
    "device_id": "dev_01HX...",
    "empresa_id": "emp_01HX...",
    "sucursal_id": "suc_01HX...",
    "pos_id": "pos_01HX...",
    "caja_id": "caja_01HX..."
  }
}
```

---

## 2. Obtener configuración

`GET {baseUrl}/api/v1/devices/config`  
Headers: `Authorization: Bearer {access_token}`, `Accept: application/json`

Misma forma de response 200 que el registro (IDs + token + nombres opcionales).

---

## 3. Formato único de error

Todos los errores HTTP **no 2xx** deben devolver JSON con esta forma:

```json
{
  "error": {
    "code": "INVALID_ACTIVATION_CODE",
    "message": "El código de activación no es válido o ya fue usado.",
    "details": null
  }
}
```

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `error.code` | string | sí | Código máquina estable (UPPER_SNAKE) |
| `error.message` | string | sí | Mensaje legible (puede mostrarse o mapearse) |
| `error.details` | object\|null | no | Datos extra de depuración |

Envelope opcional: `{ "data": null, "error": { ... } }` — el cliente busca `error` en la raíz.

### Códigos de negocio sugeridos (`error.code`)

| `error.code` | Uso típico |
|--------------|------------|
| `INVALID_ACTIVATION_CODE` | Código inválido / expirado / usado |
| `DEVICE_UNAUTHORIZED` | Dispositivo no autorizado / desactivado |
| `DEVICE_ALREADY_REGISTERED` | Conflicto de registro |
| `NOT_FOUND` | Recurso inexistente |
| `VALIDATION_ERROR` | Payload inválido |
| `INTERNAL_ERROR` | Error interno EN1 |

---

## 4. Códigos HTTP esperados

| HTTP | Cuándo | `error.code` ejemplo | Mensaje UX EPosOne (referencia) |
|------|--------|----------------------|----------------------------------|
| **200** | Registro / config OK | — | Conectado |
| **400** | Request mal formado | `VALIDATION_ERROR` | Datos de registro inválidos. Verifica la URL y el código. |
| **401** | Token ausente/inválido (config) | `DEVICE_UNAUTHORIZED` | Dispositivo no autorizado. Solicita un nuevo código en EN1. |
| **403** | Sin permiso / desactivado | `DEVICE_UNAUTHORIZED` | Dispositivo no autorizado. Contacta al administrador EN1. |
| **404** | Ruta o recurso inexistente | `NOT_FOUND` | Servidor EN1 no disponible o URL incorrecta. |
| **409** | Conflicto (ya registrado) | `DEVICE_ALREADY_REGISTERED` | Este dispositivo ya está registrado. Revisa el BackOffice. |
| **422** | Código activación inválido | `INVALID_ACTIVATION_CODE` | Código de conexión inválido. |
| **500** | Error interno | `INTERNAL_ERROR` | Error interno del servidor EN1. Intenta más tarde. |

### Errores de transporte (sin HTTP)

| Situación | Mensaje UX EPosOne |
|-----------|-------------------|
| Sin red / DNS / socket | Sin conexión a Internet. Verifica la red e intenta de nuevo. |
| Timeout | Tiempo de espera agotado. El servidor EN1 no respondió a tiempo. |
| Host unreachable / connection refused | Servidor EN1 no disponible. Verifica la URL y que el servicio esté activo. |

El APK muestra el mensaje UX al usuario y registra el detalle técnico (status, body, excepción) en log de depuración.

---

## 5. Persistencia local (APK)

- SharedPreferences, fuera de Isar / POS Core  
- Clave versionada: `en1_provisioning_config_v1`  
- Campo interno `schemaVersion: 1` en el JSON  
- Preparado para migrar a `config_v2` sin perder datos (migración completa cuando cambie el modelo)

---

## 6. Fuera de alcance Hito 1

- Sync productos / clientes / ventas / inventario (Hito 2)  
- Renovación de token / refresh (pendiente definición EN1)  
- Cambios al POS Core  

---

## 7. Criterio de cierre integración

Tablet limpia → Wizard → Conectar EN1 → `POST /register` 200 → config local → onboarding cajero si hace falta → PIN.

**Lado EPosOne:** cliente + contrato congelados.  
**Integración ✅:** cuando EN1 publique estos endpoints y una tablet quede registrada automáticamente.
