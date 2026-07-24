# ADR-007 — Licenciamiento Comercial SaaS (Caja, Offline Grace, Sync Attribute)

| Campo | Valor |
|-------|--------|
| **Estado** | Aprobado |
| **Fecha** | 18 de julio de 2026 |
| **Hito comercial** | Inicio etapa comercial EPosOne V1.0 |
| **Audiencia** | P1 (EN1) · P2 (EPosOne) · Producto |
| **Principio rector** | *La disciplina protege a la visión de la emoción del momento.* |
| **Relacionado** | EN1-02 provisioning · Hito 2 bootstrap · Hito 3 sync/orders · [`EPOSONE_EN1_DECISION_OPERATION_VS_ADMIN.md`](EPOSONE_EN1_DECISION_OPERATION_VS_ADMIN.md) · [`EPOSONE_EN1_TIMEZONE_CONTRACT_DELTA_REQUEST.md`](EPOSONE_EN1_TIMEZONE_CONTRACT_DELTA_REQUEST.md) |

---

## 1. Contexto

La fase técnica del POS (arquitectura, EN1, provisioning, bootstrap, sync, pedidos, pagos, offline) está suficientemente avanzada para operar.

El objetivo del proyecto **cambia**:

| Antes | Ahora |
|-------|--------|
| Construir el mejor POS | Convertir EPosOne en un **SaaS sostenible** |
| ¿Cómo programamos esto? | ¿Cómo cobramos miles de licencias años sin crecer admin? |

A partir del **18 jul 2026**, toda decisión técnica de producto debe favorecer **ingresos recurrentes, automatización y escalabilidad**.

---

## 2. Decisión

### 2.1 Objeto de la licencia

**La licencia pertenece a la Caja (register), no al usuario, correo ni dispositivo.**

Jerarquía (ya existente en EN1-02):

```
Organización → Sucursal → POS → Caja → Dispositivo(s)
```

El dispositivo **consume** la licencia de la Caja a la que está provisionado.

### 2.2 Trial

Todo cliente nuevo obtiene **45 días** automáticamente (sin vendedor, sin llamadas, sin soporte obligatorio).

### 2.3 Modelo de cobro / renovación

**Rechazado:** pago → código → ingresar en tablet → activar manual.

**Adoptado:**

```
Pago (Portal / pasarela)
    ↓
EN1 actualiza licencia de la Caja
    ↓
Tablet obtiene estado en el siguiente contacto Sync / Bootstrap / Heartbeat
```

Sin intervención humana. Sin códigos de activación como camino feliz.

Métodos de pago objetivo: tarjeta, Yappy, ACH; transferencia solo como excepción BO (no camino principal).

### 2.4 Distribución

La APK debe ser **pública** (descarga sin intervención de ventas).  
La activación comercial no depende de que Ventas envíe el binario.

### 2.5 Offline First (no negociable)

Internet **nunca** es requisito para vender.

Offline debe permitir: pedidos, cobro, abrir/cerrar caja, imprimir, seguir operando.

La licencia **no** se valida por cada venta.

### 2.6 Grace Offline Window

La tablet opera con una **ventana de confianza** tras la última validación exitosa con EN1 (p. ej. 30 días).

Dentro de la ventana: operación completa offline.  
Debe reconectar periódicamente para renovar autorización.

### 2.7 Licencia = atributo del protocolo (no proceso aparte)

**Principio:** la licencia nunca es un flujo independiente en el cajero.

Cualquier comunicación legítima con EN1 puede devolver / refrescar:

- estado de licencia  
- fecha de expiración  
- próxima validación requerida  
- (opcional) mensajes UX  

Canales candidatos (mismo envelope o extensión documentada): bootstrap, sync, pedidos, config, inventario, FE, updates, heartbeat.

### 2.8 Heartbeat

Cada contacto tablet→EN1 puede registrar: última conexión, versión app, estado, licencia.  
La tablet recibe licencia + expiración (+ config / `server_time` si aplica).  
**No** requiere un endpoint exclusivo “solo licencia” en el camino feliz del cajero.

### 2.9 Portal y métricas (EN1)

Portal Licencias (cliente): empresa, plan, vencimiento, historial, facturas, renovar.  
Dashboard comercial (ops): activas, trials, por vencer, vencidas, tablets sin conectar, última conexión, versión.

---

## 3. Consecuencias

### 3.1 Para P1 (EN1)

- Dominio **License Manager** (licencia anclada a Caja).  
- Portal comercial + pasarela + renovación post-pago automática.  
- Heartbeat / envelope de sync con estado de licencia.  
- Dashboard métricas comerciales.  
- Reglas anti-abuso de trial (org / Caja / device) — a especificar en contrato.  
- **Handoff obligatorio** a P2: contrato HTTP congelado + spec + ejemplos + changelog + tag (misma regla que Order Domain).

### 3.2 Para P2 (EPosOne)

- **License Store** local: estado, días restantes, última / próxima validación, grace.  
- UI mínima informativa (chip / Este dispositivo / avisos).  
- Consumir licencia desde respuestas EN1 existentes; **no** inventar llamadas solo-licencia.  
- Mantener offline completo; **no** bloquear ventas por ausencia temporal de Internet.  
- Política de escalones al vencer (aviso → restricciones online → bloqueo) = **spec conjunta**; no improvisar en APK.  
- **Prohibido** implementar payloads de licencia hasta contrato congelado de P1.

### 3.3 Fuera de alcance inmediato (P2)

- Portal de pago dentro de la tablet.  
- Ingreso de códigos de activación.  
- Validación online por ticket/venta.  
- Reabrir contratos Order / Provisioning / Bootstrap solo por licencia sin paquete handoff.

---

## 4. Alternativas rechazadas

| Alternativa | Motivo de rechazo |
|-------------|-------------------|
| Licenciar correo / usuario | Fácil abuso (otra cuenta = otro trial) |
| Licenciar solo dispositivo | Pierde el vínculo comercial Caja; reprovisioning confuso |
| Códigos manuales post-pago | No escala; carga admin |
| Cobro / activación por WhatsApp | No escala; no auditable |
| Validar licencia en cada venta | Rompe offline; fricción de caja |
| Endpoint dedicado obligatorio “check license” en cada arranque | Duplica tráfico; usuario percibe “activar”; peor UX |

---

## 5. Principios de implementación (checklist)

1. **Offline First** — vender no depende de Internet.  
2. **Licencia transparente** — el cajero no ejecuta un ritual de “validar licencia”.  
3. **Sincronización inteligente** — todo contacto EN1 puede refrescar licencia.  
4. **Automatización total** — cero activación / renovación manual en el happy path.  
5. **Escalabilidad SaaS** — diseñar para miles de Cajas, no decenas.  
6. **Disciplina de contratos** — P2 no inventa campos; espera handoff P1.

---

## 6. Criterios de aceptación (producto)

- [ ] Trial 45 días automático al alta de Caja / org según reglas EN1.  
- [ ] Pago en portal → licencia renovada en EN1 sin código.  
- [ ] Tablet actualiza estado en siguiente sync/bootstrap/heartbeat.  
- [ ] Offline completo dentro del Grace Window.  
- [ ] EPosOne muestra estado / días / última validación sin bloquear venta por falta puntual de red.  
- [ ] Dashboard EN1 con métricas comerciales básicas.  
- [ ] Contrato License + Sync envelope congelado y copiado a `Doc/` antes de cablear P2.

---

## 7. Estado de implementación

| Capa | Estado |
|------|--------|
| Visión / ADR | **Aprobado 18 jul 2026** |
| Contrato HTTP License (P1) | Pendiente handoff |
| License Store + UI (P2) | **V1.0 infra** — `Doc/EPOSONE_LICENSE_ENGINE_V1.md` · módulo `features/licensing/` · espera bloque `license` en bootstrap |
| Pasarela + Portal (P1) | Pendiente |
| Distribución APK pública (firma release / store) | Pendiente operativo |

---

*EasyTech · ADR-007 EPosOne Comercial · 18 jul 2026*
