# ADR-011 — Portal ETS como Punto Único de Entrada del Ecosistema

| Campo | Valor |
|-------|--------|
| **Estado** | Aprobado (GO) — **dominio de portal refinado por ADR-013** |
| **Fecha** | 24 de julio de 2026 |
| **Dirigido a** | Codito (EN1) · Local (EPosOne) |
| **Relacionado** | [`ADR-012-ETS-ECOSYSTEM-ARCHITECTURE.md`](ADR-012-ETS-ECOSYSTEM-ARCHITECTURE.md) · [`ADR-013-ETS-PORTAL-SINGLE-ENTRY.md`](ADR-013-ETS-PORTAL-SINGLE-ENTRY.md) · [`ADR-007-EPOSONE-COMMERCIAL-LICENSING.md`](ADR-007-EPOSONE-COMMERCIAL-LICENSING.md) · [`EPOSONE_LICENSE_ENGINE_V1.md`](EPOSONE_LICENSE_ENGINE_V1.md) |

> **Nota (24 jul 2026):** el dominio canónico del Portal ETS es **`app.easytech.services`** ([ADR-013](ADR-013-ETS-PORTAL-SINGLE-ENTRY.md)). Las menciones a `portal.easytech.services` en este documento quedan históricas.

---

## Objetivo

Definir la arquitectura oficial del **Portal ETS** como punto único de entrada para todos los productos del ecosistema Easy Technology Services.

Esta decisión establece cómo se registran los clientes, cómo adquieren productos y cómo interactúan posteriormente con cada solución del ecosistema.

---

## Principios de Arquitectura

### 1. EN1 es el núcleo del ecosistema

EasyNodeOne (EN1) será el **Core Platform** de todos los productos de Easy Technology Services.

Toda la información central vive en EN1:

- Usuarios
- Organizaciones
- Empresas
- Suscripciones
- Licencias
- Seguridad
- Auditoría
- Dispositivos
- Provisionamiento
- Facturación (futuro)
- Marketplace (futuro)

Ningún producto administrará esta información de manera independiente.

### 2. Portal ETS

El cliente siempre inicia su experiencia desde un único portal.

Ejemplo: `portal.easytech.services`

Desde este portal podrá:

- Registrarse
- Iniciar sesión
- Ver sus productos
- Comprar nuevos productos
- Administrar suscripciones
- Consultar facturas
- Descargar aplicaciones
- Administrar dispositivos
- Acceder a soporte

Este portal será equivalente al Customer Portal de plataformas como Contabo, Microsoft 365 o Google Workspace.

### 3. Productos con identidad propia

Cada producto tendrá su propia identidad visual y su propio subdominio.

Ejemplos:

- `eposone.easytech.services`
- `epayroll.easytech.services`
- `eclassone.easytech.services`
- `etesis.easytech.services`

No se adquirirán dominios independientes en esta etapa.

Todos los productos permanecerán bajo la marca principal: **easytech.services**

### 4. Una sola aplicación EN1

No existirán múltiples instalaciones del Core.

Existirá una **única aplicación EN1**.

El comportamiento dependerá del dominio de entrada:

```text
Host
  ↓
BrandContext
  ↓
ProductContext
  ↓
Experiencia del usuario
```

### 5. BrandContext

Dependiendo del dominio utilizado, la aplicación cambiará automáticamente:

- Logo
- Nombre comercial
- Colores
- Favicon
- Textos
- Navegación
- Layout
- Pantalla inicial

Ejemplo:

| Host | Tema |
|------|------|
| `appprd.easynodeone.com` | EN1 |
| `eposone.easytech.services` | EPosOne |

No se duplicará código.

### 6. ProductContext

Además del tema visual, el sistema conocerá qué producto está utilizando el cliente.

| Producto | Carga |
|----------|--------|
| EPosOne | Únicamente módulos POS |
| EPayRoll | Únicamente módulos de nómina |

Cada producto mostrará únicamente su funcionalidad.

---

## Dos superficies claramente diferenciadas

### Portal ETS

Experiencia **comercial**. Incluye:

- Marketplace
- Registro
- Inicio de sesión
- Productos contratados
- Suscripciones
- Facturación
- Métodos de pago
- Descargas
- Licencias
- Dispositivos
- Perfil

**No** expone el ERP completo.

### Producto

Cada producto tendrá su propia experiencia operativa.

| Producto | Ejemplos de módulos |
|----------|---------------------|
| EPosOne | Ventas, Caja, Clientes, Inventario, Reportes |
| EPayRoll | Nómina, Empleados, Planillas |
| EClassOne | Cursos, Estudiantes, Matrículas |

El usuario nunca verá módulos de otros productos.

---

## Flujo general

```text
Cliente
  ↓
Portal ETS
  ↓
Registro
  ↓
Inicio de sesión
  ↓
Mis Productos
  ↓
Marketplace (si desea adquirir otro)
  ↓
Selecciona un producto
  ↓
Suscripción
  ↓
Licencia
  ↓
Provisionamiento
  ↓
Descarga aplicación
  ↓
Registro del dispositivo
  ↓
Bootstrap
  ↓
Operación
```

---

## Licenciamiento

Toda licencia nace exclusivamente en EN1.

La APK **nunca**:

- crea licencias;
- modifica licencias;
- vende licencias;
- genera Trial;
- interpreta planes comerciales.

La APK **únicamente**:

- descarga;
- almacena;
- valida localmente;
- aplica permisos.

(Alineado con ADR-007 y License Engine V1.0 en EPosOne.)

---

## Aprovisionamiento

Todo el aprovisionamiento ocurre en EN1.

Se crean:

- Organización
- Empresa
- Sucursal
- POS
- Caja
- Licencia

La aplicación únicamente se registra contra una **Caja** existente.

---

## Marketplace

El Marketplace pertenece al **Portal ETS**.

No pertenece a EPosOne.

Permitirá adquirir:

- nuevos productos;
- módulos;
- servicios;
- futuras integraciones.

---

## Estado del Cliente

Después del primer ingreso, la pantalla principal mostrará únicamente los productos contratados.

Ejemplo:

```text
Mis Productos
✔ EPosOne
  Estado: Activo
  Plan: Profesional
  Próximo vencimiento: 15/08/2026
  Dispositivos: 2
  [Administrar]
```

Si el cliente no posee un producto, podrá adquirirlo desde el Marketplace.

---

## Estrategia de Dominios

Se adopta oficialmente el uso de **subdominios**.

Ejemplo:

- `portal.easytech.services`
- `eposone.easytech.services`
- `epayroll.easytech.services`
- `eclassone.easytech.services`
- `etesis.easytech.services`

No se crearán dominios independientes mientras no exista una necesidad comercial o de marca que lo justifique.

---

## Implementación — ownership

### Codito (EN1)

Responsable de:

- Portal ETS
- BrandContext
- ProductContext
- Marketplace
- Suscripciones
- Licencias
- Provisionamiento
- Bootstrap
- Gestión de dispositivos
- APIs

### Local (EPosOne)

Responsable de:

- Registro del dispositivo
- Consumo del Bootstrap
- License Engine
- Feature Manager
- Operación offline
- Sincronización
- Experiencia del POS

---

## Decisión Arquitectónica

Se aprueba oficialmente la siguiente visión del ecosistema:

> EasyNodeOne será el núcleo común de todos los productos de Easy Technology Services. Los clientes accederán inicialmente al Portal ETS, desde donde administrarán sus productos, suscripciones y servicios. Cada producto contará con una identidad propia mediante subdominios y BrandContext, compartiendo una única plataforma tecnológica sin duplicar aplicaciones ni lógica de negocio.

Este documento constituye la base arquitectónica para la evolución de EPosOne y del resto del ecosistema ETS.

---

*EasyTech · ADR-011 Portal ETS · 24 jul 2026*
