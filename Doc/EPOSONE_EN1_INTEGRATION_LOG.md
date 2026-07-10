# Bitácora Integración EPosOne ↔ EN1

**Metodología:** hitos · ambos lados deben funcionar para cerrar.

Leyenda: 🔴 No iniciado · 🟡 En desarrollo · 🟢 Terminado · ✅ Validado  
Integración: 🔴 No probado · 🟡 Integrando · 🟢 Funciona · ✅ QA aprobado

| Hito | EN1 | EPosOne | Integración | Notas |
|------|-----|---------|-------------|-------|
| **1 Provisioning** | 🟢 EN1-02 DEV | 🟢 Cliente **EN1-02** | 🟡 E2E 1 tablet | Contrato oficial EN1-02 |
| **2 Sync down** | 🔴 | 🔴 stub | 🔴 | Tras ✅ E2E Hito 1 |
| **3 Eventos up** | 🔴 | 🔴 stub | 🔴 | Ventas/caja/inventario |
| **4 BackOffice ops** | 🟡 | N/A (solo refleja) | 🔴 | |
| **5 QA 4 tablets** | 🔴 | 🔴 | 🔴 | Solo tras E2E 1 tablet |

## Hito 1 — EPosOne EN1-02 (10 jul 2026)

| Entrega | Estado |
|---------|--------|
| Wizard solo URL + código | 🟢 |
| Header `X-EN1-Provisioning-Code` | 🟢 |
| Body sin org/branch/pos/register refs | 🟢 |
| Parser response anidada + HTTP 201 | 🟢 |
| Persistencia schema v2 (token, org, branch, pos, register, device, config_version) | 🟢 |
| Errores `{ "error": "string" }` + UX | 🟢 |
| Reprovision: nuevo token automático | 🟢 |
| POS Core intacto | 🔒 |
| Sync | 🔴 Hito 2 |
| `flutter analyze` platform | 🟢 No issues found |

**Contrato:** [`EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md`](EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md)

## Gate actual — E2E una tablet

1. Instalar APK limpia (clear data).  
2. URL: `https://appdev.easynodeone.com`  
3. Código de provisioning de una Caja (BackOffice).  
4. Registrar → token + config → “Este dispositivo”.  
5. Reiniciar → omitir wizard → PIN.  
6. Opcional: reprovision mismo UUID → 201 + nuevo token.  
7. **No** generar APK para las otras 3 tablets hasta ✅.
