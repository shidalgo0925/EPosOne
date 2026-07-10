# EPosOne ↔ EN1 — Contrato Provisioning v0.1 (Hito 1)

**Fecha:** Julio 2026  
**Consumidor:** EPosOne APK (`features/platform/`)  
**Productor:** EN1 API (CODITO)

## Endpoints

### 1. Registrar dispositivo

`POST {baseUrl}/api/v1/devices/register`

**Request JSON**

```json
{
  "uuid": "device-uuid-estable",
  "model": "Samsung SM-T...",
  "os": "Android ...",
  "app_version": "1.0.0+1",
  "activation_code": "CODIGO-EMITIDO-EN-BO"
}
```

**Response JSON** (plano o envelope `{ "data": { ... } }`)

```json
{
  "access_token": "...",
  "device_id": "...",
  "empresa_id": "...",
  "sucursal_id": "...",
  "pos_id": "...",
  "caja_id": "...",
  "empresa_name": "Opcional",
  "sucursal_name": "Opcional",
  "pos_name": "Opcional",
  "caja_name": "Opcional"
}
```

Aliases aceptados por el cliente: `token`, `dispositivo_id`, `company_id`, `branch_id`, `punto_venta_id`, `cash_register_id`.

### 2. Obtener configuración

`GET {baseUrl}/api/v1/devices/config`  
Header: `Authorization: Bearer {access_token}`

Misma forma de respuesta que el registro.

## Persistencia local (APK)

SharedPreferences — fuera de Isar / POS Core:

- Token
- IDs Empresa / Sucursal / POS / Caja / Dispositivo
- URL API
- Estado: No configurado | Registrando | Conectado | Error

## Fuera de alcance Hito 1

- Sync productos / clientes / ventas / inventario
- Cambios al POS Core

## Criterio de cierre

Tablet limpia → Wizard → Conectar EN1 → registro OK → config local → onboarding cajero si hace falta → PIN.
