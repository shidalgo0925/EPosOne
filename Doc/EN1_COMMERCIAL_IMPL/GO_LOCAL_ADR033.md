# GO LOCAL — ADR-033 (Asistente Standalone)

| Campo | Valor |
|-------|--------|
| **Fecha** | 7 ago 2026 |
| **GO** | **LOCAL — ADR-033** (explícito) |
| **Gate** | `EN1_COMMERCIAL_IMPLEMENTATION_GATE.md` **LIBERADO** |
| **ADR** | [ADR-033 v1.2 ACCEPTED](ADR-033-STANDALONE-ONBOARDING-ASSISTANT.md) |
| **Antecedentes** | ADR-031 · ADR-032 · ADR-035 (consumo mínimo de claims) |
| **Fuente EN1** | commit `e3b597e` / `dda8f26` · Easy-NodeOne |

## Alcance de esta fase (LOCAL)

1. Importar pack documental comercial.  
2. Activación: `POST /api/v1/activation/redeem` → claims (`modality`, etc.).  
3. Si `modality=standalone` → **no** Register/Bootstrap Connected.  
4. Asistente local hasta **READY_TO_SELL** + draft/reanudación.  
5. Puente legacy: códigos de provisioning siguen yendo a Connect (Connected / transición).  

## Fuera de esta fase

- ADR-034 Connected completo.  
- Emisión de tokens (CODITO).  
- Refactor/borrado de Gate 2 legacy.  
- Deploy prod sin pedido explícito.  

## Criterio READY_TO_SELL (ADR-033 §6)

Activación Standalone OK · empresa · moneda/impuesto · ≥1 categoría · ≥1 producto · caja local · cajero admin+PIN · usuario finaliza.
