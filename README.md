# EPosOne

Sistema POS offline-first para pequeños negocios (Panamá). App Flutter en la carpeta `eposone/`.

## Documentación

- [README de la app](eposone/README.md) — instalación, arquitectura y funcionalidades
- [Revisión de arquitectura](EPOSONE_ARCHITECTURE_REVIEW.md) — auditoría técnica y roadmap
- [Paridad vs Loyverse](EPOSONE_vs_LOYVERSE.md) — matriz de funcionalidades, gaps y backlog L1–L6

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
