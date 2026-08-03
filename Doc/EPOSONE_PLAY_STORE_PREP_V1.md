# EPosOne — Preparación Google Play (Local / Prog2)

| Campo | Valor |
|-------|--------|
| **Fecha** | 2 ago 2026 |
| **Estado** | Prep técnica lista · **no publicar** hasta P0 + piloto |
| **applicationId** | `services.easytech.eposone` |
| **Upload keystore** | `eposone/android/keystore/eposone-upload.jks` (local, gitignored) |

---

## Hecho en repo (2 ago)

1. `applicationId` / `namespace` cambiados de `com.example.eposone` → `services.easytech.eposone`.
2. `MainActivity` movido al nuevo package.
3. Firma release vía `android/key.properties` + `keystore/eposone-upload.jks`.
4. Si no hay `key.properties`, release sigue firmando con debug (dev).
5. Secretos en `.gitignore` (`key.properties`, `*.jks`).
6. Plantilla: `android/key.properties.example`.

> **Importante:** al cambiar `applicationId`, en la tablet es una app **nueva** (no actualiza la anterior `com.example`). Desinstalar la vieja o conviven las dos.

---

## Backup obligatorio (tú)

Guardar fuera del PC (gestor de contraseñas / USB cifrado):

- Archivo `eposone-upload.jks`
- Contenido de `android/key.properties` (passwords + alias `upload`)

Sin eso no se pueden firmar updates de Play con la misma identidad de upload key.

---

## Builds

```bash
cd eposone
flutter build apk --release
flutter build appbundle --release
```

| Artefacto | Ruta |
|-----------|------|
| APK firmado | `build/app/outputs/flutter-apk/app-release.apk` |
| AAB (Play) | `build/app/outputs/bundle/release/app-release.aab` |

> En algunos entornos Flutter avisa `failed to strip debug symbols` al generar AAB; el `.aab` puede generarse igual. Si Play rechaza el bundle, instalar NDK vía Android SDK y regenerar.

**storeFile en key.properties:** ruta relativa al módulo `android/app/` → `../keystore/eposone-upload.jks`

---

## Pendiente ETS / operación (no Local solo)

| Ítem | Quién |
|------|--------|
| Cuenta Play Developer + $25 + ID verify | ETS |
| Play App Signing (recomendada) | ETS en Play Console |
| Ficha (textos, icono 512, capturas) | ETS / Marketing |
| Política de privacidad + términos en `eposone.easytech.services` | ETS / web |
| Data Safety form | ETS |
| Internal / Closed testing | ETS |
| Publicar producción | **Después** P0 certificado + piloto Mexican Food |

---

## Orden recomendado (Ana + Roadmap Maestro)

1. Cerrar P0 E2E (caja, sync offline, cajeros, pedidos, reportes, licencia).
2. Piloto primer cliente.
3. Internal testing Play.
4. Producción 1.0.0.

---

*EasyTech · Prog2 · 2 ago 2026*
