# Regla de Handoff EN1 → EPosOne

**Estado:** Aprobada · 14 jul 2026  
**Motivo:** Dos repositorios independientes; P2 no debe depender de buscar docs en EN1.

## Paquete obligatorio al cerrar un hito en EN1

| # | Entrega | Copiar a EPosOne |
|---|---------|------------------|
| 1 | Roadmap actualizado | `Doc/` |
| 2 | Contrato HTTP congelado | `Doc/` |
| 3 | Especificación funcional congelada | `Doc/` |
| 4 | Ejemplos request / response | dentro del contrato o anexo |
| 5 | Changelog del hito | `Doc/` o sección en handoff |
| 6 | Commit / tag de referencia | bitácora + handoff |

## Hito 3 — pendiente de recepción

P1 ya congeló el contrato en EN1. **Debe enviar** (sin modificar):

- `docs/EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`  
- `docs/EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md`  

Destino en este repo:

- `Doc/EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`  
- `Doc/EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md`  

Hasta que existan esos archivos, **no** codificar payloads HTTP definitivos en la APK.

## Responsabilidades

| Rol | Acción |
|-----|--------|
| **P1** | Entregar paquete · no reabrir contrato · soporte bugs |
| **P2** | Scaffold local OK · HTTP solo tras docs en `Doc/` |
| **Arquitectura** | Validar que el handoff esté completo antes del GO de código de red |

Ver también: [`.cursor/rules/en1-handoff.mdc`](../.cursor/rules/en1-handoff.mdc)
