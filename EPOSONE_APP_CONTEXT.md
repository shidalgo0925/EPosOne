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

### 5.3 Hito 2 Device Bootstrap ✅

Cerrado · congelado. Ver Roadmap V5.

### 5.4 Hito 3–7 (Roadmap V5)

Fuente: [`Doc/EPOSONE_EN1_ROADMAP_V5.md`](Doc/EPOSONE_EN1_ROADMAP_V5.md)  
GO P2: [`Doc/EPOSONE_EN1_HITO3B_ORDER_OPERATION_GO.md`](Doc/EPOSONE_EN1_HITO3B_ORDER_OPERATION_GO.md)

| Hito | Estado |
|------|--------|
| 3 Order Domain EN1 | ✅ Contrato HTTP congelado |
| **3B Operación Pedido (P2)** | 🟢 **GO** |
| 3.5 Validación operativa | ⏸ |
| 5–7 Inventario / Caja / FE | ⏸ |

### 5.5 Stubs / no ahora

Inventario · FE · KDS · CxC · ampliar contrato Orders · P1 features nuevas (solo soporte).

---

## 6. Qué NO hacer ahora

- Reabrir Provisioning / Bootstrap / modificar contrato Orders  
- Inventario / FE / caja avanzada en 3B  
- Pedir cambios a EN1 salvo bug (P1 soporte)  

---

## 7. Objetivo de experiencia

Una persona descarga EPosOne y en **&lt; 5 minutos** debe poder:

1. Crear negocio **o** conectar EN1  
2. Registrar el dispositivo  
3. Descargar catálogo EN1  
4. Abrir caja y vender  

---

## 8. Archivos clave

| Área | Ruta |
|------|------|
| Roadmap V5 | `Doc/EPOSONE_EN1_ROADMAP_V5.md` |
| GO Hito 3B P2 | `Doc/EPOSONE_EN1_HITO3B_ORDER_OPERATION_GO.md` |
| Contrato Orders (EN1) | `docs/EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md` *(repo EN1)* |
| Bitácora | `Doc/EPOSONE_EN1_INTEGRATION_LOG.md` |

---

## 9. Principios inalterables

1. EPosOne independiente · EN1 plataforma  
2. Una sola APK · Pedido = corazón  
3. Eventos · Ownership · inventario oficial EN1  
4. Core Protegido · offline-first  
5. **Un hito · un contrato · un cierre · un GO**  

---

## 10. Siguiente paso

1. **P2:** Hito 3B — Pedido offline + sync `/api/v1/orders*`  
2. E2E con P1 (soporte)  
3. Hito 3.5 validación → luego Inventario  

---

*EasyTech · Contexto 14 jul 2026 · Hito 3B GO*
