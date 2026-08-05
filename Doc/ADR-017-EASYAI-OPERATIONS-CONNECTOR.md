# ADR-017 — EasyAI Core · Operations Connector (EPOSOne)

| Campo | Valor |
|-------|--------|
| **Estado** | **Fase 2 cerrada** (escrituras + auth PIN/sesión) · Fase 3 transporte pendiente |
| **Fecha** | 5 de agosto de 2026 |
| **Commit Fase 0** | `1bcfb43` |
| **Commit Fase 1** | `13ee49f` |
| **Commit Fase 2** | `e29d38e` |
| **Proyecto** | EasyAI Core |
| **Rol Local** | Arquitecto Operacional / proveedor de herramientas |
| **SoT** | Este ADR + [`EPOSONE_EASYAI_OPS_TOOL_CATALOG_V1.md`](EPOSONE_EASYAI_OPS_TOOL_CATALOG_V1.md) |
| **Relacionado** | [`ADR-016`](ADR-016-EPOSONE-OPERATIONS-CONTROL-CENTER.md) OCC · [`ADR-008`](ADR-008-EPOSONE-COMMERCIAL-ENGINE.md) · Ownership |

---

## 1. Decisión

EPOSOne se convierte en **proveedor de información operacional** para EasyAI.

| EPOSOne hace | EPOSOne **no** hace |
|--------------|---------------------|
| Publicar **contextos** y **herramientas** | Desarrollar modelos / prompts / agentes IA |
| Ejecutar herramientas vía **Operations Connector** | Exponer tablas Isar / SQL / archivos crudos |
| Validar auth, scope, riesgo | Razonar o decidir por el usuario |

EasyAI consume **solo** el Connector.  
El Connector traduce a servicios de dominio existentes (caja, pedidos, OCC, sync, …).

---

## 2. Principios congelados

1. **No IA en EPOSOne** — solo herramienta + contexto.  
2. **No acceso directo a tablas** — ni schemas Isar, ni queries ad hoc.  
3. **Una fachada** — `OperationsConnector` es el único punto de entrada EasyAI↔APK.  
4. **Misma lógica Dual Mode** — Standalone / Integrado solo cambia origen de datos detrás del tool.  
5. **OCC ≠ reportes** sigue vigente; tools de Dashboard/OCC son operacionales.  
6. **No inventar HTTP EN1** para EasyAI hasta contrato EasyAI/EN1 congelado; Fase 0 es local/in-process.

---

## 3. Operations Connector

```text
EasyAI Core
    │  listTools / describeContext / invokeTool
    ▼
OperationsConnector  (EPOSOne)
    │  auth · allowlist · validación I/O
    ▼
Domain facades / repositories existentes
    (Cash · Orders · OCC pulse · License · Sync · …)
```

### API mínima (Fase 0)

| Método | Rol |
|--------|-----|
| `listContexts()` | Contextos publicados |
| `listTools({context?})` | Catálogo de herramientas |
| `describeTool(toolId)` | Schema entrada/salida |
| `invoke(toolId, input, session)` | Ejecución controlada |

Respuestas siempre estructuradas (`OpsToolResult`: ok / rejected / error).  
Rechazo si: tool desconocido, input inválido, verbo no permitido, falta auth, riesgo alto sin autorización.

---

## 4. Contextos (namespace)

| Context ID | Dominio |
|------------|---------|
| `caja` | Caja / arqueo |
| `turnos` | Cash Shift / turno |
| `pedidos` | Order Domain / OpenTicket |
| `clientes` | Clientes |
| `inventario` | Stock |
| `productos` | Catálogo |
| `ventas` | Sale ledger |
| `dispositivos` | Provisioning / 2.6 |
| `dashboard` | Pulso ejecutivo (enlaces OCC Hoy) |
| `occ` | Centro de Control |
| `reportes` | Informes históricos (solo consultar/analizar) |
| `telemetria` | Sync · errores · salud |
| `licencias` | License snapshot |

---

## 5. Verbos (herramientas)

Toda herramienta se nombra: `{contexto}.{verbo}[.{recurso}]`

Verbos canónicos:

| Verbo | Naturaleza | Riesgo típico |
|-------|------------|---------------|
| `consultar` | Lectura | Bajo |
| `analizar` | Lectura agregada / señales | Bajo–medio |
| `crear` | Alta | Medio–alto |
| `actualizar` | Modificación | Medio–alto |
| `cancelar` | Lifecycle | Alto |
| `cerrar` | Lifecycle (turno, pedido) | Alto |
| `abrir` | Lifecycle (turno, ticket) | Medio |

**Reportes** y **telemetría**: preferir solo `consultar` / `analizar` en V1.

---

## 6. Fases

| Fase | Contenido | Estado |
|------|-----------|--------|
| **0** | ADR + catálogo + registry Dart + `invoke` stub / 1–2 tools lectura | **Cerrada** |
| **1** | Wire `consultar`/`analizar` a OCC, turnos, sync, licencia, caja, dispositivos, ventas | **Cerrada** |
| **2** | Verbos de escritura con auth (abrir/cerrar caja, cancelar pedido) | **Cerrada** |
| **3** | Transporte remoto (HTTP/MCP) cuando EasyAI/EN1 congelados | Pendiente |

---

## 7. Consecuencias

- EasyAI **nunca** recibe un handle a Isar.  
- Nuevos dominios (KDS, Delivery) = nuevos contextos/tools, no tablas.  
- UI OCC y Connector comparten señales (p. ej. `OccPulse`) vía dominio, no vía pantallas.  
- No desplaza E2E P0 ni inventa contrato EN1 EasyAI.

---

## 8. Criterio de aceptación Fase 0

- [x] ADR-017  
- [x] Catálogo contextos + tools  
- [x] `OperationsConnector` + registry en código  
- [x] ≥1 tool lectura real inyectable (`occ.consultar.pulso` con loader)  
- [x] Suite que demuestre rechazo sin acceso a tablas  

## 9. Criterio de aceptación Fase 1

- [x] `operationsConnectorProvider` inyecta loaders de dominio  
- [x] Tools Wire: OCC, dashboard, turnos, caja (consultar/analizar), dispositivos, telemetría, licencias, pedidos abiertos, ventas hoy, reportes disponibles  
- [x] Sin acceso a tablas; escrituras siguen stub + auth gate  
- [x] Suite ampliada (12 tests)  

## 10. Criterio de aceptación Fase 2

- [x] `OpsAuth` — PIN local/EN1 o sesión POS → `OpsInvokeSession.authorized`  
- [x] Gate: escritura sin auth → `authorization_required`; sin actor → `actor_required`  
- [x] Wire: `caja.abrir` / `caja.cerrar` · `turnos.abrir` / `turnos.cerrar` · `pedidos.cancelar`  
- [x] Lecturas extra: `turnos.consultar.historial` · `pedidos.consultar.por_id`  
- [x] Suite (12+ tests) con caminos auth  
