# OPC — Diagramas (S2)

| Campo | Valor |
|-------|--------|
| **Padre** | [OPC-000](OPC-000-EPOSONE-OPERATIONS-CONNECTOR.md) |
| **Fecha** | 5 ago 2026 |

---

## 1. Contexto EasyAI ↔ EPOSOne (EIS)

```mermaid
flowchart TB
  subgraph EasyAI["EasyAI Core"]
    Agent["Orquestación / razonamiento"]
  end

  subgraph EIS["EIS — CODITO"]
    Ctx["Context"]
    Tool["Tool"]
    Evt["Event"]
  end

  subgraph OPC["EPOSOne Operations Connector"]
    Auth["OpsAuth"]
    Reg["Allowlist Tools"]
    Gate["Risk / Actor gate"]
  end

  subgraph Dom["Dominios EPOSOne"]
    Cash["Cash Shift / Caja"]
    Ord["Order / OpenTicket"]
    Occ["OCC Pulse"]
    Sync["Sync / Telemetría"]
    Lic["Licencias"]
    Dev["Dispositivo 2.6"]
  end

  Agent --> EIS
  EIS --> OPC
  Auth --> Gate
  Reg --> Gate
  Gate --> Dom
```

---

## 2. Flujo invoke (lectura vs escritura)

```mermaid
sequenceDiagram
  participant EA as EasyAI
  participant OPC as OperationsConnector
  participant Auth as OpsAuth
  participant Dom as Domain facade

  EA->>OPC: listTools / describeTool
  OPC-->>EA: catálogo estructurado

  Note over EA,Dom: Lectura
  EA->>OPC: invoke(consultar|analizar)
  OPC->>Dom: loader
  Dom-->>OPC: Map
  OPC-->>EA: OpsToolResult.ok

  Note over EA,Dom: Escritura
  EA->>Auth: authorizeWithPin / fromPosSession
  Auth-->>EA: OpsInvokeSession authorized
  EA->>OPC: invoke(abrir|cerrar|cancelar, session)
  OPC->>OPC: gate auth + actor
  OPC->>Dom: writer
  Dom-->>OPC: Map
  OPC-->>EA: OpsToolResult.ok | rejected
```

---

## 3. Contextos y observación OCC

```mermaid
flowchart LR
  OCC[occ / dashboard]
  OCC --> Caja[caja / turnos]
  OCC --> Ped[pedidos]
  OCC --> Tel[telemetria]
  OCC --> Lic[licencias]
  OCC --> Dev[dispositivos]
  Rep[reportes] -.->|histórico · no OCC| Ventas[ventas]
```

---

## 4. Eventos (diccionario → futuro EIS)

```mermaid
flowchart TB
  DomEvt["Cambios de dominio\nOrder · Cash · Sync · License"]
  Local["Señales locales\nOCC · cola · snapshot"]
  Dict["OPC-003 Event Catalog"]
  Future["EIS Event transport\n(CODITO · futuro)"]
  EA["EasyAI subscribe/poll"]

  DomEvt --> Local
  Local --> Dict
  Dict --> Future
  Future --> EA
  Local -->|hoy: Tools| EA
```

---

## 5. Dual Mode (oculto al tool)

```mermaid
flowchart TB
  Tool["Tool ID estable"]
  Conn["Connector"]
  Tool --> Conn
  Conn --> SA["Standalone · datos locales"]
  Conn --> IN["Integrado · EN1 + local"]
  SA --> Out["Map respuesta"]
  IN --> Out
```
