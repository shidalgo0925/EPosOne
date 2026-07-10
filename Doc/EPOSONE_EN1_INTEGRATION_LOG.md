# Bitácora Integración EPosOne ↔ EN1

**Metodología:** hitos · ambos lados deben funcionar para cerrar.

Leyenda: 🔴 No iniciado · 🟡 En desarrollo · 🟢 Terminado · ✅ Validado  
Integración: 🔴 No probado · 🟡 Integrando · 🟢 Funciona · ✅ QA aprobado

| Hito | EN1 | EPosOne | Integración | Notas |
|------|-----|---------|-------------|-------|
| **1 Provisioning** | 🟡 APIs (lado CODITO) | 🟢 Cliente listo (contrato v0.1) | 🔴 | APK: wizard + register + token/IDs + estado |
| **2 Sync down** | 🔴 | 🔴 stub | 🔴 | Tras validar Hito 1 |
| **3 Eventos up** | 🔴 | 🔴 stub | 🔴 | Ventas/caja/inventario |
| **4 BackOffice ops** | 🟡 | N/A (solo refleja) | 🔴 | |
| **5 QA 4 tablets** | 🔴 | 🔴 | 🔴 | Checklist único |

## Hito 1 — detalle EPosOne (jul 2026)

| Entrega | Estado |
|---------|--------|
| Wizard Bienvenido | 🟢 |
| Pantalla Conectar EN1 | 🟢 |
| `En1ProvisioningApi` + Repository | 🟢 |
| Persistencia token + jerarquía | 🟢 |
| Estados UI conexión | 🟢 |
| Skip wizard si provisionado | 🟢 |
| Contrato documentado | 🟢 `Doc/EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT.md` |
| POS Core intacto | 🔒 |
| Sync completo | 🔴 diferido Hito 2 |

**Pendiente para ✅ Validado:** EN1 endpoints live + prueba tablet limpia.
