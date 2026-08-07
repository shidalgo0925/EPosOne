# ADR-032 — Modelo de Implementación de Productos

**Implementación Autogestionada (Standalone) e Implementación Asistida (Connected)**

| Campo | Valor |
|-------|--------|
| **ID** | ADR-032 |
| **Estado** | **PROPOSED** |
| **Versión** | 1.0 |
| **Fecha** | 7 ago 2026 |
| **Autor** | Arquitectura EN1 / EPOSOne |
| **Impacto** | EN1 · Portal ETS · EPOSOne APK |
| **Implementación** | **NO AUTORIZADA** — documento de arquitectura únicamente |
| **Complementa** | ADR-031 (Modelo Comercial) |
| **Relacionados** | ADR-027 · ADR-014 (lifecycle) · ADR-008 · Maestro P0 EN1↔LOCAL |

---

## 1. Objetivo

Definir el modelo oficial de implementación de los productos comercializados por Easy Technology Services.

Este ADR complementa el ADR-031 (Modelo Comercial) y establece cómo un producto contratado se convierte en un producto operativo.

---

## 2. Problema

Hasta ahora EN1 asumía que registrar un cliente implicaba iniciar inmediatamente la implementación técnica.

```text
Registro → Organización → Provisioning → Bootstrap → Operación
```

Ese modelo obliga a todos los clientes a seguir el mismo flujo, independientemente de la modalidad contratada.

Esto genera complejidad innecesaria para clientes Standalone.

---

## 3. Principio arquitectónico

**Comercial ≠ Implementación**

El registro comercial finaliza cuando el cliente obtiene:

- Cliente  
- Organización  
- Contrato  
- Suscripción  
- Licencia  

La implementación comienza únicamente cuando el producto contratado debe ponerse en operación.

---

## 4. Estrategias de implementación

Todo producto deberá definir una estrategia de implementación.

Actualmente se definen dos.

---

## 5. Implementación Autogestionada

### Aplica para

EPOSOne **Standalone**.

### Responsable principal

El **cliente**.

Easy Technology Services únicamente proporciona:

- licencia  
- activación  
- documentación  
- soporte (opcional)  

### Flujo

```text
Landing EPOSOne
  → Seleccionar Standalone
  → Registro
  → Verificación de correo
  → Contrato
  → Suscripción
  → Licencia
  → QR de activación
  → Descarga APK
  → Escanear QR
  → Activación
  → Asistente local
  → Operación
```

### El asistente local

La APK deberá permitir configurar completamente el negocio.

Como mínimo:

- Empresa  
- Moneda  
- Impuestos  
- Categorías  
- Productos  
- Clientes (opcional)  
- Caja inicial  
- Cajero administrador  
- Impresora  
- Configuración general  

Una vez completado el asistente, el cliente podrá comenzar a vender.

### EN1 NO crea

En modalidad Standalone **NO** deberán crearse automáticamente:

- sucursales  
- POS  
- cajas  
- cajeros  
- inventario cloud  
- bootstrap cloud  

La organización existe únicamente como **entidad comercial**.

### Recursos de ayuda

El asistente ofrecerá:

**Recursos gratuitos:** Manual PDF · Videos · Base de conocimiento · FAQ  

**Servicios profesionales:** Instalación remota · presencial · Migración · Capacitación  

Estos servicios podrán estar incluidos en el plan o contratados posteriormente.

---

## 6. Implementación Asistida

### Aplica para

EPOSOne **Connected**.

### Responsable principal

**Easy Technology Services**.

### Flujo

```text
Registro
  → Correo verificado
  → Contrato
  → Suscripción
  → Licencia
  → Asignación a implementación
  → Configuración EN1
  → Sucursal → POS → Caja → Cajeros
  → Código de activación
  → Descarga APK
  → Provisioning
  → Bootstrap
  → Operación
```

Estados de implementación (EN1; la APK solo pregunta “¿puedo continuar?”):

| Estado | Responsable |
|--------|-------------|
| Pendiente | Comercial |
| En preparación | Implementación |
| Lista para aprovisionar | Implementación |
| Provisioning | APK + EN1 |
| Operativa | Cliente |

---

## 7. Código / QR de activación

El QR deja de representar únicamente un código.

Representa una **orden de activación**.

Debe indicar como mínimo:

- producto  
- modalidad  
- estrategia de implementación  
- licencia  
- código  
- expiración  
- firma  

Ejemplo lógico:

| Campo | Standalone | Connected |
|-------|------------|-----------|
| Producto | EPOSOne | EPOSOne |
| Modalidad | Standalone | Connected |
| Implementación | Autogestionada | Asistida |

---

## 8. Comportamiento de la APK

La APK **NO** preguntará al usuario qué modalidad utilizar.

La modalidad será determinada por la **activación**.

Según esa información la APK ejecutará automáticamente el flujo correspondiente:

- **Autogestionada** → activación + asistente local → operación (sin bootstrap cloud).  
- **Asistida** → solo cuando EN1 diga “Lista para aprovisionar” → Provisioning → Bootstrap → operación.  

La APK **nunca crea infraestructura** operacional en EN1. Solo pregunta: ¿Puedo continuar?

---

## 9. Responsabilidades

### Cliente

- Instalar APK  
- Completar asistente Standalone  
- Mantener su información  
- Solicitar soporte cuando lo requiera  

### Easy Technology Services

- Administrar clientes, contratos, licencias  
- Proveer documentación y soporte  
- Ejecutar implementaciones asistidas cuando correspondan  
- Emitir órdenes de activación (QR)  

---

## 10. Servicios profesionales

La implementación es un **servicio independiente** del producto.

Puede estar incluida en determinados planes o contratada posteriormente.

Esto permite distintos niveles de acompañamiento sin modificar el producto.

---

## 11. Beneficios

### Standalone

- instalación inmediata  
- menor costo  
- sin intervención de EasyTech  
- escalable  
- onboarding sencillo  

### Connected

- implementación profesional  
- integración completa con EN1  
- sincronización  
- multi-sucursal  
- administración centralizada  

---

## 12. Principios

1. Todo producto define su estrategia de implementación.  
2. La implementación puede ser Autogestionada o Asistida.  
3. El registro comercial finaliza antes de iniciar cualquier implementación.  
4. La APK determina automáticamente el flujo a partir de la activación.  
5. Standalone no requiere infraestructura operacional en EN1 para operar.  
6. Connected requiere implementación previa antes del aprovisionamiento.  
7. Los servicios de implementación son independientes del licenciamiento.  

---

## 13. Impacto esperado

### CODITO (EN1) — solo analizar

- modelo de activación  
- emisión del QR (orden de activación)  
- información contenida en la licencia  
- separación entre activación e implementación  
- integración con ADR-031  

**No implementar** hasta aprobación + freeze HTTP.

### LOCAL (EPOSOne) — solo analizar

| Tema | Implicación |
|------|-------------|
| Asistente Standalone | Reusar/ampliar wizard local (`/onboarding` + setup) tras activación por QR; no bootstrap cloud |
| Activación QR | Consumir orden firmada (producto, modalidad, estrategia, licencia); no pedir Local/Cloud |
| Autogestionada | `readyToOperate` por licencia/activación válida, sin árbol Sucursal/POS/Caja |
| Asistida | Esperar autorización EN1 (“Lista para aprovisionar”) → Provisioning → Bootstrap |
| Contrato futuro | Primer entregable APK = consumir estado/orden de activación; no inventar HTTP |

**Postura vigente hasta freeze:** la APK mantiene el flujo actual hasta que EN1 publique el contrato de activación / implementación.

**No implementar** hasta aprobación + freeze HTTP.

---

## 14. Fuera de alcance

Este ADR **no autoriza**:

- cambios en `/start`  
- cambios en bootstrap  
- cambios en provisioning  
- eliminación de código  
- refactorizaciones  
- modificaciones de ADR anteriores (salvo enmienda explícita posterior)  

Su único propósito es definir el modelo arquitectónico de implementación para que CODITO y LOCAL trabajen sobre una misma visión.

---

## 15. Tensiones con ADRs previos (a resolver en aprobación)

| ADR | Tensión | Dirección esperada al aprobar |
|-----|---------|-------------------------------|
| ADR-027 | Standalone aún bajo org/device unificado | Enmendar: org comercial ≠ árbol operacional; Standalone = activación + asistente local |
| ADR-014 | Bootstrap bloqueante post-register | Bootstrap solo en estrategia Asistida / Connected |
| Gate 2 LOCAL | Register→Bootstrap siempre | Bifurcar por orden de activación |

---

## Estado

**PROPOSED**

Pendiente de revisión y aprobación por Arquitectura antes de cualquier implementación en EN1 o en la APK.
