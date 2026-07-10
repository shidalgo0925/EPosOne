# EPosOne — Contexto de la App (Julio 2026)

**Documento vivo** · Fuente de verdad de producto para desarrollo  
**Última actualización:** 9 de julio de 2026  
**Repo:** `EPosOne` · App Flutter: `eposone/`  
**Último commit remoto relevante:** `db1433a` (catálogo Istmo) · capa Plataforma pendiente de commit

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
    ├── Sync
    ├── EN1 Connector
    ├── Provisioning
    └── LicensePolicy (stub; reglas en EN1, no en APK)
```

Evolución = **extensión**, no reemplazo del núcleo.

---

## 5. Estado actual de la app

### 5.1 POS Core (estable)

| Área | Estado |
|------|--------|
| Roadmap V2 L1–L10 | ✅ Cerrado |
| Paridad Loyverse (cajero) | ~96% |
| Catálogo Istmo piloto | ✅ ~110 productos, 11 categorías, Comida/Bar |
| Imágenes ItsBrew | ✅ 73 assets; 110/110 con imagen |
| Chips categoría en ventas | ✅ |
| QA fixes tickets / categorías | ✅ |
| APK piloto | `eposone/epos1.apk` (local, no en git) |

### 5.2 Capa Plataforma — Hito 1 Provisioning (cliente)

Ruta: `eposone/lib/src/features/platform/`

| Módulo | Estado | Notas |
|--------|--------|-------|
| Wizard Bienvenido | ✅ | Crear negocio **o** Conectar EasyNodeOne |
| Conectar EN1 | ✅ | URL + código activación → `POST /api/v1/devices/register` |
| Cliente API provisioning | ✅ | Contrato v0.1 (`Doc/EPOSONE_EN1_HITO1_PROVISIONING_CONTRACT.md`) |
| Persistencia token + IDs | ✅ | SharedPreferences (fuera de Isar/Core) |
| Estado conexión | ✅ | No configurado / Registrando / Conectado / Error |
| Device UUID + “Este dispositivo” | ✅ | Muestra jerarquía si provisionado |
| Skip wizard si provisionado | ✅ | Arranque → onboarding o PIN |
| Sync catálogo/ventas | 🔶 Stub | **Hito 2** — no implementar aún |
| POS Core | 🔒 | Sin cambios |

**Flujo Hito 1 (instalación limpia + EN1):**

```
Splash → Welcome → Conectar EN1 → Registrar → Guardar token/IDs
      → Onboarding cajero (si falta) → PIN → Caja → Vender
```

**Cierre Hito 1 (integración):** cuando EN1 publique las APIs y una tablet quede registrada automáticamente.

### 5.3 Stubs / pendientes de producto

| Tema | Estado |
|------|--------|
| FE DGI | Stub PAC |
| Sync EN1 (features/sync) | Stub + cola offline |
| Premium (cupones/puntos) | Base |
| FE / CRM / IA / planes comerciales | **No desarrollar ahora** |

---

## 6. Qué NO hacer ahora

No desarrollar (hasta cerrar flujo operativo plataforma + POS):

- Licenciamiento / planes / restricciones en APK  
- Facturación electrónica “de verdad”  
- CRM, IA, fidelización avanzada  
- Features fuera del flujo principal del POS  

**Prioridad:** wizard + registro dispositivo + sync fino Empresa→Sucursal→POS, **sin tocar el Core**.

---

## 7. Objetivo de experiencia

Una persona descarga EPosOne y en **&lt; 5 minutos** debe poder:

1. Crear negocio **o** conectar EN1  
2. Registrar el dispositivo  
3. Configurar su Punto de Venta  
4. Abrir caja  
5. Empezar a vender  

Cuando crezca → activa EasyNodeOne sin reinstalar ni perder datos.

---

## 8. Archivos clave (orientación)

| Área | Ruta |
|------|------|
| Arranque | `lib/src/core/startup/app_startup.dart` |
| Router | `lib/src/core/router/app_router.dart` |
| **Plataforma** | `lib/src/features/platform/` |
| POS Core (no tocar) | `lib/src/features/pos/` |
| Seed Istmo | `lib/src/core/database/istmo_*.dart` |
| Roadmap | `EPOSONE_MASTER_PLAN_V3.md` |
| Este contexto | `EPOSONE_APP_CONTEXT.md` |

---

## 9. Principios inalterables (checklist)

1. EPosOne es producto independiente, no módulo del ERP.  
2. EasyNodeOne es plataforma, no app de punto de venta.  
3. Una sola APK para todos los escenarios.  
4. Un solo modelo de dominio.  
5. El POS es unidad de operación (y futura licencia).  
6. Los dispositivos son recursos del POS.  
7. UX del cajero &gt; infraestructura.  
8. **POS Core Protegido** — evolución por extensión.  
9. Nunca bloquear una venta por falta de red.  
10. POS no habla con otros POS.

---

## 10. Siguiente paso técnico

1. **Hito 1 integración:** EN1 publica APIs de registro/config; probar tablet limpia punta a punta  
2. Commit capa `platform/` + contrato + contexto  
3. **Hito 2:** sync fino (productos/clientes) — solo después de validar Hito 1  
4. Nuevo `epos1.apk` cuando haga falta probar en las 4 tablets  

---

*EasyTech Services · EPosOne · Contexto de app jul 2026*
