# Bitácora Integración EPosOne ↔ EN1

**Metodología:** hitos · ambos lados deben funcionar para cerrar.

Leyenda: 🔴 No iniciado · 🟡 En desarrollo · 🟢 Terminado · ✅ Validado  
Integración: 🔴 No probado · 🟡 Integrando · 🟢 Funciona · ✅ QA aprobado

| Hito | EN1 | EPosOne | Integración | Notas |
|------|-----|---------|-------------|-------|
| **1 Provisioning** | 🟡 APIs (lado CODITO) | 🟢 **Congelado** (cliente + contrato) | 🔴 | Listo para integrar cuando EN1 publique |
| **2 Sync down** | 🔴 | 🔴 stub | 🔴 | Tras validar Hito 1 |
| **3 Eventos up** | 🔴 | 🔴 stub | 🔴 | Ventas/caja/inventario |
| **4 BackOffice ops** | 🟡 | N/A (solo refleja) | 🔴 | |
| **5 QA 4 tablets** | 🔴 | 🔴 | 🔴 | Checklist único |

## Hito 1 — detalle EPosOne (jul 2026) — CERRADO / CONGELADO lado APK

| Entrega | Estado |
|---------|--------|
| Wizard Bienvenido | 🟢 |
| Pantalla Conectar EN1 | 🟢 |
| Cliente API + Repository | 🟢 |
| Contrato v0.1 completo (HTTP + errores + JSON) | 🟢 |
| Errores UX (red/timeout/servidor/código/auth) + log técnico | 🟢 |
| Persistencia `schemaVersion` + gancho migrateIfNeeded | 🟢 |
| Skip wizard si provisionado | 🟢 |
| Renovación de token | ⏸ Diferida (define EN1 primero) |
| POS Core intacto | 🔒 |
| Sync completo | 🔴 Hito 2 |

**Integración ✅:** cuando EN1 publique `register` + `config` y una tablet limpia quede registrada automáticamente.
