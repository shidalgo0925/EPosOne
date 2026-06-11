# ePosOne - POS Android Flutter Offline-First

Sistema de Punto de Venta (POS) para Android, desarrollado en Flutter con arquitectura offline-first. Ideal para pequeños negocios que necesitan facturar sin depender de conexión a internet.

---

## 🏢 Negocio de Prueba: Burger Express

**Datos configurados:**
- **Nombre:** Burger Express
- **Dirección:** Vía España, Panamá
- **Teléfono:** 6000-1234
- **Moneda:** Balboa (B/.)
- **Impuesto:** ITBMS 7%
- **Caja inicial:** B/. 100.00

---

## 📦 Productos Precargados (4)

| # | Producto | Precio | Stock | SKU | Código de barras |
|---|----------|--------|-------|-----|------------------|
| 1 | Hamburguesa Clásica | B/. 5.50 | 100 | HAM-001 | 123456789001 |
| 2 | Hot Dog Sencillo | B/. 3.00 | 150 | HOT-001 | 123456789002 |
| 3 | Papas Fritas Medianas | B/. 2.50 | 80 | PAP-001 | 123456789003 |
| 4 | Refresco 12oz | B/. 1.50 | 200 | REF-001 | 123456789004 |

---

## 🏗️ Arquitectura

```
lib/
├── src/
│   ├── app.dart                    # App principal (MaterialApp)
│   ├── main.dart                   # Punto de entrada
│   │
│   ├── core/
│   │   ├── database/
│   │   │   ├── database_provider.dart   # Provider de Isar DB
│   │   │   └── seed_data.dart           # Datos de prueba
│   │   ├── entities/
│   │   │   └── sync_entity.dart         # Entidad base con sync
│   │   └── router/
│   │       └── app_router.dart          # Configuración de rutas (go_router)
│   │
│   ├── features/
│   │   ├── cash_register/         # Módulo de caja
│   │   ├── customers/             # Módulo de clientes
│   │   ├── home/                  # Dashboard principal
│   │   ├── pos/                   # Punto de venta (vender)
│   │   ├── products/              # Productos y categorías
│   │   ├── sales/                 # Historial de ventas
│   │   └── settings/              # Configuración del negocio
│   │
│   └── widgets/                   # Widgets reutilizables
```

---

## 🛠️ Tecnologías

| Tecnología | Versión | Uso |
|------------|---------|-----|
| Flutter | 3.27.0 | Framework UI |
| Dart | 3.6.0 | Lenguaje |
| Isar | 3.1.0+1 | Base de datos local |
| Riverpod | 2.5.0 | Gestión de estado |
| Go Router | 14.0.0 | Navegación |
| PDF | 3.10.0 | Generación de recibos |
| Printing | 5.12.0 | Impresión de recibos |

---

## 🚀 Instalación y Ejecución

### Requisitos
- Flutter SDK 3.27.0+
- Android SDK (API 21+)
- Android Studio (opcional, para emulador)

### Comandos

```bash
# Instalar dependencias
flutter pub get

# Regenerar archivos .g.dart (generados automáticamente)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Verificar errores
flutter analyze

# Ejecutar en celular conectado
flutter run

# Compilar APK debug
flutter build apk --debug

# Compilar APK release
flutter build apk --release
```

---

## 📂 Ubicación del APK Generado

```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## 🧪 Datos de Prueba

Los datos de prueba se insertan automáticamente al abrir la app por primera vez. Se encuentran en:

```
lib/src/core/database/seed_data.dart
```

**Contenido del seeding:**
- Configuración del negocio (Burger Express)
- 1 categoría: "Combos y Acompañamientos"
- 4 productos con precios y stock
- 1 cliente genérico ("Cliente Ocasional")
- 1 caja abierta con B/. 100.00

---

## 🔧 Correcciones Aplicadas

### Errores corregidos para compilar:

1. **Enums sin `@enumerated`** → Agregado `@enumerated` de Isar a `SyncStatus`, `CashRegisterStatus`, `PaymentMethod`, `SaleStatus`
2. **`.future` en `AsyncValue<Isar>`** → Cambiado a `await ref.read(databaseProvider.future)`
3. **`app_router.g.dart` faltante** → Eliminado `part 'app_router.g.dart'` (Provider simple)
4. **`CardTheme` vs `CardThemeData`** → Cambiado a `CardThemeData` (Flutter 3.27 API)
5. **`categories` no existe en Isar** → Cambiado a `categorys` (pluralización de Isar)
6. **Type errors** → `num`→`double`, `FutureOr<double>`, `String?`→`String`
7. **`compileSdkVersion` plugins** → Actualizado a 36 en `isar_flutter_libs` y `printing`
8. **Namespace faltante** → Agregado `namespace` en `isar_flutter_libs`

---

## 📱 Funcionalidades

- ✅ Punto de venta (POS) con carrito de compras
- ✅ Gestión de productos con stock
- ✅ Gestión de categorías
- ✅ Gestión de clientes
- ✅ Caja registradora (apertura/cierre)
- ✅ Historial de ventas
- ✅ Recibos con número correlativo
- ✅ Configuración del negocio
- ✅ Base de datos local offline (Isar)
- ✅ Sincronización lista para implementar

---

## 👤 Autor

**Easy Technology Services**

Desarrollado para pequeños negocios en Panamá.

---

## 📄 Licencia

Proyecto privado - Easy Technology Services.
