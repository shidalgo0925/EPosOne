# Cuestionario enviado a EN1 (Prog1) — Validación previa E2E

**Estado:** 🟢 Respuesta recibida (10 jul 2026) · ver delta  
**Respuesta Prog1:** base `https://appdev.easynodeone.com` · commit `847a09f`  
**Informe:** [`EPOSONE_EN1_HITO1_CONTRACT_DELTA.md`](EPOSONE_EN1_HITO1_CONTRACT_DELTA.md) — **incompatibilidades bloqueantes**

## Checklist interno (respuesta Prog1)

| # | Pregunta | ¿Respuesta recibida? | ¿Compatible con contrato v0.1? |
|---|----------|----------------------|--------------------------------|
| 1 | Código: A / B / C / D | ✅ C) Ambos — header preferido; body `provisioning_code`; **no** `activation_code` | ❌ Incompatible |
| 2 | Request JSON | ✅ `device_uuid` + org + refs + … | ❌ Incompatible |
| 3 | Response 200 JSON | ✅ **201** anidado `device`+`config` | ❌ Incompatible |
| 4 | Auth config | ✅ Solo Bearer | ✅ Compatible |
| 5 | Reprovisioning | ✅ Reutiliza + rota token + **201** (no 200/409) | ❌ vs contrato escrito |
| 6 | Claves JSON | ✅ `access_token`, `organization`, `branch.ref`, … | ❌ vs planos Flutter |
| 7 | Forma de error | ✅ `{ "error": "code_string" }` | ❌ Incompatible |
| 8 | curl register + config | ✅ | Evidencia OK |

**Siguiente:** aprobar ownership (Opción 1/2/3 del delta) → **luego** código → **luego** tablet.

---

## Texto enviado (referencia)

Validación previa a la integración E2E

Antes de iniciar las pruebas con la tablet necesito confirmar algunos puntos del contrato implementado en EN1.

Por favor responde únicamente con el comportamiento real de la API en DEV.

### 1. Registro del dispositivo

En `POST /api/v1/devices/register`:

¿Cómo recibe EN1 el código de provisioning?

- A) En el body JSON (`activation_code`)
- B) En el header `X-EN1-Provisioning-Code`
- C) Ambos
- D) Otro (indicar cuál)

### 2. Ejemplo real del request

Indica el JSON exacto que espera EN1.

### 3. Ejemplo real del response

Indica el JSON exacto que devuelve EN1 cuando el registro es exitoso.

### 4. Configuración

En `GET /api/v1/devices/config`:

¿La autenticación es únicamente mediante:

`Authorization: Bearer <token>`

o requiere algún otro header?

### 5. Reprovisionamiento

Si el mismo UUID ejecuta nuevamente:

`POST /api/v1/devices/register`

¿Qué ocurre?

- reutiliza el mismo dispositivo y responde 200 OK;
- responde 409 Conflict;
- otro comportamiento (especificar).

### 6. Nombres de campos

Confirma los nombres exactos que devuelve EN1 para:

- access token
- empresa
- sucursal
- POS
- caja
- dispositivo

No los nombres conceptuales, sino las claves JSON reales.

### 7. Error estándar

Cuando ocurre un error, ¿EN1 devuelve exactamente este formato?

```json
{
  "error": {
    "code": "...",
    "message": "...",
    "details": {}
  }
}
```

Si no, mostrar el JSON real.

### 8. Ejemplo curl

Proporciona un ejemplo real de:

- register
- config

tal como se usarán en DEV.

### Objetivo

No modificar EN1 ni EPosOne todavía.

Primero validar que ambos implementan exactamente el mismo contrato antes de conectar la primera tablet.

---

## Checklist interno (cuando llegue la respuesta)

| # | Pregunta | ¿Respuesta recibida? | ¿Compatible con contrato v0.1? |
|---|----------|----------------------|--------------------------------|
| 1 | Código: A / B / C / D | ⏸ | → delta §1 |
| 2 | Request JSON | ⏸ | → delta §2.1 |
| 3 | Response 200 JSON | ⏸ | → delta §3 |
| 4 | Auth config | ⏸ | → delta §2.2 |
| 5 | Reprovisioning 200 vs 409 | ⏸ | → delta §5 (arquitectura) |
| 6 | Claves JSON reales | ⏸ | → delta §3 |
| 7 | Forma de error | ⏸ | → delta §4 |
| 8 | curl register + config | ⏸ | evidencia |

**Siguiente:** pegar respuesta de Prog1 en el delta → clasificar Compatible / Alias / Incompatible → aprobar ownership → recién tablet.

---

*EasyTech · EPosOne · Cuestionario Prog1*
