# Solicitud de delta de contrato — Descarga / actualización APK desde EN1

| Campo | Valor |
|-------|--------|
| **Fecha** | 5 ago 2026 |
| **De** | P2 / Local (EPosOne APK) |
| **Para** | P1 / CODITO (EN1) |
| **Motivo** | Habilitar que el dispositivo **descargue e instale** la APK oficial desde EN1 (canal comercial / OTA controlado) |
| **Estado** | **BORRADOR · pendiente congelar en EN1** |
| **Relacionado** | [`ADR-014`](ADR-014-EPOSONE-INSTALLATION-PROVISIONING-BOOTSTRAP.md) (gate versión mínima) · [`ADR-007`](ADR-007-EPOSONE-COMMERCIAL-LICENSING.md) §2.4 distribución pública · Provisioning EN1-02 · Bootstrap Hito 2 |

> **P2 no implementa cliente OTA hasta que este delta (o equivalente) sea oficial y congelado.**  
> Hoy en APK: **no existe** descarga ni instalación desde EN1.

---

## 1. Objetivo

| Actor | Responsabilidad |
|-------|-----------------|
| **EN1** | Publica artefactos APK versionados · metadata · URL firmada · política min/latest |
| **EP1 (APK)** | Detecta · descarga · verifica integridad · solicita instalación Android · reporta versión en register/bootstrap |

**Una sola APK** (Standalone + Integrado). El canal EN1 no bifurca el binario.

Fuera de este delta:

- Distribución Play Store (paralela / opcional).  
- Firmas de upload key de Play ([`EPOSONE_PLAY_STORE_PREP_V1.md`](EPOSONE_PLAY_STORE_PREP_V1.md)).  
- Cambios a Order / Cash Shift / Sync de ventas.

---

## 2. Problema actual

1. Ops / ventas suelen instalar APK **manualmente** (USB / archivo).  
2. No hay forma contractual de que un dispositivo provisionado **pida la versión oficial** a EN1.  
3. ADR-014 prevé *“Validar versión mínima APK (si el contrato lo define)”* — **el contrato aún no lo define**.  
4. Inventario Local (5 ago): *Descarga e instalación desde EN1* = ❌.

---

## 3. Propuesta de superficie HTTP (a congelar por P1)

Nombres tentativos. **P1 puede renombrar**; P2 se alinea al handoff congelado.

### 3.1 Metadata de actualización (preferido)

`GET /api/v1/devices/app-update`  
Auth: `Authorization: Bearer <device_token>` (mismo Device Token EN1-02).

**Response 200 (ejemplo):**

```json
{
  "platform": "android",
  "package_name": "com.eposone.app",
  "latest": {
    "version_name": "1.2.0",
    "version_code": 120,
    "min_sdk": 24,
    "released_at": "2026-08-05T18:00:00Z",
    "release_notes": "Bootstrap gate · OCC · …",
    "artifact": {
      "url": "https://…/eposone-1.2.0.apk",
      "size_bytes": 98000000,
      "sha256": "…",
      "content_type": "application/vnd.android.package-archive"
    }
  },
  "policy": {
    "min_version_code": 110,
    "force_update": false,
    "recommend_update": true
  }
}
```

| Campo | Uso APK |
|-------|---------|
| `latest.version_code` | Comparar con `PackageInfo.buildNumber` / versionCode |
| `latest.artifact.url` | Descarga (HTTPS) |
| `latest.artifact.sha256` | Verificar antes de instalar |
| `policy.min_version_code` | Gate duro (ADR-014) si `local < min` |
| `policy.force_update` | Bloquear POS hasta actualizar (integrado) |
| `policy.recommend_update` | Banner / “Este dispositivo” sin bloquear |

**Errores esperados:**

| HTTP | Semántica APK |
|------|----------------|
| 401 / 403 | Token inválido → mensaje reprovision (sin wipe automático en V1) |
| 404 | Canal update no publicado → no bloquear si no hay min forzada |
| 503 | Reintentar |

### 3.2 Alternativa A — embebido en config / bootstrap

Si P1 prefiere no crear endpoint nuevo, documentar en:

- `GET /api/v1/devices/config`, y/o  
- `GET /api/v1/devices/bootstrap` → bloque `app_update` **mismo shape** que §3.1.

P2 acepta **una** fuente canónica (endpoint dedicado **o** bloque bootstrap/config — no dos SoT contradictorios).

### 3.3 Descarga del artefacto

Opciones (P1 elige una y congela):

| Opción | Descripción |
|--------|-------------|
| **A** | `url` absoluta HTTPS pública o firmada (SAS / signed URL con TTL) |
| **B** | `GET /api/v1/devices/app-update/artifact` con Bearer + stream APK |

Requisito: la APK **no** embebe credenciales de almacenamiento; usa token de dispositivo o URL firmada de corto TTL.

---

## 4. Semántica de versiones

| Concepto | Regla |
|----------|--------|
| Identidad | `version_code` (int) es la comparación canónica |
| Display | `version_name` solo UI |
| Register | EP1 ya envía `app_version` en EN1-02 — mantener; ideal incluir `version_code` en **delta register** (opcional) |
| Min gate | Si `local_version_code < policy.min_version_code` → **no** `READY_TO_OPERATE` (modo integrado) hasta actualizar |
| Soft | `recommend_update` sin bloquear venta |

Delta register opcional (misma línea que TZ delta):

```json
{
  "app_version": "1.2.0+120",
  "version_code": 120
}
```

---

## 5. Flujo objetivo (cliente EP1 — post-freeze)

```text
Provisionado + Device Token
      ↓
GET app-update (o bloque bootstrap/config)
      ↓
Comparar version_code
      ↓
┌─ local >= latest y no force ──► operar
├─ recommend ──► avisar (Este dispositivo / OCC)
└─ force o local < min ──► bloquear POS (integrado)
      ↓
Descargar APK → verificar sha256
      ↓
Intent / PackageInstaller (Android)
      ↓
Usuario confirma instalación SO
      ↓
Reinicio app → register/bootstrap reportan nueva versión
```

**Standalone:** update EN1 es opcional (sin Device Token no hay canal); distribución puede seguir siendo archivo/Play.

---

## 6. Seguridad / integridad (mínimo a congelar)

1. HTTPS obligatorio.  
2. `sha256` obligatorio en metadata.  
3. Package name debe coincidir con el de la app instalada.  
4. Firma del APK: misma signing key de release (si cambia → fail closed + mensaje).  
5. No ejecutar APK sin verificación hash.  
6. No loguear Device Token ni URL firmada completa en telemetría.

---

## 7. UX Local (post-contrato — no implementar ahora)

| Superficie | Comportamiento |
|------------|----------------|
| Este dispositivo | “Buscar actualización” · versión local vs latest |
| Gate bootstrap / lifecycle | Si `force_update` / bajo min → pantalla bloqueo con CTA Descargar |
| OCC / telemetría | Señal `app_update_available` (futuro tool EasyAI) |

Sin bypass de producto en modo integrado cuando `force_update` o bajo `min_version_code`.

---

## 8. Criterio de cierre P1 (handoff)

P1 entrega a `Doc/` de EPosOne:

1. Contrato HTTP **congelado** (path final + schemas).  
2. Ejemplos request/response.  
3. Política: dónde vive `min_version_code` / `force_update`.  
4. Cómo se publica el artefacto (quién sube APK a EN1).  
5. Changelog + commit/tag de referencia.

Sin ese paquete, **P2 no implementa** el cliente de descarga/instalación.

---

## 9. Criterio de cierre P2 (después del freeze)

- [ ] Cliente metadata + download + sha256  
- [ ] Instalación Android (permiso `REQUEST_INSTALL_PACKAGES` / sesión PackageInstaller)  
- [ ] Gate ADR-014 con `min_version_code`  
- [ ] UI Este dispositivo + bloqueo force  
- [ ] Tests de comparación de versión / rechazo hash  
- [ ] E2E Ops: publicar APK en EN1 → tablet actualiza  

---

## 10. Decisiones que P1 debe confirmar

| # | Pregunta | Impacto |
|---|----------|---------|
| 1 | ¿Endpoint dedicado o bloque en bootstrap/config? | Una SoT |
| 2 | ¿URL firmada vs stream autenticado? | Cliente download |
| 3 | ¿`force_update` lo define BO por org/caja o global? | Gate POS |
| 4 | ¿Mismo artefacto para Trial y pago? | Canal comercial |
| 5 | ¿Soporte solo Android en V1? | iOS fuera |

---

## 11. Inventario Local (contexto)

| Pieza | Estado APK hoy |
|-------|----------------|
| Register / token / bootstrap / bloqueo | ✅ |
| Metadata app-update EN1 | ❌ |
| Descarga APK | ❌ |
| Instalación desde EN1 | ❌ |
| Gate min version desde contrato | ❌ (ADR-014 diferido a este delta) |

Spec cliente Local (borrador, sin código): [`EPOSONE_EN1_APK_UPDATE_CLIENT_SPEC_V1.md`](EPOSONE_EN1_APK_UPDATE_CLIENT_SPEC_V1.md).
