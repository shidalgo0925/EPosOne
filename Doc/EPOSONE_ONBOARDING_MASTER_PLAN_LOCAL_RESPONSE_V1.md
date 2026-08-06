# LOCAL — Respuesta al Plan Maestro de Onboarding e Instalación V1

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **Rol** | LOCAL (EP1 / APK) |
| **Plan de referencia** | EPOSOne — Plan Maestro de Onboarding e Instalación V1 (propuesta funcional) |
| **Estado de esta respuesta** | As-is + gaps · **sin implementación** |
| **Plan impl. LOCAL (bloqueado)** | [`EPOSONE_ONBOARDING_P0_LOCAL_IMPL_PLAN_V1.md`](EPOSONE_ONBOARDING_P0_LOCAL_IMPL_PLAN_V1.md) — Fases 1–8 · gate CODITO |
| **Complemento UX** | [`EPOSONE_PROVISIONING_UX_REVIEW_V1.md`](EPOSONE_PROVISIONING_UX_REVIEW_V1.md) |

---

## 0. Resumen ejecutivo

| Afirmación del Plan Maestro | ¿LOCAL lo tiene hoy? |
|-----------------------------|----------------------|
| Una sola APK | **Sí** |
| Toda instalación empieza en EN1 | **No** — Welcome ofrece Local sin EN1 |
| Standalone = cuenta EN1 sin sync operativa | **No** — `PlatformMode.local` = sin EN1 (ADR-014) |
| APK solo desde EN1 | **No** — OTA EN1 en espera de freeze P1; distribución actual fuera de canal EN1 |
| Register + Bootstrap | **Sí** (Connected / `platform`) |
| Camino código provisioning | **Sí** |
| Camino QR instalación | **No** |
| Camino Login EN1 en APK | **No** |
| Camino Restaurar instalación | **Parcial** (reprovision / disconnect; no restore formal) |
| Portal cliente /start | **Fuera de EP1** (EN1) |
| Trial 15d / Grace 7d | **APK no hardcodea** — lee snapshot EN1 (docs ADR-007 hablan 45d trial) |

**Conclusión:** el Plan Maestro es coherente como **objetivo de producto**, pero **diverge** del Dual Mode actual (ADR-014 + Welcome Local). LOCAL puede reutilizar Register/Bootstrap; los caminos QR / Login EN1 / Restore / Standalone-via-EN1 requieren **contratos EN1 + decisión de producto** antes de código.

---

## 1. Entregable LOCAL — Estado de la APK

### 1.1 Flujo actual (as-is)

```text
APK fresca
  → /splash
  → /platform/welcome
        ├─ Local (Standalone hoy) → onboarding local → PIN → caja → POS
        └─ Plataforma (Connected) → /platform/connect (URL + código)
              → POST /devices/register
              → /platform/bootstrap (GET /devices/bootstrap)
              → (/onboarding si isSetupComplete=false)  ← gap
              → /pin → /cash/open → /pos
```

Detalles: pantallas, fallos, endpoints → [`EPOSONE_PROVISIONING_UX_REVIEW_V1.md`](EPOSONE_PROVISIONING_UX_REVIEW_V1.md).

### 1.2 Pantallas vs Plan Maestro (asistente)

| Pieza del Plan | Estado EP1 |
|----------------|------------|
| ¿Instalación válida? → Login cajero | **Parcial** — startup/lifecycle; no asistente unificado |
| Asistente: Escanear QR | **Pendiente** |
| Asistente: Ingresar código | **Implementado** (`ConnectEn1Screen`) |
| Asistente: Iniciar sesión EN1 | **Pendiente** |
| Asistente: Restaurar | **Pendiente** (hay Reaprovisionar + Desconectar) |
| Progreso bootstrap checklist | **Parcial** (pantalla bootstrap; no checklist rica) |
| Instalación finalizada → PIN | **Parcial** (gap onboarding) |
| Descarga APK desde EN1 (cliente) | **Pendiente** (spec OTA wait P1) |

### 1.3 Detección (preguntas EP1 del Plan)

| Pregunta | Respuesta LOCAL |
|----------|-----------------|
| ¿Qué pantallas existen? | Welcome, Connect, Bootstrap, License, Device, PIN, Cash open, Onboarding local, POS (+ Settings) |
| ¿Cuáles faltan vs Plan? | Asistente unificado, QR install, Login EN1, Restore, “Listo”, portal (EN1), OTA APK |
| ¿Cómo detectar instalación previa? | `ProvisioningStore` (token/config) + `PlatformPrefs` + `InstallationLifecycle` (`readyToOperate`) |
| ¿Cómo detectar reinstalación? | **Débil** — APK nueva pierde prefs; UUID puede regenerarse según `DeviceRegistry`; no hay “restore token” |
| ¿Cómo detectar cambio de tablet? | **No** — UUID nuevo = dispositivo nuevo; hace falta código/register de nuevo (sin flujo “mover caja”) |
| ¿Contrato para Login EN1? | **No existe** en cliente Device HTTP; haría falta freeze EN1 (auth admin + list org/branch/register + emitir provisioning) |
| ¿Reutilizar Register + Bootstrap? | **Sí** — todos los caminos del Plan deben converger a `POST register` + `GET bootstrap` + gate ADR-014 |

### 1.4 Propuesta UX LOCAL (alineada al Plan, mínima fricción contractual)

Sin tocar código hasta aprobación:

1. **Documentar / Manual ahora** = flujo Connected real (código) + Local actual (con disclaimer de divergencia).  
2. **Objetivo UX (C del review):** asistente con **Código + QR** convergentes a Register/Bootstrap; welcome “Nueva caja / Reaprovisionar”.  
3. **Login EN1 (Camino 3):** solo tras contrato CODITO.  
4. **Standalone “con cuenta EN1”:** requiere redefinir Dual Mode (hoy Local ≠ Standalone del Plan).

### 1.5 Gaps de implementación (EP1)

| Gap | Bloqueo |
|-----|---------|
| Unificar Welcome → Asistente (quitar “Local vs EN1” o renombrar) | Decisión producto vs ADR-014 |
| Standalone con licencia EN1 sin sync | Contrato modalidad + bootstrap/license policy |
| QR técnico (URL + code/token) | Formato QR + EN1 emite QR; LOCAL: scanner (ya hay `mobile_scanner` para productos) |
| Login EN1 en APK | Contrato HTTP nuevo |
| Restore / cambio de tablet | Contrato device transfer |
| OTA APK desde EN1 | Freeze P1 ([`EPOSONE_EN1_APK_UPDATE_WAIT_P1_2026-08-05.md`](EPOSONE_EN1_APK_UPDATE_WAIT_P1_2026-08-05.md)) |
| Fix `isSetupComplete` post-bootstrap | **Solo LOCAL** — candidato a quick win tras GO |
| Portal /start / planes / trial UX | **EN1** (fuera de APK) |

---

## 2. Preguntas del Plan — alcance

### CODITO / EN1 (LOCAL no responde SoT)

- Dónde se almacena modalidad Standalone/Connected.  
- Quién la expone / endpoint.  
- ¿APK puede conocer modalidad automáticamente?  
- Qué debe devolver bootstrap / ¿endpoint onboarding?  
- Portal, /start, planes, facturación, descarga APK servidor.

### LOCAL (arriba §1.3) — respondido as-is.

### QR

| Tipo | Estado |
|------|--------|
| Comercial → `/start` | EN1 (web); APK no |
| Técnico (URL + provisioning token) | No implementado; viable sobre Camino 2 sin login BO |

---

## 3. Tensiones con principios del Plan (hay que decidir)

| Principio Plan | Realidad LOCAL / ADR |
|----------------|----------------------|
| EN1 único punto de entrada comercial | Welcome permite Local sin EN1 |
| Standalone ≠ sin EN1 | `PlatformMode.local` = sin EN1 |
| APK siempre desde EN1 | Canal OTA no congelado; builds locales/manuales |
| Trial 15 / Grace 7 | APK usa fechas del snapshot; docs comerciales mencionan trial 45d |

Hasta alinear **producto + ADR-014 + comercial**, el “único flujo oficial” del Plan **no** puede declararse implementado en EP1.

---

## 4. Qué reutilizar sin inventar (cuando haya GO)

```text
Caminos 1–4 del Plan
        │
        ▼
POST /api/v1/devices/register   ← ya existe
        │
        ▼
GET /api/v1/devices/bootstrap   ← ya existe
        │
        ▼
InstallationLifecycle gate      ← ya existe
        │
        ▼
PIN → Caja → POS                ← ya existe
```

Nuevo = **UX de entrada + contratos** (QR payload, login admin, restore, modalidad), no un segundo motor de instalación.

---

## 5. Licenciamiento

- Motor local: `LicenseSnapshot` + `GraceManager` + gate bootstrap.  
- Días trial/grace: **los define EN1** en el snapshot (no hardcode 15/7 en APK).  
- LOCAL: no introducir tercer período; alinear Manual con lo que CODITO publique.

---

## 6. Manuales

Con el Plan congelado + as-is LOCAL, se pueden derivar:

| Manual | Base actual |
|--------|-------------|
| Instalación | Flujo Connect + Bootstrap (Camino 2) |
| Administrador | EN1 BO + Device Info / Reprovision |
| Cajero | PIN + caja + POS (P0 cert) |
| Soporte | Recovery 401, disconnect, reprovision |
| Recuperación | Parcial hasta exista Restore contractual |

---

## 7. Recomendación LOCAL

1. **Congelar decisión de producto** sobre Standalone (Plan vs ADR-014).  
2. CODITO entrega as-is EN1 + contratos (modalidad, QR, login, restore, OTA).  
3. LOCAL ejecuta [`EPOSONE_ONBOARDING_P0_LOCAL_IMPL_PLAN_V1.md`](EPOSONE_ONBOARDING_P0_LOCAL_IMPL_PLAN_V1.md) **solo tras GO CODITO**.  
4. Hasta entonces: **cero código** de onboarding nuevo.

**Estado:** Plan Maestro recibido · EP1 as-is documentado · **impl P0 Onboarding = BLOQUEADA a GO CODITO**.
