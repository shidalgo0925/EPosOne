# EPOSOne P0 — Documento maestro EN1 (CODITO) ↔ LOCAL

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **Rol** | Documento de referencia para CODITO y LOCAL mientras se cierra el P0 |
| **Alcance** | Decisiones arquitectónicas, comerciales y de UX validadas en pruebas reales |
| **Hosts PRD** | Comercial + API: `https://eposone.easytech.services` · `/start` |
| **APK actual** | Gate 2 MVP · defaults PRD · commit `3fac174` |

---

## Visión constitutiva

**EN1 es la plataforma de identidad, suscripciones, organizaciones, licenciamiento comercial y administración de dispositivos de EPOSOne. La APK es el cliente operativo del punto de venta y nunca administra el ciclo comercial ni la identidad del cliente.**

- **Una sola APK.** Standalone vs Connected = suscripción/entitlements EN1. La tablet nunca pregunta Local / Cloud / Online / Offline.
- EN1 = identidad, comercial, portal, códigos, ciclo de vida de dispositivos.
- LOCAL = Register, Bootstrap, PIN, operación POS.

---

## 0. Objetivo de producto (congelado)

Flyer → QR → `/start` (EN1) → cuenta → org → plan → suscripción → verificar correo → **descargar/instalar APK con ayuda** → Register → Bootstrap → PIN → Abrir caja → **primera venta**.

Ese es el happy path oficial. El onboarding no está cerrado hasta cumplir el criterio de la sección 10.

---

## 1. Modelo comercial (decisión congelada)

El cliente selecciona un plan: **Standalone**, **Starter**, **Business** o **Enterprise**.

Durante el onboarding **no se muestran precios**.

Cada plan crea automáticamente una suscripción con sus entitlements por defecto (POS, sucursales, features, licencias = configuración inicial).

El **contrato comercial firmado** es la autoridad sobre la negociación económica (asesores + gerencia).

Si existen excepciones (POS adicionales, sucursales, descuentos, módulos), Gerencia realiza un **override administrativo en EN1**.

El plan **nunca cambia**; solo cambian los recursos autorizados mediante overrides **auditables**.

> Nadie debe volver a intentar poner precios en el onboarding.

| Concepto | Autoridad |
|----------|-----------|
| Selección de plan | Usuario en `/start` (sin precio) |
| Precio / descuento / negociación | Contrato + Gerencia |
| Capacidad efectiva (POS, módulos, …) | Plan default + **overrides** EN1 |
| Modalidad Standalone / Connected | Entitlements de la suscripción |

**Standalone no significa “sin EN1”.** Significa: tiene cuenta, organización, suscripción y recursos; cambian solo los entitlements disponibles. Puede usar el Portal EN1 con los módulos permitidos.

---

## 2. Portal de Instalación (autoridad de dispositivos)

El Portal de Instalación **no** es “un portal para bajar una APK”.

Es la **única autoridad** para administrar la instalación de dispositivos.

Permite:

- visualizar el plan;
- visualizar la modalidad;
- visualizar los recursos contratados;
- visualizar los POS instalados;
- visualizar los POS disponibles;
- generar códigos de aprovisionamiento;
- generar QR técnicos;
- reaprovisionar dispositivos;
- administrar el ciclo de vida de los dispositivos.

Nunca muestra precios.

Cada nueva tablet **consume** un recurso autorizado (plan + overrides). Ejemplo: Business con 5 POS autorizados → 2 instalados → 3 disponibles.

---

## 3. Separación de responsabilidades

### EN1 (CODITO)

| Dominio | Estado |
|---------|--------|
| Cuenta / Login / Org / Plan / Suscripción | Producto `/start` en PRD |
| Modelo comercial sin precios + overrides | Decisión aprobada · impl parcial |
| Portal = autoridad de dispositivos (recursos + lifecycle) | Decisión aprobada · ampliar UI |
| Provision code + QR técnico | ✅ |
| Issue code / Session / Login onboarding HTTP | ✅ freeze `eposone-onboarding-p0-v1.4` |
| Modalidad `standalone` \| `connected` | ✅ en session/config |
| User Bearer ≠ Device Bearer | ✅ contrato |
| **D-01 Organization Resolver** | ❌ P0 crítico |
| **P0.17 Reaprovisionamiento lifecycle** | ❌ P0 crítico |
| **P0.18 Asistente instalación Android** | ❌ P0 crítico |
| QR de **ayuda** (guía/video/WhatsApp; no re-descarga) | ❌ (con P0.18) |
| Verificación correo / password UX | Pendiente |
| Descarga APK guiada + progreso | Pendiente / parcial |
| Auditoría de overrides y reaprovisionamiento | Pendiente |

### LOCAL (EP1)

| Dominio | Estado |
|---------|--------|
| Welcome 4 caminos (sin Modo Local) | ✅ Gate 2 |
| Defaults PRD `eposone.easytech.services` | ✅ |
| Abrir `/start` comercial | ✅ |
| Login onboarding + session + issue-code (User Bearer) | ✅ |
| Activar con código / pegar / escanear QR → Register | ✅ |
| Restore UI (login → org/caja → issue → Register → Bootstrap) | ✅ MVP (compuesto; **sin** endpoint `/restore`) |
| Reprovision desde «Este dispositivo» (mismo UUID + código) | ✅ parcial |
| Register + Bootstrap + PIN (pipeline único) | ✅ |
| Auth recovery 401 → Connect | ✅ |
| Progreso bootstrap rico | 🟡 básico |
| Deep link desde EN1 (post-onboarding → aprovisionar) | ❌ |
| Reaprovisionamiento completo P0.17 | ❌ espera contrato EN1 endurecido |
| Asistente permisos Android | **N/A en APK** — web EN1 (P0.18) |

LOCAL **no** administra: usuarios, organizaciones, suscripciones, planes, pagos, overrides, precios.

---

## 4. Tokens (no mezclar)

```text
User Bearer   →  solo asistente / portal onboarding (/api/v1/onboarding/*)
Device Bearer →  solo POS (register → config/bootstrap/orders/cash)
PIN cajero    →  local; no es login HTTP
```

---

## 5. Flujo oficial (producto)

```text
Flyer → QR comercial → /start
  → cuenta → org → plan (sin precio) → suscripción → recursos default
  → verificar correo
  → Asistente instalación Android (EN1)   ← P0.18
  → APK instalada
  → Register → Bootstrap → PIN → Caja → Venta
```

Caminos APK (Gate 2) — todos convergen al mismo pipeline:

| Camino | Entrada APK | HTTP |
|--------|-------------|------|
| A | Crear negocio → browser `/start` | Web EN1 |
| B | Ya tengo cuenta | login → session → issue → **register** → bootstrap |
| C | Activar con código / QR técnico | **register** → bootstrap |
| D | Restaurar | login → session → (issue) → **register** → bootstrap |

---

## 6. Descubrimientos de las pruebas reales

Durante la validación con el flyer se identificaron los siguientes puntos críticos:

| ID | Hallazgo | Decisión / estado |
|----|----------|-------------------|
| **D-01** | **Resolver de Organización incorrecto.** El primer login después de `/start` abrió otra organización (p.ej. Mexican Food). | **P0 crítico.** Prioridad: `organization_id` explícito → org recién creada → org seleccionada → última → selector → única. Nunca reutilizar automáticamente la última cuando existe una creación reciente. |
| **D-02** | **Reaprovisionamiento incompleto.** Cambio de tablet y reinstalación aún no cubren todo el ciclo de vida. | **P0 crítico** (= P0.17). |
| **D-03** | **Instalación Android.** Muchos usuarios no saben habilitar “Instalar aplicaciones desconocidas”. Se requiere asistente visual. | **P0 crítico** (= P0.18). |
| **D-04** | Onboarding muestra precios. | **Aprobado:** eliminar precios; solo selección de plan. |
| **D-05** | El portal debe administrar recursos y no solamente generar códigos. | **Aprobado:** Portal = autoridad de instalación de dispositivos (sección 2). |

---

## 7. P0.17 — Reaprovisionamiento (D-02)

### Problema

Cliente que cambia tablet / reinstala / factory reset puede quedar bloqueado. Hoy LOCAL puede pedir código y re-register, pero el **ciclo de vida completo** (invalidar device anterior, listar devices autorizados, casos robado/perdido, códigos vencidos/usados) depende de EN1 y no está certificado E2E.

### Flujo esperado

```text
Login → Org → Ver devices autorizados → Seleccionar device/caja
  → Reaprovisionar
  → EN1 invalida Device Bearer anterior + emite código nuevo
  → LOCAL: Register → Bootstrap → Operar
```

### Validaciones

Equipo perdido / robado / reemplazado / reinstall / factory reset / código vencido / código ya usado.

| Actor | Hace |
|-------|------|
| **EN1** | Lifecycle, nuevo código, invalidación bearer, auditoría, errores estables |
| **LOCAL** | UI restore/reprovision, consumir código, Register, Bootstrap (un solo pipeline) |

**Bloqueo LOCAL:** no inventar endpoint `/restore`; extender UI cuando CODITO actualice el freeze (delta sobre Gate 1).

---

## 8. P0.18 — Asistente instalación Android (D-03)

### Problema

Android bloquea APK desconocidas → el usuario abandona. El comerciante no piensa “Descargas → Abrir”.

### Tipos de QR (decisión)

| QR | Uso | Prohibido |
|----|-----|-----------|
| **Comercial** | Flyer → `/start` | — |
| **Técnico** | String del provision code → APK Camino C | Usarlo para re-descargar la APK |
| **Ayuda** | Guía / video / FAQ / marca / WhatsApp | Repetir descarga de la APK |

El QR de la pantalla de bloqueo Android es de **asistencia**, no de re-descarga.

### Qué construye EN1 (web)

1. Progreso de descarga (no enlace suelto).  
2. Botón grande **INSTALAR EPOSOne**.  
3. Si bloquea: guía paso a paso (+ “¿Cómo habilito la instalación?”).  
4. Selector de marca (Samsung, Xiaomi, Honor, Motorola, Huawei, …).  
5. QR de ayuda + “No puedo instalar”.  
6. Documentar Android 10–15.

### Qué hace LOCAL después

- Deep link / flag de onboarding → ir a **aprovisionamiento** sin pedir de nuevo correo/org/plan (pendiente contrato).  
- Mantener Camino C (código/QR técnico) para quien ya tiene código.

---

## 9. Prioridad de trabajo (orden vigente)

### EN1

1. **D-01** Resolver de Organización.  
2. **P0.17** Reaprovisionamiento (D-02).  
3. **P0.18** Asistente de instalación Android (D-03).  
4. Eliminar precios del onboarding (D-04).  
5. Overrides comerciales.  
6. Mejorar contraseña.  
7. Mejorar verificación de correo.  
8. Descarga guiada de la APK.  
9. QR de ayuda.  
10. Auditoría.

### LOCAL (Sprint Ana · P0.19–P0.30)

Ver [`EPOSONE_P0_LOCAL_SPRINT_V1.md`](EPOSONE_P0_LOCAL_SPRINT_V1.md).

1. **P0.19** Consumir reaprovisionamiento (espera freeze EN1 P0.17).  
2. **P0.20** Deep Link desde EN1 → Register.  
3. **P0.21–P0.24** Bootstrap progreso + errores + offline + no re-register.  
4. **P0.25–P0.29** PIN/caja, licencias, mensajes, “está listo”.  
5. **P0.30** Certificación E2E.

---

## 10. Criterio de “P0 / onboarding cerrado”

Solo cuando:

- [ ] D-01 Org Resolver correcto post-/start.  
- [ ] D-02 / P0.17 Reaprovisionamiento E2E en PRD.  
- [ ] D-03 / P0.18 Asistente Android + QR ayuda.  
- [ ] D-04 Sin precios en onboarding.  
- [ ] D-05 Portal muestra plan, modalidad, recursos contratados/instalados/disponibles y lifecycle.  
- [ ] Flyer → primera venta sin soporte técnico en prueba demo.  
- [ ] LOCAL: un solo pipeline Register → Bootstrap → PIN → Caja → Operar.

Hasta entonces: Gate 2 APK = **asistente tablet MVP**; producto P0 = **no cerrado**.

---

## 11. Referencias repo LOCAL

| Doc | Rol |
|-----|-----|
| [`Doc/EPOSONE_P0_LOCAL_SPRINT_V1.md`](EPOSONE_P0_LOCAL_SPRINT_V1.md) | Sprint LOCAL Ana P0.19–P0.30 |
| [`Doc/EPOSONE_P0_ONBOARDING_E2E_CERT_CHECKLIST_V1.md`](EPOSONE_P0_ONBOARDING_E2E_CERT_CHECKLIST_V1.md) | Certificación E2E |
| Este archivo | **Documento maestro** P0 · modelo comercial · portal · descubrimientos · prioridades |
| [`Doc/ADR-032-EPOSONE-IMPLEMENTATION-MODEL-V1.md`](ADR-032-EPOSONE-IMPLEMENTATION-MODEL-V1.md) | **PROPOSED** · Autogestionada (Standalone) vs Asistida (Connected) · sin impl |
| [`Doc/EN1_ONBOARDING_P0/GATE1_HTTP_FROZEN_FOR_LOCAL.md`](EN1_ONBOARDING_P0/GATE1_HTTP_FROZEN_FOR_LOCAL.md) | HTTP freeze |
| [`Doc/EN1_ONBOARDING_P0/RESTORE_CONTRACT_V1.md`](EN1_ONBOARDING_P0/RESTORE_CONTRACT_V1.md) | Restore compuesto |
| [`Doc/EN1_ONBOARDING_P0/QR_CONTRACT_V1.md`](EN1_ONBOARDING_P0/QR_CONTRACT_V1.md) | QR técnico = código |
| [`Doc/EN1_ONBOARDING_P0/GATE2_LOCAL_IMPL_STATUS.md`](EN1_ONBOARDING_P0/GATE2_LOCAL_IMPL_STATUS.md) | Estado Gate 2 APK |
| [`Doc/EPOSONE_ONBOARDING_P0_LOCAL_IMPL_PLAN_V1.md`](EPOSONE_ONBOARDING_P0_LOCAL_IMPL_PLAN_V1.md) | Plan fases LOCAL |
