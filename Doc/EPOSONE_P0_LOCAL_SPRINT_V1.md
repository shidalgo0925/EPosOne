# EPOSOne (LOCAL) — Sprint P0 · Instrucciones Ana

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **Actor** | LOCAL (EP1) · repo EPosOne |
| **IDs** | P0.19 … P0.30 |
| **Regla** | Consumir contratos EN1. No inventar arquitectura comercial ni HTTP nuevo. |

---

## Estado de partida (EN1 ya entregó)

Portal de Instalación · Login / Session / Issue Code · Distribución APK · Docs P0 · Contratos Gate 1 · APK pública:

`https://eposone.easytech.services/static/apk/eposone/EPosOne.apk`

LOCAL **no** modifica: planes, precios, orgs, suscripciones, overrides, licencias comerciales, Portal EN1, auth de usuarios.

---

## Backlog LOCAL

| ID | Tema | Estado LOCAL | Bloqueo |
|----|------|--------------|---------|
| **P0.19** | Reaprovisionamiento (consumidor) | Parcial (Gate 2 restore compuesto) | EN1 P0.17 freeze completo |
| **P0.20** | Deep Link desde EN1 | En curso (Gate1: `eposone://provision?code=`) | — |
| **P0.21** | Bootstrap con progreso (checklist) | En curso | — |
| **P0.22** | Recuperación errores Bootstrap | En curso | — |
| **P0.23** | Register OK + Bootstrap falla → no re-register | ✅ | — |
| **P0.24** | Offline durante Bootstrap | Parcial → auto-reintento | — |
| **P0.25** | Bootstrap → PIN → Abrir Caja | Parcial | — |
| **P0.26** | Validación licencias antes de caja | ✅ | — |
| **P0.27** | Mensajes códigos expirado/usado/revocado | En curso | códigos estables EN1 |
| **P0.28** | Sin mensajes técnicos al usuario | En curso | — |
| **P0.29** | “EPOSOne está listo” | En curso | — |
| **P0.30** | Certificación E2E | Checklist doc | PRD + P0.17 |

---

## Flujos (normativos)

### Reaprovisionamiento (P0.19)

```text
Login → Org → Dispositivo → Nuevo Provision Code
  → Register → Bootstrap → PIN → Operar
```

LOCAL no decide: quién puede, expiración, auditoría, revocación (= EN1).

### Gate de aceptación

```text
Portal EN1 → Register → Bootstrap → PIN → Abrir Caja → Primera Venta
```

+ recuperación de dispositivo vía contrato EN1, sin reglas de negocio propias.

---

## Entregables

1. Consumo del contrato de reaprovisionamiento (cuando EN1 congele P0.17).  
2. Deep Link → Register.  
3. Bootstrap con progreso checklist.  
4. Recuperación errores / offline / sin re-register.  
5. Mensajes amigables.  
6. Validación E2E + certificación P0.

---

## Referencias

- Maestro: [`EPOSONE_P0_ONBOARDING_CONTEXT_EN1_LOCAL_V1.md`](EPOSONE_P0_ONBOARDING_CONTEXT_EN1_LOCAL_V1.md)  
- E2E: [`EPOSONE_P0_ONBOARDING_E2E_CERT_CHECKLIST_V1.md`](EPOSONE_P0_ONBOARDING_E2E_CERT_CHECKLIST_V1.md)  
- Freeze: [`EN1_ONBOARDING_P0/GATE1_HTTP_FROZEN_FOR_LOCAL.md`](EN1_ONBOARDING_P0/GATE1_HTTP_FROZEN_FOR_LOCAL.md)  
- QR / deep link: [`EN1_ONBOARDING_P0/QR_CONTRACT_V1.md`](EN1_ONBOARDING_P0/QR_CONTRACT_V1.md)  
