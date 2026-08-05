# EPosOne — Cierre de entrega Prog2 (5 ago 2026)

| Campo | Valor |
|-------|--------|
| **Estado** | **CERRADO en ingeniería** — pruebas E2E en tablet **por Ops** (no bloquean este cierre) |
| **Fecha** | 5 de agosto de 2026 |
| **Rama** | `master` @ **`cc9b0de`** |
| **APK** | `eposone/build/app/outputs/flutter-apk/app-release.apk` (~92.6 MB, build 5 ago 01:30) |

---

## Qué se entrega (código + docs)

| Paquete | Commit / ref | Notas |
|---------|--------------|--------|
| Discount Domain V1 Fase A+B | `5f131da` → `cf0320d` | Resolver, Isar, PIN, recibo, % libre deprecado |
| Hito 2.6 diagnóstico | `ca50112` | APK version real, cola, errores bootstrap/sync |
| Ownership + Dual Mode | `1a4aac6` | Matrices V1 |
| ADR-016 OCC + inventario | `e54f04a` | Principio OCC ≠ reportes |
| OCC Fase A (UI) | `edf7264` · cierre ADR `cc9b0de` | Centro de Control / Hoy |

## Fuera de este cierre (siguen vivos)

| Ítem | Owner |
|------|--------|
| E2E Hito 2.5 **C–E** en tablet | Ops / Prog2 QA |
| B9–B11 desactivar cajero EN1 | BO EN1 + Ops |
| OCC Fase B–D | GO futuro |
| Discount Fase C (HTTP EN1) | Contrato P1 congelado |
| Políticas V6 en 2.6 | Post-freeze comercial |

## Pruebas

Se **realizarán** con la APK de este cierre.  
Resultados → [`EPOSONE_E2E_HITO25_RUN_LOG.md`](EPOSONE_E2E_HITO25_RUN_LOG.md) · checklist [`EPOSONE_E2E_CHECKLIST_HITO25_V1.md`](EPOSONE_E2E_CHECKLIST_HITO25_V1.md).

**No** se declara Hito 2.5 certificado hasta evidencia C–E OK.

## Cómo instalar

1. Desinstalar APK anterior (prueba limpia si aplica).  
2. Instalar `app-release.apk` de esta entrega.  
3. Ejecutar bloque C (y luego D/E) según checklist.

## Firma cierre ingeniería

| Rol | Fecha | OK |
|-----|-------|----|
| Prog2 (código + docs) | 5 ago 2026 | ✅ |
| Ops / E2E tablet | | Pendiente pruebas |
