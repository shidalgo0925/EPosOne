# OPC — Roadmap S2 (Operations Connector Specification)

| Campo | Valor |
|-------|--------|
| **Sprint** | S2 |
| **Proyecto** | EasyAI Core |
| **Rol Local** | Chief Architect – Operations Connector |
| **Padre** | [OPC-000](OPC-000-EPOSONE-OPERATIONS-CONNECTOR.md) |
| **Estado** | **CERRADO en Local** |
| **Cierre** | [`EPOSONE_EASYAI_S2_OPC_CLOSE_2026-08-05.md`](../EPOSONE_EASYAI_S2_OPC_CLOSE_2026-08-05.md) |
| **Fecha** | 5 ago 2026 |
| **Regla** | Documentar · no código · no GPT · no endpoints |

---

## 1. Objetivo del sprint

Al finalizar S2, EPOSOne tiene **completamente documentado** su Operations Connector para que EasyAI Core consuma la operación del POS **solo** vía Context / Tool / Event (EIS).

---

## 2. Plan de trabajo S2

| Paso | Entregable | Estado |
|------|------------|--------|
| 1 | OPC-000 Specification | **Hecho** |
| 2 | OPC-001 Context Catalog | **Hecho** |
| 3 | OPC-002 Tool Catalog | **Hecho** |
| 4 | OPC-003 Event Catalog | **Hecho** |
| 5 | OPC-004 Analytics Catalog | **Hecho** |
| 6 | OPC-005 Dashboard Catalog | **Hecho** |
| 7 | OPC-006 AI Opportunities | **Hecho** |
| 8 | Diagramas | **Hecho** |
| 9 | Validación cruzada (OPC-000 §9) | **Hecho** |
| 10 | Handoff a CODITO / EasyAI (review EIS aliases) | Pendiente externo |

---

## 3. Fuera de S2 (siguiente)

| Track | Contenido | Gate |
|-------|-----------|------|
| **S3 / ADR-017 Fase 3** | Transporte HTTP/MCP | EIS + EN1 EasyAI congelados |
| Wire Spec tools | `pedidos.crear`, clientes, inventario, `pedidos.anular`, pagos | Tras priorización EasyAI · sin romper POS |
| OCC B–D | Alert engine / auditoría rica | ADR-016 · no desplaza P0 E2E |
| Event subscribe | Bus EIS | CODITO |

---

## 4. Relación con trabajo previo Local

| Artefacto | Rol respecto a S2 |
|-----------|-------------------|
| ADR-017 Fases 0–2 | Scaffold in-process ya existe · S2 **especifica** formalmente |
| Tool catalog V1 | Runtime Wire · subsumido conceptualmente en OPC-002 |
| OCC Fase A | Fuente de OPC-005 |
| Order Events Model | Fuente de OPC-003 |

S2 **no** pide revertir ni ampliar ese código.

---

## 5. Criterio de cierre S2

- [x] Paquete `Doc/OPC/` completo  
- [x] EasyAI puede entender operación sin arquitectura interna  
- [x] Restricciones respetadas (no código / no GPT / no APIs nuevas)  
- [x] Cierre Local publicado  
- [ ] ACK CODITO de mapeo EIS (externo · no bloquea cierre Local)

**S2 Local: CERRADO.** Handoff listo para CODITO / EasyAI.
