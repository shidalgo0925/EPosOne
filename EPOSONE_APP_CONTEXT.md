# EPosOne — Contexto de la App (Julio 2026)

**Documento vivo** · Fuente de verdad de producto para desarrollo  
**Última actualización:** 13 de julio de 2026  
**Repo:** `EPosOne` · App Flutter: `eposone/` · Rama: `master` = `origin/master`

---

## Dónde quedamos (snapshot)

| Ítem | Estado |
|------|--------|
| **Hito 1 Provisioning EN1-02** | ✅ **CERRADO** · tag **`provisioning-v1.0`** |
| **Hito 2 Device Bootstrap** | 🟡 **GO ABIERTO** — contrato + cliente pull en curso |
| **Contrato Hito 2** | [`Doc/EPOSONE_EN1_HITO2_DEVICE_BOOTSTRAP_CONTRACT.md`](Doc/EPOSONE_EN1_HITO2_DEVICE_BOOTSTRAP_CONTRACT.md) |
| **Cliente Provisioning** | 🔒 Congelado |
| **POS Core** | 🔒 Congelado |
| **Catálogo** | Istmo local hasta Bootstrap; luego EN1 |

**Siguiente acción:** Reinstalar APK → **Descargar catálogo EN1** → debe llamar `GET /api/v1/devices/bootstrap` (Device Token). No usar `/api/eposone/products`.

---

## 1. Qué es EPosOne

EPosOne es un **producto independiente** (aplicación de punto de venta) dentro del ecosistema **EasyNodeOne Platform**.

| Rol | Qué es |
|-----|--------|
| **EasyNodeOne (EN1)** | Plataforma (autenticación, Launcher, back-office, sync, FE, CRM…) |
| **EPosOne** | Aplicación POS — operación diaria del cajero |

**No es un módulo del ERP.** El usuario entra a EN1 solo para autenticarse o al Launcher; después trabaja **completamente dentro de EPosOne**.

```
Login → EasyNodeOne Platform → Launcher → EPosOne → Operación diaria
```

Mientras está en EPosOne, **no debe sentirse dentro del ERP**.

---

## 2. Objetivo comercial

Competir con Loyverse, Square POS, Poster POS, Shopify POS.

**Diferencia:** cuando el cliente crece, activa EasyNodeOne **sin cambiar de aplicación**, sin reinstalar y sin perder datos.

---

## 3. Arquitectura congelada (inalterable)

### 3.1 Una sola APK

No existen builds distintos (Lite / Cloud / EN1).  
**Un producto.** Tres **modos** de operación:

| Modo | Descripción |
|------|-------------|
| **Local** | App sola; datos en el dispositivo |
| **Plataforma** | Conectada a EN1 (fuente de verdad) |
| **Vincular EN1** | Negocio que empezó Local y luego conecta EN1 (cambia backend, no producto) |

### 3.2 Un solo dominio

Mismas entidades Local y Plataforma. El dominio **no conoce** SQLite, APIs ni EN1 — solo el negocio.

Repositorios intercambiables, p. ej. `ProductoRepository` → `SQLite…` | `EN1…`.

### 3.3 Jerarquía oficial

```
Tenant → Empresa → Sucursal → Punto de Venta (POS) → Caja → Dispositivo
```

- **POS** = unidad de operación y **futura** unidad de licenciamiento  
- **Dispositivo** = recurso del POS (UUID para auditoría/idempotencia); **no** consume licencia  
- Identidad operativa antes de vender: Empresa → Sucursal → POS → Caja (+ Turno en operación)

### 3.4 EN1 = cerebro · EPosOne = nodo

- Los POS **nunca** hablan entre sí (sin P2P)  
- Sync por **eventos** (no tablas)  
- Nunca bloquear una venta por falta de internet  

---

## 4. POS Core Protegido 🔒

**Decisión (jul 2026):** el flujo del cajero es **Core Protegido**.

### No tocar (salvo bugs / mejoras puntuales)

Ventas · Abrir caja · Cobrar · Tickets · Reembolsos · Productos · Clientes · Inventario básico · Impresión · Bluetooth · UX del cajero

**Si hoy puede vender, mañana debe vender exactamente igual.**

### Extender (alrededor del Core)

```
EPosOne
├── POS Core          ← 🔒 no modificar salvo errores
├── Inventario / Caja / Impresión / Pagos / Bluetooth
└── Plataforma        ← módulos nuevos
    ├── Onboarding
    ├── Device Manager
    ├── Sync / Device Bootstrap
    ├── EN1 Connector
    ├── Provisioning          ← 🔒 cerrado Hito 1
    └── LicensePolicy (stub)
```

Evolución = **extensión**, no reemplazo del núcleo.

---

## 5. Estado actual de la app

### 5.1 POS Core (estable)

| Área | Estado |
|------|--------|
| Roadmap V2 L1–L10 | ✅ Cerrado |
| Paridad Loyverse (cajero) | ~96% |
| Catálogo Istmo piloto | ✅ ~110 productos (local hasta Hito 2) |
| Imágenes ItsBrew | ✅ embebidas; sin pull EN1 |
| APK piloto | `eposone/epos1.apk` (local) |

### 5.2 Hito 1 Provisioning ✅ CERRADO

Tag `provisioning-v1.0`. Ver handoff de cierre.

### 5.3 Hito 2 Device Bootstrap ⏸

Pull: config · catálogo · precios · uom/pack/min/max · imágenes · saldos.  
Sin ventas→stock. Contrato EN1 primero.

### 5.4 Stubs / no ahora

FE · CRM · IA · licencias · transferencias · multi-tablet.

---

## 6. Qué NO hacer ahora

- Reabrir cliente provisioning (salvo bug reinicio documentado)  
- Empezar Hito 2 sin contrato congelado EN1  
- Borrar Istmo local antes del E2E Bootstrap  
- FE / CRM / IA / sync ventas→stock  

---

## 7. Objetivo de experiencia

Una persona descarga EPosOne y en **&lt; 5 minutos** debe poder:

1. Crear negocio **o** conectar EN1  
2. Registrar el dispositivo  
3. (Hito 2) Descargar catálogo EN1  
4. Abrir caja y vender  

---

## 8. Archivos clave

| Área | Ruta |
|------|------|
| Plataforma | `eposone/lib/src/features/platform/` |
| POS Core | `eposone/lib/src/features/pos/` 🔒 |
| Cierre Hito 1 | `Doc/EPOSONE_HITO1_PROVISIONING_HANDOFF_CLOSED.md` |
| Contrato EN1-02 | `Doc/EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT_EN1-02.md` |
| Bitácora | `Doc/EPOSONE_EN1_INTEGRATION_LOG.md` |
| Roadmap | `EPOSONE_MASTER_PLAN_V3.md` (v3.4) |

---

## 9. Principios inalterables

1. EPosOne independiente · EN1 plataforma  
2. Una sola APK · un dominio  
3. POS = operación (y futura licencia) · dispositivo = recurso  
4. UX cajero &gt; infra · Core Protegido  
5. Nunca bloquear venta por red · sin P2P entre POS  
6. **Un hito · un contrato · un cierre · un GO**

---

## 10. Siguiente paso

1. EN1: checklist freeze contrato Hito 2 (token device → products/stock + curl org 5)  
2. Tablet: Este dispositivo → **Descargar catálogo EN1** → verificar ventas con `ib-*`  
3. E2E Bootstrap → retirar Istmo como fuente activa (assets se quedan hasta decisión)  

---

*EasyTech Services · EPosOne · Contexto 13 jul 2026 · Hito 2 GO abierto*
