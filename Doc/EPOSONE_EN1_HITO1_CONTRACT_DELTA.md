# Informe de diferencias — Contrato v0.1 vs EN1 DEV

**Estado del documento:** 🟢 **CERRADO — EPosOne adaptado a EN1-02**  
**Fecha:** 10 de julio de 2026  
**Decisión:** Opción 1 — EPosOne consume el contrato oficial EN1-02 (código ligado a Caja; wizard solo URL + código).  
**Contrato oficial:** [`EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md`](EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md)  
**Cliente:** `features/platform/` actualizado · `flutter analyze` platform: No issues found  

> Las filas siguientes documentan el delta histórico v0.1 vs EN1 Dev.  
> Tras EN1-02, el APK ya no envía refs ni `activation_code`; usa header + parser anidado.

### Clasificación

| Etiqueta | Significado |
|----------|-------------|
| **Compatible** | Mismo comportamiento / mismo nombre |
| **Alias soportado** | EN1 usa un alias que el cliente Flutter **ya** acepta |
| **Incompatible** | Rompe el cliente actual; requiere decisión |

---

## 0. Resumen ejecutivo

| Ítem | Resultado |
|------|-----------|
| ¿Hay diferencias incompatibles? | **Sí — muchas (bloqueantes)** |
| ¿Se puede probar tablet hoy? | ❌ **No** — el APK actual **no** hablará con EN1 Dev sin alinear |
| ¿Quién debe mover primero? | **Decisión de arquitectura** (ver §9) |

**Veredicto:** el contrato v0.1 (lado EPosOne) y la API real EN1 Dev **no implementan el mismo lenguaje**. No es un ajuste cosmética: request, response, HTTP, errores y código de provisioning difieren.

**Alertas de Prog1 confirmadas:** si EPosOne espera `activation_code`, error anidado, HTTP 200/409 en reprovision → hay que alinear APK **o** contrato **o** EN1.

---

## 1. Código de provisioning (crítico)

| Aspecto | Contrato / Flutter v0.1 | EN1 DEV (real) | Clasificación | Owner propuesto |
|---------|-------------------------|----------------|---------------|-----------------|
| Canal | Solo body | Header **preferido** + body alternativo | **Incompatible** | Arquitectura |
| Clave body | `activation_code` | `provisioning_code` (**no** acepta `activation_code`) | **Incompatible** | Arquitectura |
| Header | No usado | `X-EN1-Provisioning-Code` (preferido) | **Incompatible** | Arquitectura |
| Header alt. | — | `X-EPosOne-Provisioning-Code` | **Incompatible** (Flutter no lo envía) | Arquitectura |
| Prioridad EN1 | — | header EN1 → header EPosOne → body | Info | — |

**Decisión requerida:** un mecanismo canónico. Opciones:

| Opción | Qué implica |
|--------|-------------|
| **A — Flutter se adapta a EN1** | Enviar header `X-EN1-Provisioning-Code` (+ opcional body `provisioning_code`); dejar de enviar `activation_code` |
| **B — EN1 acepta contrato v0.1** | Aceptar también `activation_code` en body (y/o dejar de exigir header) |
| **C — Contrato v0.2** | Documentar el comportamiento EN1 como canónico y adaptar Flutter |

---

## 2. Endpoints y headers

### 2.1 POST register

| Aspecto | Contrato / Flutter | EN1 DEV | Clasificación | Owner propuesto |
|---------|--------------------|---------|---------------|-----------------|
| Base URL | Configurable en wizard | `https://appdev.easynodeone.com` | **Compatible** (URL no hardcodeada) | — |
| Ruta | `/api/v1/devices/register` | `/api/v1/devices/register` | **Compatible** | — |
| Método | `POST` | `POST` | **Compatible** | — |
| `Content-Type: application/json` | Sí | Sí | **Compatible** | — |
| Header provisioning | No | **Obligatorio efectivo** (o body `provisioning_code`) | **Incompatible** | Arquitectura |

### Body request — campos

| Campo contrato Flutter | EN1 espera | Clasificación | Owner propuesto |
|------------------------|------------|---------------|-----------------|
| `uuid` | Canónico EN1: `device_uuid` · alias EN1: `uuid` | **Alias parcial** — Flutter envía `uuid`; EN1 lo acepta como alias | Revisar: ¿alias alcanza? Si sí → Alias; si Flutter solo manda `uuid` OK |
| `model` | `device_model` · alias EN1: `model` | **Alias soportado** (si EN1 alias `model` cubre) | — |
| `os` | `android_version` + `platform` | **Incompatible** (nombres/semántica distintos) | Arquitectura |
| `app_version` | `app_version` | **Compatible** | — |
| `activation_code` | **No aceptado** · usa header / `provisioning_code` | **Incompatible** | Arquitectura |
| — | `organization_id` **o** `organization_ref` (**obligatorio**) | **Incompatible** — Flutter **no** lo envía | Arquitectura |
| — | `branch_ref` (**obligatorio**) | **Incompatible** — Flutter no lo envía | Arquitectura |
| — | `pos_ref` (**obligatorio**) | **Incompatible** — Flutter no lo envía | Arquitectura |
| — | `register_ref` (**obligatorio**) | **Incompatible** — Flutter no lo envía | Arquitectura |
| — | `device_name` (opcional) | Info | — |
| — | `platform` | Info / Incompatible vs `os` | Arquitectura |

**Hallazgo grave:** el wizard actual solo pide **URL + código**. EN1 exige además **organización + branch_ref + pos_ref + register_ref** en el register. Eso cambia UX y contrato, no solo un rename.

### 2.2 GET config

| Aspecto | Contrato / Flutter | EN1 DEV | Clasificación | Owner propuesto |
|---------|--------------------|---------|---------------|-----------------|
| Ruta | `/api/v1/devices/config` | `/api/v1/devices/config` | **Compatible** | — |
| Auth | `Authorization: Bearer {token}` | Solo Bearer | **Compatible** | — |
| Headers extra auth | No | No | **Compatible** | — |

---

## 3. Response éxito — forma y campos

| Aspecto | Contrato / Flutter | EN1 DEV | Clasificación | Owner propuesto |
|---------|--------------------|---------|---------------|-----------------|
| HTTP éxito | **200** | **201** (alta y reprovision) | **Incompatible** | EPosOne (aceptar 201) o EN1 (también 200) |
| Forma | Plana o `{ "data": {…} }` | Anidada: `access_token` + `device` + `config` | **Incompatible** | Arquitectura |
| `access_token` | Sí (raíz) | Sí (raíz) | **Compatible** | — |
| `token_type` | No en contrato | `"Bearer"` | Compatible (ignorable) | — |
| `device_id` | Obligatorio (plano) | **No existe** · hay `device.uuid` | **Incompatible** | Arquitectura |
| `empresa_id` / `company_id` | Obligatorio | `organization.id` / `device.organization_id` | **Incompatible** (no alias Flutter) | Arquitectura |
| `sucursal_id` / `branch_id` | Obligatorio | `branch.ref` / `device.branch_ref` | **Incompatible** | Arquitectura |
| `pos_id` | Obligatorio | `pos.ref` / `device.pos_ref` | **Incompatible** | Arquitectura |
| `caja_id` / `cash_register_id` | Obligatorio | `register.ref` / `device.register_ref` | **Incompatible** (`register_id` tampoco mapea solo) | Arquitectura |
| Nombres | `empresa_name`, etc. | `organization.name`, `branch.name`, … / `business_name` | **Incompatible** | Arquitectura |

### Tabla §6 Prog1 vs aliases Flutter

| Concepto | Clave EN1 real | ¿Alias Flutter cubre? | Clasificación |
|----------|----------------|----------------------|---------------|
| Token | `access_token` | Sí | **Compatible** |
| Empresa | `config.organization` / `organization_id` | No (`empresa_id`/`company_id` planos) | **Incompatible** |
| Sucursal | `branch.ref` | No | **Incompatible** |
| POS | `pos.ref` | No | **Incompatible** |
| Caja | `register.ref` | No (`register_id` **no** está en aliases) | **Incompatible** |
| Dispositivo | `device.uuid` | No como `device_id` plano | **Incompatible** |

**Response 201 real (referencia):** ver respuesta Prog1 — estructura `device` + `config` anidados.

---

## 4. Errores HTTP y JSON

| Aspecto | Contrato / Flutter | EN1 DEV | Clasificación | Owner propuesto |
|---------|--------------------|---------|---------------|-----------------|
| Forma | `{ "error": { "code", "message", "details" } }` | `{ "error": "<string código>" }` | **Incompatible** | Arquitectura |
| `message` / `details` | Sí | No | **Incompatible** | Arquitectura |
| HTTP | 400/401/403/404/409/422/500 | 400/401/403/404 (según caso) | Parcial — sin 422/409 documentados igual | Revisar |
| Códigos tipo `INVALID_ACTIVATION_CODE` | Esperados | Ej. `device_uuid_required` (snake) | **Incompatible** (convención distinta) | Arquitectura |

El cliente Flutter mapea `error.code` anidado. Con EN1 actual fallará el parseo de errores (UX genérica / unknown).

---

## 5. Reprovisioning

| Escenario | Expectativa E2E / contrato EPosOne | EN1 DEV real | Clasificación | Owner propuesto |
|-----------|-------------------------------------|--------------|---------------|-----------------|
| Mismo UUID otra vez | Ideal 200 + mismo device; contrato listaba 409 como conflicto | **Reutiliza device**, **rota token**, `config_version++`, **HTTP 201** (no 200, no 409) | **Incompatible** con contrato escrito; **alineado en espíritu** con “no duplicar” | Arquitectura → actualizar contrato a **201 + rotate token** |
| Token anterior | No definido | **Deja de valer** | Info crítica para APK (debe guardar el nuevo token) | EPosOne (al adaptar) |

**Decisión unificada propuesta (para aprobar):**

- [x] **Propuesta:** adoptar comportamiento EN1 — **201 + reutiliza + rota token** (ni 200 ni 409)
- [ ] Alternativa: EN1 cambia a 200 sin rotar / o 409 — **no recomendado** si Dev ya smoke-testeó esto

---

## 6. Inventario de diferencias (solo hallazgos)

| # | Tema | Contrato / Flutter | EN1 | Clasificación | Owner propuesto | Acción |
|---|------|--------------------|-----|---------------|-----------------|--------|
| 1 | Código provisioning | `activation_code` body | Header `X-EN1-Provisioning-Code` / body `provisioning_code` | Incompatible | Arquitectura | Elegir A/B/C §1 |
| 2 | Request mínimo | uuid+model+os+app_version+code | + org + branch_ref + pos_ref + register_ref | Incompatible | Arquitectura | Definir si wizard pide refs o código las implica |
| 3 | `uuid` vs `device_uuid` | `uuid` | `device_uuid` (alias `uuid`) | Alias / verificar | EPosOne test | Confirmar alias en Dev |
| 4 | `os` / `model` | `os`, `model` | `platform`, `android_version`, `device_model` | Incompatible | Arquitectura | Mapear en cliente o aceptar aliases EN1 |
| 5 | HTTP éxito | 200 | 201 | Incompatible | EPosOne | Aceptar 2xx/201 en cliente |
| 6 | Response shape | Plano IDs | Anidado `device`+`config` | Incompatible | Arquitectura | Adapter Flutter **o** DTO EN1 legacy |
| 7 | IDs empresa/sucursal/POS/caja | `*_id` strings planos | `ref` + `organization.id` | Incompatible | Arquitectura | Redefinir persistencia local |
| 8 | Error JSON | Objeto anidado | String en `error` | Incompatible | Arquitectura | Adapter parseo **o** EN1 envelope |
| 9 | Reprovision HTTP | 200 o 409 | 201 + rotate token | Incompatible (doc) | Contrato v0.2 | Documentar comportamiento EN1 |
| 10 | GET config auth | Bearer | Bearer | Compatible | — | Ninguna |

---

## 7. Evidencia

| Fuente | Detalle |
|--------|---------|
| Base DEV | `https://appdev.easynodeone.com` |
| Commit EN1 | `847a09f` |
| curl register / config | Incluidos en respuesta Prog1 |
| Refs smoke | `hito1-branch` / `hito1-pos` / `hito1-caja` · org `1` |
| Código provisioning | BackOffice EPosOne → Dispositivos (org) |

---

## 8. Implicación para la prueba tablet

| Paso E2E planeado | ¿Funciona con APK actual vs EN1 Dev? |
|-------------------|--------------------------------------|
| Wizard → URL + código → register | ❌ No (falta header/código correcto + refs + shape) |
| Guardar token / IDs | ❌ Parser no entiende response anidada |
| GET config | ⚠ Auth OK **si** hubiera token; parser igual falla |
| Este dispositivo | ❌ Sin IDs mapeados |
| Reprovision | ❌ Cliente no espera 201 ni rotate |

**Conclusión:** tablet E2E **bloqueada** hasta alinear.

---

## 9. Opciones de alineación (para arquitectura)

### Opción 1 — EPosOne se adapta a EN1 (recomendación técnica si EN1 Dev ya está smoke-ok)

- Actualizar contrato a **v0.2** = comportamiento EN1 documentado por Prog1.  
- Adaptar cliente Flutter (`En1ProvisioningApi` + wizard si hacen falta refs).  
- Owner código: **EPosOne**. Owner doc: **Contrato**.  
- EN1: sin cambios (o solo docs).

### Opción 2 — EN1 ofrece compatibilidad con contrato v0.1

- Aceptar `activation_code`, body mínimo Flutter, response plana, error anidado, HTTP 200.  
- Owner: **EN1**.  
- Riesgo: duplicar dos shapes en servidor.

### Opción 3 — Híbrido

- EN1 acepta `activation_code` como alias de `provisioning_code` + header opcional.  
- EPosOne adapta parser a response anidada + HTTP 201 + error string.  
- Definir cómo salen `organization_id` / refs (código de provisioning ¿ya implica org+branch+pos+caja en EN1?).

> **Pregunta abierta a Prog1 / arquitectura:** si el código de provisioning ya está atado a org+branch+pos+caja en BackOffice, ¿pueden volverse **opcionales** en el body los refs cuando el header trae el código? Eso simplificaría el wizard EPosOne (URL + código solamente).

---

## 10. Aprobación

| Rol | Decisión | Fecha | OK |
|-----|----------|-------|-----|
| Arquitectura | Elegir Opción 1 / 2 / 3 (+ respuesta refs vía código) | | |
| EPosOne | | | |
| EN1 (Prog1) | | | |

**Tras aprobación:** implementar **solo** lo del owner indicado → re-validar delta → **entonces** tablet limpia.

**Prohibido ahora:** modificar Flutter, modificar EN1, o generar APK demo 4 estaciones.

---

*EasyTech · EPosOne · Delta contrato Hito 1 — 10 jul 2026 · EN1 commit 847a09f*
