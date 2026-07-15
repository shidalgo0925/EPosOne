# Roadmap EN1 + EPosOne V5

**Actualizado:** 15 jul 2026  
**Cierre de sesión P2:** UX-01 + Hito 3B.1 operación · cliente Sync listo · E2E checklist pendiente

| Hito | Estado | Quién |
|------|--------|-------|
| 1 Provisioning | ✅ | |
| 2 Bootstrap | ✅ | |
| 3A Dominio + Contrato | ✅ | P1 |
| 3B Operación Flutter | ✅ (cliente) | P2 |
| UX-01 + 3B.1 Operación Pedido | ✅ | P2 |
| **3C Sync** | 🟡 Cliente listo · E2E/pruebas en tablet | P2 ejecuta checklist · P1 verifica BO |
| 4 Inventario | ⏸ hasta Sync E2E OK | |

## Hecho en P2 (cierre 15 jul 2026)

### Order Domain (Hito 3B / cliente 3C)
- Pedidos EN1: crear / guardar / modificar / cobrar / anular / cerrar sobre contrato congelado.
- Cobro POS → Order Domain (`createPaidOrderFromPosSale`); ticket abierto puede enlazar `linkedOrderLocalId`.
- Push legacy **Sale** desactivado: no se encola, no ensucia historial; mensaje apunta a Pedidos EN1.
- `dirty` en `Order`: true al modificar; false tras sync OK.
- Cola Order + `flushPendingToEn1` + sync inmediato en eventos de ciclo de vida.
- Auto-sync cada 30 s solo si hay trabajo pendiente y hay enlace EN1.
- Chip estado EN1 en POS (conectado / offline / sincronizando + pendientes).
- Overlay bloqueante en guardar pedido; cierre automático hoja Tickets + snackbar.
- Cola Sync UI: Pendientes · Sincronizando · Completado · Error (errores no se borran solos).

### Bootstrap / catálogo
- Páginas POS **Comida** / **Bar** reconstruidas desde categorías EN1.
- `isActive` robusto (Activo/Inactivo ES/EN).
- Handoff menú Istmo Brew para import en EN1: `Doc/EN1_HANDOFF_ISTMO_MENU/` (+ `tools/export_istmo_catalog_for_en1.py`).

### Contratos (fuente única — no reabrir)
- `Doc/EN1_EPOSONE_HITO3_ORDER_HTTP_CONTRACT.md`
- `Doc/EN1_EPOSONE_ORDER_DOMAIN_SPEC_V1.md`
- Regla handoff: `.cursor/rules/en1-handoff.mdc` · `Doc/EPOSONE_EN1_HANDOFF_RULE.md`

## Pendiente inmediato (cierre Hito 3C)

1. **Checklist E2E en tablet** (happy path, ciclo de vida, offline, idempotencia, reinicio, errores, UX).
2. Confirmación P1: pedidos visibles en BackOffice EN1 sin duplicados.
3. Diagnóstico: versión APK, contrato, último sync, pendientes, token/caja/dispositivo.
4. Limpieza técnica previa a piloto (logs temporales, flags muertas).
5. **Congelar POS Core** solo tras 3C E2E OK — sin nuevas pantallas/flujos.

## No implementar aún
Inventario · Kardex · Recetas · Compras · Transferencias · Facturación · CxC · KDS · Menú QR · Delivery · Fidelización · Multi-POS · Licencias.

## Referencias de estado
- `Doc/EPOSONE_EN1_HITO3B1_UX01_STATUS.md`
- `Doc/EPOSONE_EN1_HITO3B_HANDOFF_STATUS.md`
- `Doc/EPOSONE_EN1_INTEGRATION_LOG.md`
