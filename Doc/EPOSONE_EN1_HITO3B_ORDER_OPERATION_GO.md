# Hito 3B — Operación del Pedido · GO Programador 2

**Estado:** 🟢 GO ABIERTO  
**Fecha:** 14 de julio de 2026  
**Máquina:** APK / Flutter (repo EPosOne) — no servidor EN1  
**Prerrequisito:** Hito 3 Order Domain ✅ · tag EN1 `eposone-order-domain-v1.0`  
**Contrato canónico (EN1):** `docs/EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`  
**Roadmap:** [`EPOSONE_EN1_ROADMAP_V5.md`](EPOSONE_EN1_ROADMAP_V5.md)

---

## Objetivo

Implementar la **operación del Pedido** usando **exclusivamente** el contrato HTTP congelado.

| Regla | |
|-------|--|
| No modificar contratos | ✅ |
| No pedir cambios a EN1 | ✅ (salvo bug real vía P1 soporte) |
| No inventar reglas de negocio | ✅ |
| Auth | **Bearer Device Token** únicamente |

---

## Consumir únicamente

### Bootstrap (ya existente)

```
GET /api/v1/devices/bootstrap
Authorization: Bearer <DeviceToken>
```

### Pedido (Hito 3)

```
POST   /api/v1/orders
GET    /api/v1/orders
GET    /api/v1/orders/{id}
PATCH  /api/v1/orders/{id}
POST   /api/v1/orders/{id}/events
POST   /api/v1/orders/{id}/payments
```

Detalle de payloads / códigos / ownership: contrato HTTP congelado en EN1 (no reinterpretar aquí).

---

## Alcance (sí)

| Área | Acciones |
|------|----------|
| Pedido | Nuevo · Guardar · Continuar · Cerrar |
| Productos | Agregar · Eliminar · Modificar cantidad · Observaciones |
| Pago | Cobrar · Mixto · Parcial **si el contrato lo soporta** |
| Eventos (automáticos) | `pedido.creado` · `producto.agregado` · `producto.eliminado` · `cantidad.modificada` · `pedido.cobrado` |

- Usuario ejecuta **acciones**; sistema deriva estados.  
- **No** pantallas/APIs de “cambiar estado” manual.

---

## Fuera de alcance (no)

Inventario · Kardex · Transferencias · Compras · Caja avanzada · FE · CxC · Recetas · KDS · ampliar endpoints.

---

## Offline-first

Sin red → guardar local → cola sync → al volver Internet sincronizar con EN1.  
**Nunca bloquear la venta** por falta de conexión.

---

## Criterio de aceptación (Hito 3B)

1. Dispositivo **ya provisionado** crea un Pedido  
2. Pedido se almacena **localmente**  
3. Pedido se **sincroniza** con EN1  
4. Pedido se puede **consultar de nuevo** desde EN1  
5. Pedido sigue **editable** mientras esté abierto (según ownership)  
6. Eventos del Pedido registrados correctamente  
7. **Ningún** contrato del Hito 3 modificado  

---

## Cierre Hito 3 (E2E con P1)

Cuando 3B esté listo, integración conjunta:

```
Crear Pedido (APK)
  → Agregar productos
  → Guardar local
  → Sync
  → EN1 registra Pedido
  → Consultar en BackOffice
  → Continuar Pedido
  → Cobrar
  → Cerrar
```

Si ese flujo funciona → **Hito 3 cerrado**.

P1 en paralelo: solo bugs / validaciones / rendimiento — **sin** nuevos endpoints ni ampliación de dominio.

---

## Después

**Hito 3.5 — Validación operativa** (antes de Inventario):

- Food Truck  
- Restaurante casual  
- Restaurante con caja central  

Si el modelo aguanta sin cambios estructurales → entonces **Hito 5 Inventario**.

---

## Congelados P2

Provisioning · Bootstrap contrato · Catálogo maestro · POS Core (motor); solo cablear Pedido al contrato.

---

*GO Hito 3B · EasyTech · 14 jul 2026*
