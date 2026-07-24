# Contrato de Impresión / Recibo EPosOne V1

| Campo | Valor |
|-------|--------|
| **Estado** | Borrador — revisión Analista / P1 / P2 |
| **Fecha** | 19 jul 2026 |
| **Versión** | v1.0-draft |
| **Roadmap** | [`EPOSONE_EN1_ROADMAP_V6.md`](EPOSONE_EN1_ROADMAP_V6.md) |
| **Depende de** | Modelo Comercial · Tax · Tip · Pagos |
| **Archivo** | `Doc/EPOSONE_PRINT_CONTRACT_V1.md` |
| **Siguiente (V6)** | Fase 3 — Spec Motor Comercial |
| **Alcance** | Plantilla por secciones + snapshot de impresión. **Sin** driver ESC/POS ni payloads PAC. |

---

## 1. Propósito

Definir **qué** se imprime y en **qué orden lógico**, no un layout pixel-perfect único.

El recibo es una **plantilla por secciones**: cada sección se activa o no según:

- Tipo de documento (recibo, factura, cotización, nota de crédito, cuenta…).
- Política de impresión de la empresa/sucursal/caja.
- Datos disponibles (cliente, fiscal, QR, mesa…).

Mismo contrato en Standalone e Integrado; solo cambia el origen de la política y de los datos maestros.

---

## 2. Principios

| # | Regla |
|---|--------|
| 1 | No hay “un recibo fijo panameño copiado”; hay **estructura funcional** reutilizable. |
| 2 | Los renderers (texto 58/80 mm, PDF, pantalla) **solo consumen un snapshot**; no recalculan totales. |
| 3 | Impuestos en desglose = **solo los aplicados** (Contrato Fiscal). |
| 4 | Propina **separada** de impuestos (Contrato Propinas). |
| 5 | Pagos = **una línea por tender** (Contrato Pagos). |
| 6 | Reimpresión usa el mismo snapshot (marcar `copy` / `reprint`). |
| 7 | Dual-mode: política local o sync EN1. |

---

## 3. Política de impresión

### 3.1 Datos generales

| Campo | Descripción |
|-------|-------------|
| Nombre / Código | Ej. `RCPT-REST-80`. |
| Activo / Vigencia / Versión | Como otras políticas. |
| Ancho papel | `58mm` · `80mm` (default 80). |
| Idioma | `es` (default) · extensible. |
| Logo | URL/path; mostrar sí/no. |
| Secciones habilitadas | Lista ordenada (§5). |
| QR | Modo y fuente (§5.8). |
| Mensajes | Header comercial, footer, promo, leyenda fiscal, política de devolución. |

### 3.2 Scope

Empresa → Sucursal → Caja (impresora/gaveta pueden ser de caja).

### 3.3 Origen

| Modo | Edición | Aplicación |
|------|---------|------------|
| Standalone | Admin local | Renderer local |
| Integrado | EN1 BO | Snapshot + sync de política |

---

## 4. Tipos de documento

| Tipo | Uso |
|------|-----|
| `sale_receipt` | Recibo de venta cobrada (default POS). |
| `fiscal_invoice` | Factura / FE (cuando exista emisión). |
| `credit_note` | Nota de crédito / reembolso. |
| `quote` | Cotización (sin cobro). |
| `bill_preview` | Cuenta / pre-cuenta (no fiscal). |
| `shift_report` | Fuera de V1 mínimo de venta (caja). |

Cada tipo tiene un set default de secciones; la política puede sobreescribir.

---

## 5. Secciones (motor de plantilla)

Orden canónico sugerido. Si una sección está OFF o sin datos, se omite (no deja hueco vacío ruidoso).

### 5.1 Encabezado comercio

| Campo | Origen típico |
|-------|----------------|
| Logo | Política / config |
| Nombre comercial | Empresa |
| Razón social | Empresa |
| Sucursal | Sucursal |
| RUC | Empresa |
| Dirección | Sucursal / empresa |
| Teléfono | Opcional |

### 5.2 Contexto operativo

| Campo | Origen |
|-------|--------|
| Caja | Caja (nombre/código) |
| Cajero | Sesión / snapshot |
| Turno | Turno abierto |
| Fecha y hora | Hora local negocio (política timezone) |
| Nº recibo | Secuencia local / fiscal |
| Nº pedido | Pedido EN1 o local |
| Punto de facturación | Si fiscal listo |

### 5.3 Cliente

| Caso | Impresión |
|------|-----------|
| Contado | `CLIENTE CONTADO` (o equivalente de política) |
| Registrado | Nombre, RUC/Cédula, Teléfono (opc.) |

### 5.4 Pedido (hospitality / food truck)

| Campo | Cuándo |
|-------|--------|
| Mesa / etiqueta | Restaurante |
| Nº pedido | Siempre si existe |
| Mesero | Si hay atribución |

### 5.5 Detalle de líneas

Columnas lógicas (el renderer adapta al ancho):

| Columna | Contenido |
|--------|-----------|
| Cantidad | Qty |
| Unidad | und, kg, L… |
| Descripción | Nombre + modificadores |
| Precio unitario | |
| Descuento línea | Si &gt; 0 |
| Impuesto(s) | Código/monto o tasa según espacio |
| Importe | Total de línea |

Multi-impuesto por línea: si no cabe en una fila, segunda línea de detalle fiscal.

### 5.6 Resumen comercial

```text
Subtotal
Descuentos
Base gravable   (si aplica)
Recargos        (fase posterior; omitir si 0)
Propina         (separada)
TOTAL
```

### 5.7 Resumen fiscal (dinámico)

Solo impuestos aplicados del snapshot Tax:

```text
ITBMS 7%     x.xx
ISC Licor    y.yy
```

No imprimir filas fijas 7/10/15 en cero “por costumbre”, salvo que la política fiscal de impresión lo exija explícitamente.

### 5.8 Pagos

```text
Métodos de pago:
  Efectivo    20.00
  Visa        50.00
Cambio         2.00   ← solo si > 0
```

Referencias: según política (ocultar / últimos dígitos / completa).

### 5.9 QR

| Modo QR | Contenido |
|---------|-----------|
| `none` | No imprimir |
| `receipt_lookup` | URL/consulta del recibo |
| `en1_verify` | Verificación EN1 |
| `fiscal_fe` | URL/CUFE FE Panamá (cuando exista) |
| `custom` | Payload configurado |

Si no hay dato (ej. FE pendiente): omitir QR o imprimir leyenda “Documento no fiscal / pendiente” según tipo.

### 5.10 Pie

- Mensaje de agradecimiento / footer config.
- Promoción.
- Política de devolución.
- Leyendas fiscales.
- Redes / web (opc.).
- Marca de reimpresión / copia.

---

## 6. Snapshot de impresión (DTO lógico)

Inmutable. Generado al cobrar (o al emitir NC). Los builders **no** vuelven a calcular.

Contiene al menos:

1. Identidad documento: tipo, ids venta/pedido, versión contrato impresión, `is_reprint`.
2. Emisor: empresa, sucursal, RUC, dirección, caja.
3. Operador: cajero, turno, fecha/hora local.
4. Cliente snapshot.
5. Líneas + impuestos por línea.
6. Totales comerciales + desglose fiscal + propina.
7. Tenders[] + cambio.
8. QR payload (si aplica).
9. Mensajes / pie.
10. Referencias fiscales (número, CUFE, auth) si existen.

**Gap actual:** los builders reciben `Sale` plano; post-freeze deben recibir este snapshot (ensamblado desde Sale + items + customer + tenders + fiscal + turno).

---

## 7. Reglas de render

| Tema | Regla |
|------|--------|
| Ancho | 58 vs 80: mismo snapshot; distinto wrapping. |
| Paridad | Texto térmico y PDF deben mostrar las mismas secciones y montos. |
| Moneda | Símbolo de la empresa. |
| Redondeo visual | Igual al snapshot (no re-redondear). |
| Fallbacks | Sin cliente → Contado. Sin turno → omitir o “—”. Sin logo → solo texto. |
| Elegibilidad | Recibo de venta: tras cobro confirmado. FE: según estado fiscal (pendiente/aceptada) — política decide si imprime antes de aceptación. |

---

## 8. Hardware (declarativo)

La política / config de caja puede declarar:

- Impresora (tipo, ancho).
- Gaveta (abrir si hay `cash`).
- No obliga implementación aquí; el contrato exige el **gancho** de configuración.

---

## 9. Dual Mode

| | Standalone | Integrado |
|---|------------|-----------|
| Textos empresa/logo | Local | EN1 |
| Secuencias recibo | Local | Local y/o fiscal EN1 |
| QR EN1 / FE | N/A o limitado | Disponible según módulos |

---

## 10. Fuera de alcance V1

- Driver específico de cada impresora.
- Diseño gráfico marketing.
- PAC real / CUFE real (solo hueco de sección).
- KDS / comandas de cocina (documento distinto).

---

## 11. Criterios de aceptación

1. Plantilla por secciones activables.  
2. Snapshot inmutable obligatorio.  
3. Fiscal dinámico; propina separada; tenders N líneas.  
4. Caja · Cajero · Turno en encabezado operativo.  
5. Cliente contado vs registrado.  
6. QR configurable.  
7. Dual-mode y tipos de documento definidos.

---

## 12. Decisiones abiertas

1. ¿Imprimir FE pendiente con leyenda o bloquear? **Propuesta: leyenda configurable; default permitir recibo comercial.**  
2. ¿58 mm omitir columnas Impuesto en detalle y dejar solo resumen? **Propuesta: sí.**  
3. ¿Logo solo PDF o también térmico? **Propuesta: PDF sí; térmico según capacidad.**

---

## Changelog

| Fecha | Cambio |
|-------|--------|
| 2026-07-19 | Borrador V1: política, tipos, secciones, snapshot, render, QR, dual-mode. |
