# EPosOne ↔ EN1 — Contrato Hito 2.5 · Cajeros + Turno (v1.0)

**Fecha:** 18 de julio de 2026  
**Estado:** ✅ **OFICIAL (Dev)** — P1 implementó EN1; Prog2 cablea APK  
**Consumidor:** EPosOne APK (login cajero · cabecera Caja·Cajero·Turno · ops)  
**Productor:** EN1 API Dev (`https://appdev.easynodeone.com`)  
**Prerequisito:** Hito 1 Provisioning · Hito 2 Bootstrap · Cajeros BO (`cashier_contact_id`)  
**Org demo:** Itsmo Brew = **org 5**

> **Nota:** commit/tag P1 aún pendiente; contrato funcional validado en Dev (PIN PBKDF2, bootstrap cashiers, sync cashier_contact_id).

> **Objetivo:** identificación del cajero en POS online/offline con `cashier_contact_id` en toda operación.  
> **No incluye:** endpoints especiales solo para cajeros · PIN en texto plano en sync · login de usuario EN1.

---

## 1. Política PIN (congelada)

| Pieza | Regla |
|-------|-------|
| EN1 | Almacena **hash + sal**. Algoritmo permitido: **PBKDF2-HMAC-SHA256** (mín. 100 000 iter) o **Argon2id**. |
| Bootstrap / sync | Entrega `pin_verifier` **opaco**. **Nunca** el PIN en claro. |
| APK | Guarda el verificador cifrado con **Android Keystore**. |
| Login | Validación **local**. Límite de intentos + bloqueo temporal. |
| Rotación | `pin_version` / `updated_at` (o `pin_updated_at`). |
| Set/change PIN | Solo BO → EN1 por **HTTPS**. El catálogo sync **no** lleva secreto reversible. |

### Formato `pin_verifier` (obligatorio)

Cadena opaca, única para el cliente:

```text
pbkdf2_sha256$<iterations>$<salt_b64>$<hash_b64>
```

Ejemplo (ilustrativo, no usar en prod):

```text
pbkdf2_sha256$100000$YWJjZGVmZ2hpams$dGhpc2lzbm90YXJlYWxoYXNo
```

- Si el algoritmo cambia, nuevo prefijo (`argon2id$…`).  
- APK: parsear prefijo; si desconocido → forzar re-sync / bloquear login con mensaje claro.

---

## 2. Flujo operativo (congelado)

```
Dispositivo ya vinculado a Caja (Hito 1)
  → Bootstrap/sync (cashiers + cashiers_version)
  → Seleccionar cajero (is_active = true)
  → Validar PIN local
  → Abrir o continuar turno
  → Operar (toda op lleva cashier_contact_id)
  → Cerrar turno
  → Sync eventos con cashier_contact_id
```

- **No** seleccionar Caja en POS: ya fijada por provisioning.  
- BO: excepción, cambio de cajero, cierre de emergencia, auditoría.  
- Apertura normal del turno: **desde el POS**.

---

## 3. Snapshot de cajeros (bootstrap / sync)

### 3.1 Extensión de `GET /api/v1/devices/bootstrap`

Mismo endpoint Hito 2. Añadir bloque:

```json
{
  "cashiers_version": 1721347200,
  "cashiers": [
    {
      "cashier_contact_id": 42,
      "cashier_name": "Juan Pérez",
      "cashier_code": "CJR-0042",
      "is_active": true,
      "pin_verifier": "pbkdf2_sha256$100000$…$…",
      "pin_version": 3,
      "updated_at": "2026-07-18T20:00:00Z"
    }
  ]
}
```

| Campo | Tipo | Notas |
|-------|------|-------|
| `cashiers_version` | int (epoch) | `max(updated_at)` de cajeros de la **org** (mismo patrón que `catalog_version` si existe). |
| `cashier_contact_id` | int | Única identidad. **No** `cashier_user_id`. |
| `cashier_name` | string | Display |
| `cashier_code` | string | `CJR-####` |
| `is_active` | bool | Login solo si `true` |
| `pin_verifier` | string | Ver §1 |
| `pin_version` | int | Incrementa en cada cambio de PIN |
| `updated_at` | ISO-8601 UTC | |

### 3.2 Sync incremental

- Request de sync/bootstrap puede enviar `cashiers_version` conocido (query o body según patrón actual de catálogo).  
- Si versión del servidor **igual** → **no** reenviar lista (omitir `cashiers` o `cashiers: []` + misma version).  
- Sync incluye **activos e inactivos** (`is_active: false`) para revocar/ocultar localmente.

### 3.3 Alcance catálogo (v1)

Cajeros de la **organización** del dispositivo. La Caja ya está fijada por el Device Token.

---

## 4. Turno y operaciones — `cashier_contact_id`

### 4.1 Apertura / continuación de turno (desde POS)

Payload mínimo (shape a alinear con endpoints de cash shift existentes en Dev):

```json
{
  "cashier_contact_id": 42,
  "cashier_name": "Juan Pérez",
  "opened_at": "2026-07-18T12:00:00Z",
  "opening_float": 100.00
}
```

Respuesta debe ecoar:

```json
{
  "shift_id": 123,
  "shift_number": "000123",
  "caja_id": "...",
  "caja_name": "Caja 1",
  "cashier_contact_id": 42,
  "cashier_name": "Juan Pérez",
  "status": "open"
}
```

### 4.2 Operaciones que **deben** llevar `cashier_contact_id`

| Operación | Quién |
|-----------|--------|
| Pedido (create / events) | Cajero autenticado en POS |
| Pago | Idem |
| Apertura / cierre de turno | Idem |
| Reembolso / cancelación | Mismo cajero + reglas supervisor BO si aplica |
| Movimiento de caja | Idem |

**Nunca** atribuir ops al usuario administrador del Back Office.

### 4.3 Order Domain (compat)

En sync de pedidos/pagos ya existentes, añadir campo:

```json
"cashier_contact_id": 42
```

Opcional v1 si el pedido anterior no lo tenía; **obligatorio** en ops nuevas tras este hito.

---

## 5. Reglas offline / conflictos

| Caso | Decisión |
|------|----------|
| Login offline | Catálogo local + PIN local. Sin EN1. |
| Cajero desactivado mientras offline | Sesión local sigue hasta cierre/sync. Al sync, EN1 rechaza **nuevas** ops si inactivo; APK fuerza re-login / bloqueo. |
| BO cambia cajero del turno | Fuente de verdad = EN1 al sync. APK adopta cajero remoto + aviso. Ops locales ya emitidas **conservan** su `cashier_contact_id` original (auditoría). |
| PIN desfasado (`pin_version`) | Re-descargar cashiers; invalidar sesión si verifier cambió. |

### Errores sugeridos (sync)

| Código / HTTP | Significado |
|---------------|-------------|
| `cashier_inactive` / 409 | Cajero inactivo; APK bloquea |
| `cashier_unknown` / 422 | ID no pertenece a la org/caja |
| `pin_stale` / 409 | (opcional) verifier desactualizado tras sync |

---

## 6. Cabecera operativa APK (UX — no HTTP)

Tras login, toda la UI POS muestra:

```text
Caja 01 · Juan Pérez · Turno #000123
```

---

## 7. Ownership del nombre de cajero (formal · 20 jul 2026)

| Modo | Dueño del nombre | Quién corrige |
|------|------------------|---------------|
| **Integrado** | **EN1** (maestro `cashier_name` en BO + bootstrap) | Nombre mal en BO → **EN1** |
| **Tablet UI** | Consume catálogo; estampa display en venta/cabecera | UUID / nombre vacío en pantalla → **Prog2** |
| **Standalone** | APK (CRUD local) | Prog2 |

Identidad canónica en ops: `cashier_contact_id` (no el nombre).

### Criterio de cierre P1 (Dev EN1)

1. CRUD cajeros: set/change PIN → solo hash+sal en DB.  
2. Bootstrap Device Token incluye `cashiers` + `cashiers_version`.  
3. Sync incremental respeta versión (sin re-descarga si igual).  
4. Turno open/close y ops aceptan/persisten `cashier_contact_id`.  
5. Pruebas: snapshot, PIN hash, cajero inactivo, version igual.  
6. **Commit + tag** en rama Dev (p. ej. `hito25-cashiers-v1.0`) + changelog.  
7. Copiar este contrato (versión **OFICIAL**) a handoff estático / `Doc/` EPosOne.  
8. Entregar `cashier_name` legible (no vacío / no UUID) en bootstrap.

### Criterio de cierre Prog2 (después del handoff)

Bootstrap → cajeros → abrir turno desde APK → PIN local → offline → sync con `cashier_contact_id`.  
UI nunca muestra UUID como nombre de cajero (fallback `Cajero #id` + resolve desde catálogo).

---

## 8. Fuera de alcance

❌ Endpoints REST dedicados solo a listar cajeros  
❌ PIN plano en snapshot  
❌ Selección de Caja en login POS  
❌ Cableado HTTP en APK antes de commit/tag P1  
❌ Inventario / FE / licencias  

---

## 9. Changelog (este documento)

| Fecha | Cambio |
|-------|--------|
| 2026-07-18 | Propuesta congelable: PIN hash, snapshot cashiers, flujo POS-first, reglas offline/BO. |
| 2026-07-20 | §7 Ownership nombre: EN1 Integrado · Prog2 corrige UUID/vacío en tablet. |

---

## 10. Entregable P1 antes de Prog2

| # | Entrega |
|---|---------|
| 1 | Este contrato marcado **OFICIAL** + ejemplos request/response reales de Dev |
| 2 | Spec funcional corta (login, turno, offline) si difiere de §2–§5 |
| 3 | Changelog EN1 |
| 4 | Commit / tag de referencia |
| 5 | Confirmación: `easynodeone_dev` solo |

**Sin ese paquete, Prog2 no implementa el cliente HTTP de cajeros.**

---

*EasyTech · Hito 2.5 Cajeros contrato · 20 jul 2026*
