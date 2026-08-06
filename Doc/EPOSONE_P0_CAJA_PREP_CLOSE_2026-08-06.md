# EPOSOne — Cierre P0.1 Caja (preparación)

| Campo | Valor |
|-------|--------|
| **Fecha** | 6 ago 2026 |
| **Módulo** | Caja — apertura / cierre / arqueo |
| **Commit** | `ecf86d0` |
| **Estado** | **PREPARACIÓN CERRADA** · certificación funcional en tablet **ABIERTA** |

## Qué se cierra aquí

Entrega LOCAL de **instrumentación de certificación** (no el pass operativo del cajero):

| Entrega | Path |
|---------|------|
| Roadmap P0 | [`EPOSONE_P0_CERT_ROADMAP_V1.md`](EPOSONE_P0_CERT_ROADMAP_V1.md) |
| Checklist 20 casos | [`EPOSONE_P0_CAJA_CERT_CHECKLIST_V1.md`](EPOSONE_P0_CAJA_CERT_CHECKLIST_V1.md) |
| Log ETS | [`ETS_VALIDACION_CAJA_SPRINT_LOG.md`](ETS_VALIDACION_CAJA_SPRINT_LOG.md) |
| Unit `expectedCash` | `eposone/test/features/cash_register/shift_summary_test.dart` (3 tests) |

## Qué NO se cierra

- Pasada manual casos 1–20 en tablet (log ETS sin rellenar).
- Criterio ETS de módulo: *jornada fluida de cajero*.
- Sync Cash Shift EN1 / offline (casos 19–20) como certificado.
- Módulos P0 siguientes (pedidos, cancel/anular/dev, sync, licencia, Mexican Food).

## Fuera de alcance (confirmado)

- EasyAI / EIS / Gate 0 (sigue bloqueado hasta paquete en repo).
- P2 comercialización.

## Siguiente

1. Ejecutar checklist en APK release → rellenar [`ETS_VALIDACION_CAJA_SPRINT_LOG.md`](ETS_VALIDACION_CAJA_SPRINT_LOG.md).  
2. Si pass → **cierre funcional** del módulo Caja.  
3. Entonces P0 #2 Pedidos + recibos.

## Sign-off preparación

| Rol | Firma |
|-----|-------|
| LOCAL | Preparación P0.1 Caja **cerrada** (`ecf86d0`) |
| Certificación funcional | **Pendiente** (tablet) |
