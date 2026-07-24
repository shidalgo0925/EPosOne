# ADR-013 — Portal ETS como Punto Único de Entrada

| Campo | Valor |
|-------|--------|
| **Estado** | Aprobado (GO) |
| **Fecha** | 24 de julio de 2026 |
| **Dominio oficial** | `app.easytech.services` |
| **Supersede / refina** | Dominio de portal en [`ADR-011-ETS-PORTAL-SINGLE-ENTRY.md`](ADR-011-ETS-PORTAL-SINGLE-ENTRY.md) (`portal.` → **`app.`**) |
| **Relacionado** | [`ADR-012-ETS-ECOSYSTEM-ARCHITECTURE.md`](ADR-012-ETS-ECOSYSTEM-ARCHITECTURE.md) · [`ADR-007-EPOSONE-COMMERCIAL-LICENSING.md`](ADR-007-EPOSONE-COMMERCIAL-LICENSING.md) |

---

## Objetivo

Definir el Portal ETS como la puerta de entrada oficial del ecosistema Easy Technology Services.

---

## Dominio oficial

```text
app.easytech.services
```

Este portal representa la relación comercial entre el cliente y **ETS**.

No representa un producto específico.

---

## Responsabilidades del Portal

El Portal ETS será responsable de:

- Registro de clientes
- Inicio de sesión
- Gestión de cuenta
- Productos contratados
- Marketplace de productos
- Suscripciones
- Licencias
- Facturación
- Métodos de pago
- Descargas
- Soporte
- Perfil

---

## Lo que NO hace

El Portal ETS **no** ejecuta la lógica funcional de los productos.

Ejemplo: no vende en POS, no factura ventas de restaurante, no administra inventarios, no administra nóminas.

Eso pertenece a cada producto.

---

## Flujo

```text
Cliente
  ↓
app.easytech.services
  ↓
Iniciar sesión
  ↓
Mis Productos
  ↓
Seleccionar producto
  ↓
Abrir producto
  ↓
Dominio del producto
  ↓
Tenant
  ↓
Operación
```

### Ejemplo EPosOne

```text
Cliente → Portal ETS → EPosOne → eposone.easytech.services
  → Restaurante ABC → Operación POS
```

### Ejemplo EPayRoll

```text
Cliente → Portal ETS → EPayRoll → epayroll.easytech.services
  → Empresa XYZ → Administración de nómina
```

---

## Relación con EN1

El Portal ETS utiliza los servicios comunes de EN1.

No duplica: autenticación · licencias · organizaciones · auditoría · APIs.

---

## Mapa arquitectónico oficial ETS

```text
                           INTERNET
                               │
                               ▼
                    app.easytech.services
                      Portal del Ecosistema
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
     EPosOne              EPayRoll             EClassOne
eposone.easytech...  epayroll.easytech... eclassone.easytech...
        │                      │                      │
        ▼                      ▼                      ▼
   Tenant Cliente A      Tenant Empresa B      Tenant Colegio C
        │                      │                      │
        ▼                      ▼                      ▼
      Usuarios              Usuarios              Usuarios

──────────────────────────────────────────────────────────────

                 Plataforma Compartida (EN1)

• Autenticación · Organizaciones · Licencias · Suscripciones
• Provisionamiento · Bootstrap · Sincronización · Auditoría
• APIs · Seguridad · ContextResolver · BrandContext · ProductContext
```

---

## Resultado esperado

El cliente percibe una experiencia uniforme bajo ETS, mientras que cada producto mantiene su propia identidad y funcionalidad.

---

## Decisión final (012 + 013)

A partir de estos ADR queda establecida la arquitectura oficial del ecosistema:

1. **ETS** es la marca y el ecosistema.
2. **Portal ETS** (`app.easytech.services`) es el punto único de entrada.
3. **EN1** es la plataforma compartida.
4. Cada producto (EPosOne, EPayRoll, EClassOne, ETesis, etc.) tiene su propio dominio, identidad y experiencia.
5. Cada producto administra sus propios tenants, reutilizando los servicios comunes de EN1.

---

*EasyTech · ADR-013 Portal ETS · 24 jul 2026*
