# Hito 2.5 — Spec funcional Cajeros POS (v1)

**Fecha:** 18 jul 2026  
**Par:** [`EN1_EPOSONE_HITO25_CASHIER_CONTRACT.md`](EN1_EPOSONE_HITO25_CASHIER_CONTRACT.md)  
**Estado:** Borrador alineado al contrato; Prog2 implementa UI/local **solo tras** handoff OFICIAL.

---

## Actores

| Actor | Rol |
|-------|-----|
| Cajero | Contact `is_cashier`; opera POS con PIN; no es User EN1 |
| Supervisor / admin BO | Excepciones de turno, cambio de cajero, set PIN, auditoría |
| Dispositivo | Ya provisionado a una Caja |

---

## Historias

1. Como cajero, descargo el catálogo de cajeros con el bootstrap y elijo mi nombre.  
2. Ingreso PIN; si es correcto, abro o continúo el turno sin internet.  
3. Veo siempre Caja · Cajero · Turno en cabecera.  
4. Cada pedido, pago y movimiento queda con mi `cashier_contact_id`.  
5. Si EN1 me desactiva, al sincronizar el POS me bloquea y pide otro cajero.  
6. Si el BO cambia el cajero del turno, al sync veo aviso y adopto el remoto; mis ops previas no cambian de cajero.

---

## Reglas de negocio

- Un dispositivo ↔ una Caja (provisioning).  
- Un turno abierto ↔ un `cashier_contact_id` “actual” en EN1; ops locales pueden diferir en auditoría.  
- Login solo `is_active = true`.  
- PIN: ver contrato §1 (nunca plano en sync).

---

## Criterio de aceptación (E2E)

- [ ] Bootstrap trae cajeros  
- [ ] Login PIN offline  
- [ ] Abrir turno desde APK  
- [ ] Cabecera visible  
- [ ] Ops sync con `cashier_contact_id`  
- [ ] Inactivo / cambio BO según contrato  

---

*EasyTech · Spec funcional Hito 2.5 · 18 jul 2026*
