# Solicitud a EN1 — Validación de contrato Hito 1 (DEV)

**De:** Equipo EPosOne  
**Para:** Equipo EN1 (CODITO)  
**Fecha:** 10 de julio de 2026  
**Asunto:** Entregar especificación real del ambiente DEV antes de prueba E2E en tablet  
**Referencia contrato EPosOne:** [`EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT.md`](EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT.md) (v0.1)

---

## Por qué pedimos esto

El cliente Flutter de provisioning está **congelado**.  
Antes de conectar una tablet, necesitamos comparar **implementación real EN1 (DEV)** vs **contrato v0.1**.

Objetivo: documentar diferencias y decidir ownership (EN1 / EPosOne / contrato) **sin tocar código** hasta aprobar el delta.

---

## Información requerida del ambiente DEV

Por favor responder con datos **reales** (copiar/pegar de Postman, curl o logs), no resúmenes.

### 1. Ambiente

| Campo | Respuesta EN1 |
|-------|----------------|
| URL base (sin path de API) | _ej. `https://…`_ |
| Ambiente | DEV |
| ¿TLS / certificado especial? | |
| ¿VPN / IP allowlist? | |

### 2. `POST /api/v1/devices/register`

| Campo | Respuesta EN1 |
|-------|----------------|
| URL completa exacta | |
| Método | POST (confirmar) |
| Content-Type | |
| Headers **obligatorios** (lista completa) | |
| ¿Usa `X-EN1-Provisioning-Code`? | Sí / No — si Sí, ejemplo |
| ¿Usa `activation_code` en el JSON body? | Sí / No |
| Body JSON exacto (ejemplo real) | ver abajo |
| Response 200 exacto (ejemplo real, token puede redactarse parcialmente) | ver abajo |
| Códigos HTTP que el servidor **realmente** devuelve | lista |
| Ejemplo de error JSON real | ver abajo |

**Ejemplo request real (pegar completo):**

```http
POST …
Headers:
…

Body:
{
}
```

**Ejemplo response 200 real (pegar completo):**

```http
HTTP/1.1 200 …
…

{
}
```

### 3. `GET /api/v1/devices/config`

| Campo | Respuesta EN1 |
|-------|----------------|
| URL completa exacta | |
| Método | GET (confirmar) |
| Headers **obligatorios** | |
| ¿`Authorization: Bearer …`? | Sí / No — formato exacto |
| Response 200 exacto | pegar abajo |
| Códigos HTTP reales en error | lista |
| Ejemplo error JSON real | pegar abajo |

**Ejemplo request/response real (pegar completo).**

### 4. Código de provisioning (crítico)

Marcar **una** opción (o ambas si aplica):

- [ ] Código en body: campo `activation_code`
- [ ] Código en header: `X-EN1-Provisioning-Code`
- [ ] Otro (especificar nombre exacto): _______________

Si el nombre del campo/header **no** es uno de los anteriores, indicar el nombre canónico EN1.

### 5. Nombres de campos en response 200

Indicar el nombre **exacto** que devuelve EN1 para cada concepto:

| Concepto | Nombre exacto en JSON EN1 |
|----------|---------------------------|
| Token de acceso | |
| ID dispositivo | |
| ID empresa | |
| ID sucursal | |
| ID POS | |
| ID caja | |
| Nombre empresa (si existe) | |
| Nombre sucursal (si existe) | |
| Nombre POS (si existe) | |
| Nombre caja (si existe) | |
| ¿Envelope `{ "data": { … } }`? | Sí / No |

### 6. Reprovisioning (decisión de arquitectura — obligatorio)

Cuando el **mismo `uuid`** vuelve a llamar `POST …/register` con un código válido:

| Pregunta | Respuesta EN1 |
|----------|----------------|
| ¿HTTP status esperado? | 200 / 409 / otro: ___ |
| ¿Reutiliza el mismo `device_id`? | Sí / No |
| ¿Emite nuevo `access_token`? | Sí / No / igual |
| ¿Crea un dispositivo nuevo? | Sí / No |
| Ejemplo response real del 2º register | pegar |

> EPosOne espera poder **reutilizar** el mismo dispositivo (no duplicar).  
> Si EN1 responde 409, hay que unificar la regla de arquitectura **antes** de la tablet.

### 7. Datos de prueba para E2E (después del delta)

| Campo | Valor DEV |
|-------|-----------|
| Código de provisioning válido | |
| Código inválido de prueba | |
| Empresa (id + nombre) | |
| Sucursal (id + nombre) | |
| POS (id + nombre) | |
| Caja (id + nombre) | |

---

## Qué haremos con su respuesta

1. Completar [`EPOSONE_EN1_HITO1_CONTRACT_DELTA.md`](EPOSONE_EN1_HITO1_CONTRACT_DELTA.md).  
2. Clasificar cada diferencia: **Compatible** / **Alias soportado** / **Incompatible**.  
3. Aprobar ownership del ajuste (EN1 / EPosOne / contrato).  
4. **Solo entonces** prueba E2E en una tablet limpia.

**No** iniciaremos sync, licencias, FE ni cambios al POS Core en esta fase.

---

## Referencia rápida — lo que el cliente Flutter envía hoy (contrato v0.1)

```http
POST {baseUrl}/api/v1/devices/register
Content-Type: application/json
Accept: application/json

{
  "uuid": "<uuid-dispositivo>",
  "model": "<modelo>",
  "os": "<os>",
  "app_version": "<version>",
  "activation_code": "<codigo>"
}
```

```http
GET {baseUrl}/api/v1/devices/config
Authorization: Bearer <access_token>
Accept: application/json
```

**No** envía hoy el header `X-EN1-Provisioning-Code`.

---

*EasyTech · EPosOne · Validación de contrato previa a E2E*
