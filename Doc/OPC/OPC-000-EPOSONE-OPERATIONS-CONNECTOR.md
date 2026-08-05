# OPC-000 — EPOSOne Operations Connector

| Campo | Valor |
|-------|--------|
| **ID** | OPC-000 |
| **Proyecto** | EasyAI Core |
| **Rol Local** | Chief Architect – Operations Connector |
| **Sprint** | **S2** — Operations Connector Specification |
| **Estado** | **CERRADO (S2)** — especificación completa · handoff CODITO externo |
| **Fecha** | 5 de agosto de 2026 |
| **ADR de decisión** | [`ADR-017`](../ADR-017-EASYAI-OPERATIONS-CONNECTOR.md) |
| **Catálogo tools runtime** | [`EPOSONE_EASYAI_OPS_TOOL_CATALOG_V1.md`](../EPOSONE_EASYAI_OPS_TOOL_CATALOG_V1.md) |
| **Estándar externo** | **EIS** (EasyAI Integration Standard) — SoT CODITO |
| **Paquete** | [`Doc/OPC/`](./) |

---

## 1. Objetivo

Preparar **EPOSOne** para ser consumido por **EasyAI Core** como proveedor de información y acciones **operacionales**, mediante el estándar **EIS** definido por CODITO.

Al cerrar S2, EasyAI debe poder **comprender la operación del POS** usando únicamente el Operations Connector — sin conocer Isar, SQLite, schemas internos ni pantallas Flutter.

| EPOSOne entrega | EPOSOne **no** entrega |
|-----------------|------------------------|
| Contextos, Herramientas, Eventos, Analytics (catálogos) | Modelos, prompts, agentes GPT |
| Fachada única de integración | Acceso directo a tablas / archivos |
| Auth operacional (sesión / PIN) sobre tools de escritura | Cambio de reglas de negocio POS |

---

## 2. Alcance (S2)

### En alcance

1. Documentar el **Operations Connector** (este OPC-000).  
2. Inventariar **Contextos** (OPC-001).  
3. Inventariar **Herramientas** (OPC-002) — declarar, no implementar nuevas.  
4. Inventariar **Eventos** (OPC-003) — documentar existentes; no modificar.  
5. Inventariar **Analytics / indicadores** (OPC-004).  
6. Documentar superficie **Dashboard / OCC** para EasyAI (OPC-005) — sin pantallas nuevas.  
7. Documentar **oportunidades IA** (OPC-006) — sin diseñar IA.  
8. Diagramas + Roadmap S2.  
9. Validación cruzada vs EIS, ADR EasyAI, Cash Shift, Order Domain, OCC, Licencias, Sync.

### Fuera de alcance (S2)

- Desarrollar o modificar código EPOSOne.  
- Integrar GPT / LLM.  
- Crear endpoints HTTP / MCP (Fase 3 ADR-017; requiere EIS/EN1 congelados).  
- Cambiar APIs EN1, sync, Order lifecycle, Cash Shift contracts.  
- Cambiar flujo operativo del cajero.  
- Reabrir OCC ≠ reportes.

---

## 3. Responsabilidades

| Actor | Responsabilidad |
|-------|-----------------|
| **EPOSOne (Local)** | Publicar Context / Tool / Event catalogs; ejecutar tools vía Connector; auth; Dual Mode detrás de la fachada |
| **EasyAI Core** | Orquestar razonamiento; invocar solo Connector; nunca asumir tablas |
| **CODITO** | SoT de **EIS** (nombres, transport, versionado) |
| **EN1** | Origen de verdad multi-org / contratos HTTP ya congelados; no reinventar vía EasyAI |

---

## 4. Dependencias

| Dependencia | Uso | Estado |
|-------------|-----|--------|
| **EIS (CODITO)** | Forma canónica Context/Tool/Event/Session | Externo · mapear OPC → EIS |
| [`ADR-017`](../ADR-017-EASYAI-OPERATIONS-CONNECTOR.md) | Decisión de fachada | Cerrado Fases 0–2 (código scaffold) |
| [`ADR-016`](../ADR-016-EPOSONE-OPERATIONS-CONTROL-CENTER.md) | OCC ≠ reportes | Fase A |
| Order Domain | Pedidos / eventos | Contratos Hito 3 |
| Cash Shift | Turno / caja | Contrato HTTP + local |
| Licensing ADR-007 | Snapshot / gracia | Activo |
| Sync / telemetría | Cola · errores | Activo |
| Ownership / Dual Mode | Standalone vs Integrado | Matrices V1 |

**Nota S2:** Existe scaffold in-process (`OperationsConnector`, Fases 0–2). S2 **congela la especificación documental**. Ampliar código o transporte remoto **no** es parte de S2.

---

## 5. Compatibilidad con EIS

EIS (CODITO) es el estándar de integración EasyAI. EPOSOne no redefine EIS; **mapea** superficies OPC a primitivas EIS.

| Primitiva EIS (esperado) | Superficie OPC EPOSOne | Notas |
|--------------------------|------------------------|-------|
| **Context** | OPC-001 Context ID | Namespace estable `{id}` |
| **Tool** | OPC-002 `{context}.{verb}[.{resource}]` | Allowlist; rechazo de `db.*` / SQL |
| **Event** | OPC-003 Event ID | Solo documentar emisión existente |
| **Session / Auth** | `OpsInvokeSession` + `OpsAuth` | Escrituras: authorized + actor_id |
| **Result** | `OpsToolResult` ok / rejected / error | Códigos estables |
| **Transport** | In-process hoy · HTTP/MCP futuro | **Bloqueado** hasta EIS+EN1 congelados |

### Reglas de mapeo

1. Un Context EIS = un Context OPC (o composición documentada).  
2. Un Tool EIS = un Tool OPC (1:1 preferido).  
3. Eventos no se inventan en S2; se catalogan desde Order / Cash / Sync / License.  
4. Si EIS nombra distinto, OPC mantiene IDs locales y declara **alias EIS** cuando CODITO lo publique.  
5. EPOSOne **nunca** expone schema Isar como Context EIS.

### API lógica del Connector (alineada EIS Tool Runtime)

| Método | Semántica |
|--------|-----------|
| `listContexts()` | Contextos publicados |
| `listTools({context?})` | Catálogo |
| `describeTool(toolId)` | Schema I/O |
| `invoke(toolId, input, session)` | Ejecución controlada |
| `listEvents` / `subscribe` *(futuro)* | Solo tras contrato eventos EIS |

---

## 6. Arquitectura (vista lógica)

```text
┌─────────────────────────────────────────────┐
│                 EasyAI Core                 │
│         (razona · no conoce Isar)           │
└─────────────────────┬───────────────────────┘
                      │  EIS (CODITO)
                      │  Context · Tool · Event
                      ▼
┌─────────────────────────────────────────────┐
│     EPOSOne Operations Connector (OPC)      │
│  auth · allowlist · risk · Dual Mode hide   │
└─────────────────────┬───────────────────────┘
                      │  facades de dominio
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   Cash Shift    Order Domain     OCC Pulse
   License         Sync           Device 2.6
   Sales           Catalog        Reports hub
```

Principio: **una fachada**. EasyAI no llama repositorios ni pantallas.

---

## 7. Principios congelados (heredados ADR-017)

1. No IA en EPOSOne.  
2. No acceso directo a tablas.  
3. Una fachada Connector.  
4. Dual Mode transparente al tool.  
5. OCC ≠ reportes.  
6. No inventar HTTP EN1 EasyAI hasta contrato congelado.  
7. S2 = documentación; no cambia flujo POS ni reglas de negocio.

---

## 8. Entregables S2

| ID | Documento |
|----|-----------|
| OPC-000 | Este documento |
| OPC-001 | [Operations Context Catalog](OPC-001-OPERATIONS-CONTEXT.md) |
| OPC-002 | [Operations Tool Catalog](OPC-002-OPERATIONS-TOOLS.md) |
| OPC-003 | [Operations Event Catalog](OPC-003-OPERATIONS-EVENTS.md) |
| OPC-004 | [Operations Analytics Catalog](OPC-004-OPERATIONS-ANALYTICS.md) |
| OPC-005 | [Operations Dashboard Catalog](OPC-005-OPERATIONS-DASHBOARD.md) |
| OPC-006 | [Operations AI Opportunities](OPC-006-OPERATIONS-AI-OPPORTUNITIES.md) |
| — | [Diagramas](OPC-DIAGRAMS.md) |
| — | [Roadmap S2](OPC-S2-ROADMAP.md) |

---

## 9. Validación cruzada (checklist)

| Referencia | Resultado |
|------------|-----------|
| EIS (CODITO) | Mapeo §5 · pending alias oficiales |
| ADR-017 EasyAI | Alineado · SoT decisión |
| Cash Shift | Contextos `caja`/`turnos` · eventos open/close |
| Order Domain | Context `pedidos` · eventos cancel/void/refund |
| OCC ADR-016 | Context `occ`/`dashboard` · OCC ≠ reportes |
| Licenciamiento | Context `licencias` · evento vencimiento |
| Sync | Context `telemetria` · SyncCompleted / DeviceOffline |
| Arquitectura existente | Sin endpoints nuevos · sin cambio de contratos |

---

## 10. Criterio de aceptación S2

- [x] OPC-000..006 publicados en `Doc/OPC/`  
- [x] Diagramas + Roadmap S2  
- [x] Validación cruzada documentada  
- [x] Sin código nuevo / sin endpoints / sin GPT  
- [x] EasyAI puede planificar consumo solo con este paquete  

**Objetivo final S2:** EPOSOne tiene **completamente documentado** su Operations Connector.
