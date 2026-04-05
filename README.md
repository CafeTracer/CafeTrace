# CaféTrace – App Móvil

Sistema de trazabilidad postcosecha de café para pequeños productores.
**Proyecto Integrador III · UPB 2026 · Hernández & Osorio**

---

## Arquitectura

```
lib/
├── core/
│   ├── constants/     # AppConstants — URL base, keys, paginación
│   ├── errors/        # AppError — jerarquía de errores del dominio
│   ├── network/       # ApiClient — Dio + interceptores JWT y errores
│   ├── router/        # GoRouter — navegación + guards de autenticación
│   └── theme/         # AppTheme — Material Design 3, paleta CaféTrace
├── domain/
│   ├── entities/      # Entidades puras (Usuario, Lote, Registro, etc.)
│   └── repositories/  # Interfaces abstractas (contratos)
├── infrastructure/
│   ├── models/        # Modelos JSON → entidades
│   └── repositories/  # Implementaciones HTTP concretas
├── application/
│   └── providers/     # Riverpod providers — estado global
└── presentation/
    ├── screens/       # Pantallas organizadas por feature
    └── widgets/       # Widgets reutilizables
```

**Regla clave**: cada capa solo depende de la que está por encima de ella.
- `presentation` → `application` → `domain` ← `infrastructure`
- Para cambiar el backend: solo modificar `infrastructure/`
- Para cambiar la UI: solo modificar `presentation/`
- Para agregar un feature: agregar entidad en `domain/`, impl en `infrastructure/`, provider en `application/`, pantalla en `presentation/`

---

## Setup inicial

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Generar código (modelos Freezed y providers Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 3. Correr en emulador Android
flutter run
```

## Cambiar URL del backend

Editar **una sola línea** en `lib/core/constants/app_constants.dart`:

```dart
// Desarrollo local (emulador Android):
static const String baseUrl = 'http://10.0.2.2:8000';

// Producción (EC2):
static const String baseUrl = 'https://{elastic-ip}';
```

## Pantallas implementadas

| ID  | Pantalla                   | Rol              |
|-----|----------------------------|------------------|
| P01 | Login                      | Todos            |
| P02 | Dashboard                  | Productor / Admin|
| P03 | Lista de lotes             | Productor / Admin|
| P04 | Crear / Editar lote        | Productor        |
| P05 | Detalle lote + Timeline    | Productor / Admin|
| P06 | Registrar actividad        | Productor        |
| P07 | Reporte de trazabilidad    | Productor / Admin|
| P08 | Fincas                     | Productor        |
| P09 | Registrar finca            | Productor        |
| P10 | Perfil                     | Todos            |
| P11 | Gestión de usuarios        | Admin            |
| P12 | Crear usuario              | Admin            |

## Dependencias principales

| Paquete                   | Propósito                        |
|---------------------------|----------------------------------|
| `flutter_riverpod`        | Estado global (providers)        |
| `go_router`               | Navegación declarativa + guards  |
| `dio`                     | HTTP client con interceptores    |
| `flutter_secure_storage`  | JWT en almacenamiento seguro     |
| `intl`                    | Formateo de fechas               |

## Notas de desarrollo

- El emulador Android accede al localhost del PC en `10.0.2.2`
- El archivo `.env` nunca va al repositorio (está en `.gitignore`)
- Los catálogos (variedades, estados, tipos de actividad) se cargan una vez y quedan cacheados por Riverpod
- Los providers de familia (`registrosProvider(idLote)`) crean estado independiente por lote
