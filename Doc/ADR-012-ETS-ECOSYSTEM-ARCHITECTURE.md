# ADR-012 — Arquitectura del Ecosistema Easy Technology Services (ETS)

| Campo | Valor |
|-------|--------|
| **Estado** | Aprobado (GO) |
| **Fecha** | 24 de julio de 2026 |
| **Aplica a** | EN1 · Portal ETS · EPosOne · EPayRoll · EClassOne · ETesis · futuros productos |
| **Relacionado** | [`ADR-011-ETS-PORTAL-SINGLE-ENTRY.md`](ADR-011-ETS-PORTAL-SINGLE-ENTRY.md) · [`ADR-013-ETS-PORTAL-SINGLE-ENTRY.md`](ADR-013-ETS-PORTAL-SINGLE-ENTRY.md) · [`ADR-007-EPOSONE-COMMERCIAL-LICENSING.md`](ADR-007-EPOSONE-COMMERCIAL-LICENSING.md) |

---

## Objetivo

Definir oficialmente la arquitectura del ecosistema de productos de Easy Technology Services.

A partir de este ADR, **EN1 deja de verse como el producto principal** y pasa a ser la **plataforma tecnológica** que soporta todo el ecosistema ETS.

---

## Principios

### 1. ETS es el ecosistema

Easy Technology Services (ETS) es la marca bajo la cual se ofrecen todos los productos.

Los clientes establecen su relación comercial con **ETS**.

- No con EN1.
- No con EPosOne.

### 2. EN1 es la plataforma

EasyNodeOne (EN1) es el **Core Platform**.

Responsabilidades:

- Autenticación
- Organizaciones
- Usuarios
- Seguridad
- Licencias
- Suscripciones
- Provisionamiento
- Auditoría
- APIs comunes
- Servicios compartidos

EN1 **no** es la experiencia comercial del cliente.

### 3. Los productos son independientes

Cada solución del ecosistema constituye un producto independiente.

Ejemplos: EPosOne · EPayRoll · EClassOne · ETesis · Relatic · futuros productos.

Cada uno tendrá:

- identidad propia;
- dominio propio;
- experiencia propia;
- navegación propia;
- funcionalidades propias.

### 4. Los clientes pertenecen a un producto

Cada cliente (tenant) existe dentro del contexto de un producto.

```text
ETS
  ↓
EPosOne
  ↓
Restaurante ABC
```

```text
ETS
  ↓
EPayRoll
  ↓
Empresa XYZ
```

**No** existe un tenant global para todos los productos.

### 5. EN1 comparte servicios

Todos los productos reutilizan:

- autenticación;
- licencias;
- organizaciones;
- auditoría;
- dispositivos;
- sincronización;
- bootstrap;
- servicios comunes.

No se duplicará infraestructura.

---

## Jerarquía oficial

```text
Internet
  ↓
Easy Technology Services (ETS)
  ↓
Portal ETS
  ↓
Productos
  ↓
Tenant del producto
  ↓
Usuarios
```

---

## Decisión

Se adopta oficialmente la siguiente jerarquía:

```text
ETS → Productos → Tenant → Usuarios
```

EN1 es la plataforma transversal que soporta todos los niveles.

---

## Resultado esperado

Agregar un nuevo producto no requerirá crear una nueva plataforma.

Únicamente:

1. registrar el producto;
2. asignar un dominio;
3. configurar BrandContext;
4. configurar ProductContext.

Todo lo demás será reutilizado desde EN1.

---

*EasyTech · ADR-012 Ecosistema ETS · 24 jul 2026*
