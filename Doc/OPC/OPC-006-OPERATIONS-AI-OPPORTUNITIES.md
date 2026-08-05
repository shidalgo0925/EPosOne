# OPC-006 — Operations AI Opportunities

| Campo | Valor |
|-------|--------|
| **ID** | OPC-006 |
| **Padre** | [OPC-000](OPC-000-EPOSONE-OPERATIONS-CONNECTOR.md) |
| **Estado** | Oportunidades · **no diseñar IA** · **no integrar GPT** |
| **Fecha** | 5 ago 2026 |

---

## 1. Propósito

Identificar **casos de uso** donde EasyAI Core aportaría valor usando **solo** el Operations Connector.

EPOSOne **no** implementa estos casos. Solo publica Context / Tool / Event para que EasyAI los consuma.

---

## 2. Casos de uso

| # | Oportunidad | Pregunta de negocio | Context / Tools / Events | Valor |
|---|-------------|---------------------|--------------------------|-------|
| 1 | **Supervisor IA** | ¿Qué requiere atención ahora en este POS? | `occ.*`, `dashboard.*`, alertas | Priorizar acción humana |
| 2 | **Análisis de diferencias** | ¿Por qué descuadró la caja? | `caja.analizar.descuadre`, `CashShiftClosed`, movimientos | Explicar descuadre |
| 3 | **Resumen diario** | ¿Cómo cerró el día? | `ventas.analizar.resumen_hoy`, turnos, refunds | Briefing gerente |
| 4 | **Explicación de anomalías** | ¿Qué pasó con sync / bootstrap? | `telemetria.*`, `dispositivos.analizar.salud` | Diagnóstico sin logs crudos |
| 5 | **Predicción de ventas** | ¿Qué esperar mañana / hora pico? | Series ventas (Spec reportes) + eventos Order | Planificación (futuro datos) |
| 6 | **Recomendaciones** | ¿Abrir segundo cajero? ¿Reordenar stock? | pedidos abiertos, inventario Spec, atención | Sugerencias no vinculantes |
| 7 | **Alertas inteligentes** | Filtrar ruido vs alerta crítica | `occ.analizar.alertas` + umbrales EasyAI | Menos fatiga de alertas |
| 8 | **Licencia / continuidad** | ¿Riesgo de corte comercial? | `licencias.analizar.vencimiento` | Anticipar gracia/expiración |
| 9 | **Coach de cierre** | Checklist cierre de turno | `turnos.*`, caja, pedidos abiertos | Guiar cajero (EasyAI UI) |
| 10 | **Auditoría narrativa** | Relato de cancel/void/refund | OPC-003 Order* events | Cumplimiento / entrenamiento |

---

## 3. Límites (congelados)

| EasyAI puede | EasyAI **no** puede (vía EPOSOne) |
|--------------|-----------------------------------|
| Invocar tools allowlisted | Leer Isar / SQL |
| Razonar sobre resultados estructurados | Cambiar reglas de tax / totals / Order lifecycle |
| Pedir auth al host para escrituras | Bypass PIN / OpsAuth |
| Suscribir eventos cuando EIS lo permita | Inventar eventos de dominio |
| Vivir fuera del APK | Sustituir OCC o el flujo POS |

---

## 4. Priorización sugerida (para EasyAI / CODITO — no Local)

| Prioridad | Casos | Dependencia |
|-----------|-------|-------------|
| P0 | Supervisor IA · Alertas inteligentes · Licencia | Tools Wire ya existentes |
| P1 | Diferencias · Resumen diario · Anomalías sync | Mismos + historial turnos |
| P2 | Predicción · Recomendaciones stock | Series / inventario Spec + EIS transport |

---

## 5. Criterio S2

- [x] Oportunidades de la misión documentadas.  
- [x] Sin diseño de modelos / prompts / agentes.  
- [x] Trazabilidad a Context/Tool/Event.
