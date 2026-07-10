# EPosOne

Sistema POS offline-first para pequeños negocios (Panamá). App Flutter en la carpeta `eposone/`.

**Producto independiente** del ecosistema EasyNodeOne · **Una sola APK** · **POS Core Protegido**.

## Documentación

- **[Contexto de la app (jul 2026)](EPOSONE_APP_CONTEXT.md)** — arquitectura congelada, Core Protegido, capa Plataforma, qué no tocar
- [Master Plan V3](EPOSONE_MASTER_PLAN_V3.md) — roadmap comercial y EN1
- [README de la app](eposone/README.md) — instalación y estructura
- [Revisión de arquitectura](EPOSONE_ARCHITECTURE_REVIEW.md)
- [Paridad vs Loyverse](EPOSONE_vs_LOYVERSE.md)

## Inicio rápido

```bash
cd eposone
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Requisitos

- Flutter SDK 3.27+
- Android SDK (API 21+)
