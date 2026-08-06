# EP1 — Revisión del flujo de instalación (Provisioning UX)

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **Rol** | LOCAL (EPOSOne APK) |
| **Objetivo** | Estado real antes del Manual Oficial de Instalación |
| **Alcance** | Solo análisis · **sin cambios de código** |
| **SoT código** | `eposone/lib/src/features/platform/` · `app_startup` · `app_router` |
| **Contratos** | EN1-02 register · Hito 2 bootstrap · ADR-014 · Reprovision UX |

---

## 1. Estado actual — tablet nueva (modo Plataforma)

### Flujo completo (happy path)

```text
APK fresca
  → /splash
  → /platform/welcome          «Local» | «Conectar EasyNodeOne»
  → /platform/connect          URL API + código Caja
  → POST /api/v1/devices/register
  → SnackBar éxito (no pantalla dedicada)
  → /platform/bootstrap        GET /api/v1/devices/bootstrap (bloqueante)
  → evaluate() readyToOperate
  → /onboarding  (*)           a menudo, si isSetupComplete=false
  → /pin                       selección cajero + PIN
  → /cash/open                 si no hay turno
  → /pos
```

(\*) **Gap real:** tras bootstrap EN1, `isSetupComplete` suele seguir `false` (solo lo pone el wizard local). La APK puede caer en `/onboarding` aunque ya tenga cajeros EN1. No es login EN1; es deuda de arranque.

### Qué pantallas aparecen

| Orden | Ruta | Pantalla |
|------:|------|----------|
| 1 | `/splash` | Splash |
| 2 | `/platform/welcome` | Bienvenida Local vs Plataforma |
| 3 | `/platform/connect` | Conectar EN1 (URL + código) |
| 4 | `/platform/bootstrap` | Descarga bootstrap / gate ADR-014 |
| 5 | `/onboarding` | Wizard negocio local (condicional) |
| 6 | `/pin` | Cajeros + PIN |
| 7 | `/cash/open` | Apertura de turno |
| 8 | `/pos` | Operación |

### Datos que solicita la APK

| Pantalla | Datos usuario |
|----------|---------------|
| Welcome | Solo elección Local / Plataforma |
| Connect | **URL del servidor EN1** + **código de provisioning** |
| Bootstrap | Ninguno (automático) |
| PIN | Cajero + PIN 4–6 |
| Cash open | Monto de apertura |

**No pide:** usuario/contraseña EN1, organización, sucursal ni caja. Eso viene en la respuesta de `register` (config asociada al código de Caja).

UUID del dispositivo: lo genera/conserva `DeviceRegistry` localmente (no lo escribe el usuario).

### Cómo obtiene el código de provisioning

**EN1 BackOffice** emite un código **asociado a una Caja** (contrato EN1-02).  
La APK solo lo **consume** en el header `X-EN1-Provisioning-Code`.

### Qué hace después del código

1. `POST …/devices/register` → `access_token` + config (org/branch/pos/register/timezone…).  
2. Persiste config + marca onboarding plataforma.  
3. `GET …/devices/bootstrap` → productos, categorías, cajeros, licencia, páginas POS.  
4. Gate ADR-014 → `readyToOperate`.  
5. PIN → caja → POS.

`GET …/devices/config` **no** está en el happy path de instalación (sí en «Este dispositivo» → refrescar).

### Llamadas HTTP

| Etapa | Método | Path |
|-------|--------|------|
| Register | `POST` | `{base}/api/v1/devices/register` |
| Bootstrap | `GET` | `{base}/api/v1/devices/bootstrap` |
| Bootstrap cajeros | `GET` | `…/bootstrap?cashiers_version=N` |
| Config (post) | `GET` | `{base}/api/v1/devices/config` |

### Si falla alguna etapa

| Etapa | UX actual |
|-------|-----------|
| Connect (código inválido / red / 401 / 409) | Banner + mensaje; reintento en el mismo form |
| Bootstrap (red / vacío / licencia) | Pantalla bloqueante + **Reintentar** / **Reaprovisionar** / Ver licencia |
| 401/403 o device revoked | Limpia token → `/platform/connect?reprovision=1` |
| PIN / caja | Mensajes locales; no reabre provisioning |

---

## 2. Pantallas existentes

| Pantalla / paso | Estado |
|-----------------|--------|
| Bienvenida Local vs EN1 | **Implementada** |
| Connect EN1 (URL + código **juntos**) | **Implementada** |
| Pantalla solo URL | **Pendiente** (no existe) |
| Pantalla solo código | **Pendiente** (no existe) |
| Registro exitoso (pantalla dedicada) | **Pendiente** (solo SnackBar) |
| Descarga bootstrap | **Implementada** |
| Selección cajero | **Implementada** (dentro de `/pin`) |
| Login PIN | **Implementada** |
| Apertura de turno | **Implementada** |
| Este dispositivo / diagnóstico | **Implementada** |
| Reaprovisionar | **Implementada** |
| Desconectar EN1 | **Implementada** |
| Restaurar instalación / backup | **Pendiente** (no existe) |
| Login EN1 usuario/password | **Pendiente** (no existe) |
| Selección org / sucursal / caja en APK | **Pendiente** (no existe; viene del código) |

---

## 3. Diseño UX actual (filosofía)

```text
Usuario abre APK
        ↓
PlatformWelcomeScreen
        ↓
ConnectEn1Screen  (URL + código Caja)
        ↓
POST register → Device Token + config
        ↓
PlatformBootstrapScreen  (bloqueante)
        ↓
PIN cajeros → Abrir turno → POS
```

**Filosofía:** la tablet es un **dispositivo de Caja**. El vínculo de seguridad es el **código one-shot de Caja** + **Device Token**. No hay identidad de usuario BO en la APK. Org/sucursal/caja las decide EN1 al emitir el código.

También existe modo **Local** (sin EN1) desde Welcome → onboarding local.

---

## 4. Propuesta UX (sin código)

### Opción A — Código manual (estado actual / contrato EN1-02)

```text
EN1 genera código → usuario lo escribe → APK register → bootstrap
```

| Ventajas | Desventajas |
|----------|-------------|
| Ya implementada y contractual | Manual, propenso a typos |
| Segura (one-shot, TTL, scoped a Caja) | Manual de instalación más largo |
| Sin login BO en tablet (menor superficie) | Requiere acceso a BO para emitir código |
| Encaja Dual Mode / Device Token | Gap onboarding local post-bootstrap |

### Opción B — Login EN1 + selección org/sucursal/caja + provisioning automático

```text
APK → login EN1 → org → sucursal → caja → EN1 emite token/código oculto → bootstrap
```

| Ventajas | Desventajas |
|----------|-------------|
| UX más “producto” / menos códigos | **No existe** en APK ni como contrato Device HTTP congelado |
| Manual más corto para el comercio | Exige nuevos endpoints BO auth + scopes en dispositivo |
| Menos error humano | Credenciales BO en POS (riesgo; rol admin en caja) |
| | Rompe/amplía EN1-02; trabajo EN1 + LOCAL |

Coincide con la propuesta “desde cero” del mensaje (welcome → login → org → branch → caja → progreso → listo).

### Opción C — Híbrida (recomendada por LOCAL sin romper lo hecho)

Mantener **mecanismo A** (código + Device Token) como SoT de seguridad, mejorar **capa UX**:

1. Welcome: **Configurar nueva caja** | **Reaprovisionar / Restaurar vínculo** (mapear a disconnect/reprovision ya existentes).  
2. Connect: wizard 2 pasos (URL guardada → código) + QR del código si EN1 lo emite.  
3. Pantalla **“Instalación en curso”** unificada (register + bootstrap con checklist visible: productos, cajeros, impuestos, config).  
4. Pantalla **“Listo → Login cajeros”** (eliminar caída a onboarding local en modo plataforma).  
5. Opcional futuro: en BO, botón “Emparejar tablet” que muestre código grande / QR (sigue siendo A).

| Ventajas | Desventajas |
|----------|-------------|
| No inventa HTTP; respeta EN1-02 | Sigue existiendo un código (aunque con QR sea casi invisible) |
| Mejora manual y UX sin reabrir contratos | Requiere fixes LOCAL (gap `isSetupComplete`, pantallas progreso) |
| Reusa re-provision / recovery ya hechos | Opción B queda como P2/EN1 si el negocio lo exige |

**Veredicto LOCAL:** para el **Manual Oficial ahora**, documentar **Opción A** (realidad). Para **diseño objetivo**, priorizar **C** (pulido sobre A). **B** solo con contrato EN1 nuevo + decisión de seguridad (credenciales BO en tablet).

La idea de “el token se genera en EN1 y queda oculto” es compatible con C vía QR/emparejamiento BO; **no** requiere login BO en la APK.

---

## 5. Restricciones técnicas

| Restricción | Impacto |
|-------------|---------|
| Contrato **EN1-02** congelado: register con `X-EN1-Provisioning-Code` | Opción B no se puede implementar solo en LOCAL |
| No hay endpoints Device de “login BO / list orgs / pick register” en el cliente | B bloqueada hasta freeze EN1 |
| ADR-014: bootstrap obligatorio antes de POS | No se puede saltar descarga |
| Device Token ≠ sesión Flask BO | Prohibido reutilizar login web en APK sin diseño nuevo |
| Gap `isSetupComplete` | UX real ≠ “PIN directo tras bootstrap” |
| Tesorería/movimientos sin contrato HTTP | Irrelevante a instalación; no bloquea provisioning |

---

## 6. No implementar

Este documento **no** autoriza cambios de código.  
Esperar aprobación explícita antes de:

- pantallas nuevas de instalación,
- login EN1 en APK,
- cambios a EN1-02,
- fix del gap onboarding post-bootstrap (aunque sea LOCAL-only).

---

## Referencias rápidas

- `ConnectEn1Screen` · `PlatformWelcomeScreen` · `PlatformBootstrapScreen`
- `En1ProvisioningRepository` · `En1BootstrapRepository` · `InstallationLifecycle`
- `Doc/EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md`
- `Doc/ADR-014-EPOSONE-INSTALLATION-PROVISIONING-BOOTSTRAP.md`
- `Doc/EPOSONE_REPROVISION_UX_V1.md`
