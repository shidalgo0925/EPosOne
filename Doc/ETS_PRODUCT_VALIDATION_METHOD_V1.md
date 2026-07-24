# ETS Product Validation Method — EPosOne V1.0

**Fecha:** 18 jul 2026  
**Estado:** Adoptado (Analista · P1 · P2)  
**Objetivo de etapa:** No desarrollar más features. Validar el producto como un cliente que acaba de instalarlo.  
**Principio:** Validar **operación**, no botones.

---

## 1. Cambio de mentalidad

| Incorrecto | Correcto |
|------------|----------|
| “¿El botón funciona?” | “¿Puedo operar un restaurante una hora?” |
| Checklist de controles | Día normal de trabajo |
| “✔ Funciona” | “¿El cajero aguantaría 8 horas en esta pantalla?” |

Un POS debe ser **rápido**. Lo que funciona pero cansa **no** está listo.

---

## 2. Estados de cada módulo (obligatorio)

```
Desarrollado
    ↓
Validado funcionalmente
    ↓
Pulido UX
    ↓
Release Candidate
```

Ningún módulo avanza al siguiente estado hasta cerrar el anterior.  
Ningún módulo nuevo se abre hasta cerrar el actual.

**Orden V1.0 (un módulo a la vez):**

1. **Pedido** (ahora)  
2. Cobro  
3. Caja  
4. … resto del plan operativo (catálogo, sync como parte de Pedido/Cobro, config, UX final)

---

## 3. Clasificación de hallazgos (única permitida)

| Categoría | Criterio | Acción |
|-----------|----------|--------|
| **Bloqueador RC** | Impide liberar V1.0 | Corregir antes de cerrar el módulo |
| **Mejora UX** | No impide liberar; fricción / fatiga | Pulido UX del mismo módulo (después de funcional) |
| **Backlog futuro** | Idea / “ya que estamos…” | Anotar y **no** desarrollar ahora |

Prohibido mezclar “ya que estamos aquí…” con la sesión de validación.

---

## 4. Criterio de cierre de módulo

El módulo **Pedido** (y luego cada uno) solo se cierra cuando:

> Un cajero puede operar una **jornada completa** de forma fluida, sin errores funcionales ni fricciones relevantes.

No basta con “todos los casos pasaron una vez”.

---

## 5. Sprint Pedido — Validación Funcional V1.0

**Rol:** cajero en tablet · menú EN1 real · revisar también EN1 BO.  
**No:** revisión de código.

### Escenario guía (operación real)

Llega cliente → abro pedido → agrego bebida → cambia de opinión → quito bebida → agrego otra → llega otra persona → segundo plato → piden cuenta → dividen el pago → imprimo → cierro → reviso EN1.

### Casos (cerrar en orden)

| # | Caso | Qué demuestra |
|---|------|----------------|
| 1 | Happy path | Crear → líneas → guardar → cobrar un método → cerrar → sync → visible en EN1 |
| 2 | Cliente cambia de opinión | Quitar / cambiar ítem sin romper totales ni sync |
| 3 | Cliente agrega más | Añadir líneas a pedido ya abierto |
| 4 | Se equivoca el cajero | Corregir qty / borrar / recuperar sin datos basura |
| 5 | Cambio de vendedor | Si aplica en UX actual; si no existe, anotar (UX o backlog) |
| 6 | Pago mixto | Varios tenders, saldo, confirmar cobro |
| 7 | Se cae Internet | Seguir vendiendo / cobrando offline |
| 8 | Regresa Internet | Sync sin duplicados / cola limpia |
| 9 | Verificación EN1 | Pedido/pago correctos en BO |
| 10 | Auditoría | Trazabilidad mínima (quién, cuándo, montos, estado) coherente POS↔EN1 |

### Plantilla de hallazgo

```
Caso: #
Momento: (qué hacía el cajero)
Observado:
Esperado:
Categoría: Bloqueador RC | Mejora UX | Backlog futuro
Severidad / nota:
```

---

## 6. Instrucción de arranque (equipo)

**GO.**

Procedemos con la **Validación Funcional V1.0** iniciando por el módulo **Pedido**.

No validamos botones; validamos la **operación real del negocio**.

Cada hallazgo: **Bloqueador RC** · **Mejora UX** · **Backlog futuro**.

Pedido se cierra solo con jornada fluida. Luego **Cobro**, luego **Caja**. Un módulo a la vez.

---

## 7. Relación con roadmap

- Alineado con: congelar features · 3C E2E · [`EPOSONE_EN1_ROADMAP_V5.md`](EPOSONE_EN1_ROADMAP_V5.md)  
- Comercial / licencias: ADR-007 — **fuera** de este sprint Pedido  
- Inventario / FE / KDS: no ahora  

---

*EasyTech · ETS Product Validation Method · 18 jul 2026*
