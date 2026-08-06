# EPOSOne P0 — Checklist certificación Caja (apertura / cierre / arqueo)

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **Módulo** | Caja / Cash Shift |
| **Contrato HTTP** | [`EN1_EPOSONE_CASH_SHIFT_HTTP_CONTRACT.md`](EN1_EPOSONE_CASH_SHIFT_HTTP_CONTRACT.md) |
| **Spec** | [`EN1_EPOSONE_CASH_SHIFT_SPEC_V1.md`](EN1_EPOSONE_CASH_SHIFT_SPEC_V1.md) |
| **Log de sesión** | [`ETS_VALIDACION_CAJA_SPRINT_LOG.md`](ETS_VALIDACION_CAJA_SPRINT_LOG.md) |
| **Modo preferido 1ª pasada** | Standalone o Integrado con red (marcar en log) |

## Clasificación de hallazgos (ETS)

| Categoría | Acción |
|-----------|--------|
| Bloqueador RC | Corregir antes de cerrar módulo |
| Mejora UX | Anotar; pulir después de funcional |
| Backlog | Anotar; no desarrollar en la sesión |

## Casos (cerrar en orden)

| # | Caso | Qué demuestra | Resultado |
|---|------|---------------|-----------|
| 1 | PIN → `/cash/open` si no hay turno | Gate de jornada | ☐ |
| 2 | Abrir fondo 0 y fondo > 0 | Turno `open` en dispositivo | ☐ |
| 3 | Doble apertura | Rechazo / mensaje claro | ☐ |
| 4 | Tras abrir → `/pos` + chip turno | Operar venta | ☐ |
| 5 | Relanzar app con turno abierto | No pide abrir de nuevo; cajero asignado | ☐ |
| 6 | Hub `/cash-register` | Resumen teórico / ventas / métodos | ☐ |
| 7 | Tesorería: entrada | `expectedCash` sube | ☐ |
| 8 | Tesorería: retiro | `expectedCash` baja | ☐ |
| 9 | Cobro efectivo en turno | Teórico de cajón sube | ☐ |
| 10 | Cobro no-efectivo | No altera teórico de cajón (sí aparece en mix) | ☐ |
| 11 | `/cash-register/close` | Esperado / contado / diferencia visibles | ☐ |
| 12 | Cierre cuadrado | Contado = esperado → cierra OK | ☐ |
| 13 | Cierre descuadrado | Sobrante/faltante + notas; cierra OK | ☐ |
| 14 | Post-cierre | Sesión limpia → `/cash/open`; no cobrar | ☐ |
| 15 | Impresión opcional | Apertura / Z si hay impresora | ☐ N/A ☐ |
| 16 | Histórico turnos | `/reports/shifts` lista cerrados | ☐ |
| 17 | OCC → Cajas | Deep-links hub / cierre / tesorería | ☐ |
| 18 | Standalone | Open/close sin Device Token | ☐ |
| 19 | Integrado + online | Push Cash Shift HTTP open/close | ☐ N/A ☐ |
| 20 | Integrado + offline | Open/close encola; sync al volver | ☐ N/A ☐ |

## Gaps conocidos (no “arreglar” en sesión de cert)

- Movimientos de tesorería: UI local sí; **sin** contrato HTTP v1 → no exigir sync EN1 de movements.
- Cambio de cajero mid-turno: local sí; HTTP v1 no.
- Tests automatizados de UI: pendientes; unit de `computeShiftSummary` = soporte, no sustituye checklist.

## Criterio de cierre del módulo

> Un cajero puede abrir turno, operar cobros/tesorería, cerrar con arqueo (cuadrado y descuadrado) y volver a abrir, sin errores funcionales ni fricciones relevantes en una jornada de prueba.
