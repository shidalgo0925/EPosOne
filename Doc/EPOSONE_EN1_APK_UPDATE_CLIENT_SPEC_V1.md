# EPosOne — Spec cliente APK Update desde EN1 (V1)

| Campo | Valor |
|-------|--------|
| **Estado** | **Borrador** · bloqueado hasta freeze del delta EN1 |
| **Fecha** | 5 ago 2026 |
| **Contrato pendiente** | [`EPOSONE_EN1_APK_UPDATE_CONTRACT_DELTA_REQUEST.md`](EPOSONE_EN1_APK_UPDATE_CONTRACT_DELTA_REQUEST.md) |
| **ADR** | [`ADR-014`](ADR-014-EPOSONE-INSTALLATION-PROVISIONING-BOOTSTRAP.md) |
| **Regla** | **No implementar código** hasta handoff P1 congelado |

---

## 1. Objetivo Local

Tras freeze EN1, la APK debe:

1. Consultar metadata de actualización con Device Token.  
2. Comparar `version_code` local vs `latest` / `min`.  
3. Descargar artefacto, verificar `sha256`.  
4. Invocar instalador Android.  
5. Aplicar gate: bajo mínimo o `force_update` → no operar POS (modo integrado).

---

## 2. Módulos previstos (futuros)

| Módulo | Responsabilidad |
|--------|-----------------|
| `En1AppUpdateApi` | GET metadata (+ artifact si aplica) |
| `AppUpdateRepository` | Persist last check · policy cache |
| `AppUpdateDownloader` | HTTPS download a archivo privado app |
| `ApkIntegrity` | sha256 |
| `ApkInstaller` | PackageInstaller / Intent install |
| `AppUpdateGate` | Integra `InstallationLifecycle` (ADR-014) |
| UI | Este dispositivo · pantalla bloqueo force |

No inventar paths HTTP distintos al contrato congelado.

---

## 3. Reglas de negocio Local

| Condición | Efecto |
|-----------|--------|
| Sin Device Token (Standalone) | Canal EN1 no aplica |
| `local >= latest` y no force | Nada |
| `recommend_update` | Aviso no bloqueante |
| `local < min_version_code` | Bloqueo integrado |
| `force_update == true` | Bloqueo hasta instalar latest |
| Hash mismatch | Abortar install · error usuario · no bypass |
| Fallo red en soft update | Reintentar después; no tumbar POS |
| Fallo red con force/min | Mantener bloqueo · CTA reintentar |

Offline First (ADR-007): **no** exige internet para vender **después** de READY; el **force/min update** es excepción de plataforma (igual que primer bootstrap).

---

## 4. Relación con aprovisionamiento

```text
Register → Token → Bootstrap → [App-update check] → READY_TO_OPERATE
```

El check de versión es **posterior o paralelo** al bootstrap de catálogo; no sustituye provisioning.

Reaprovisionamiento / revocación / config auto siguen siendo tracks **separados** (inventario 5 ago); este spec solo cubre **OTA APK**.

---

## 5. Criterio de aceptación (post-GO código)

- [ ] Contrato EN1 copiado en `Doc/` con commit/tag  
- [ ] Descarga + sha256 + install en tablet de prueba  
- [ ] Gate min/force verificado  
- [ ] Register reporta nueva `app_version` tras update  

---

## 6. Explicitamente fuera

- Implementación ahora.  
- Play Store updates.  
- iOS.  
- Auto-install sin confirmación del usuario (salvo política futura Producto + restricciones Android).
