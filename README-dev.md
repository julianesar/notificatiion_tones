# Notifications Sounds - Guía de Desarrollo

## Configuración Inicial

### 1. Instalar Dependencias
```bash
flutter pub get
```

### 2. Ejecutar la Aplicación
```bash
flutter run
```

## Estructura del Proyecto

```
lib/
├── config/
│   └── app_config.dart          # Configuración global (baseUrl, cacheTtl)
├── core/
│   ├── network/
│   │   └── api_client.dart      # Cliente HTTP con caché y reintentos
│   └── theme/
│       └── app_theme.dart       # Temas Material 3
├── features/
│   ├── categories/
│   │   ├── data/
│   │   │   ├── datasources/     # Fuentes de datos remotas
│   │   │   ├── models/          # Modelos con serialización JSON
│   │   │   └── repositories/    # Implementación de repositorios
│   │   ├── domain/
│   │   │   ├── entities/        # Entidades del dominio
│   │   │   ├── repositories/    # Interfaces de repositorios
│   │   │   └── usecases/        # Casos de uso
│   │   └── presentation/
│   │       ├── pages/           # Pantallas UI
│   │       └── providers/       # Gestión de estado
│   └── tones/
│       └── ...                  # Misma estructura que categories
├── providers/
│   └── theme_provider.dart      # Provider para temas
├── screens/
│   └── main_screen.dart         # Pantalla principal con tabs
└── main.dart                    # Punto de entrada con DI
```

## Arquitectura

### Clean Architecture (3 Capas)
- **Presentation**: UI, Providers, Pages
- **Domain**: Entities, Use Cases, Repository Interfaces
- **Data**: Models, DataSources, Repository Implementations

### Gestión de Estado
- **Provider**: Para estado global y por feature
- **ChangeNotifier**: Para notificar cambios en la UI

### Caché y Red
- **ApiClient**: Caché local de 5 minutos con refresh en background
- **Timeout**: 8 segundos por request
- **Reintentos**: 1 reintento en errores 5xx o timeout

## Configuración de API

### Cambiar baseUrl
Editar `lib/config/app_config.dart`:

```dart
class AppConfig {
  final String baseUrl = 'https://tu-nueva-api.com';
  final Duration cacheTtl = const Duration(minutes: 5);
  // ...
}
```

### Endpoints Utilizados
- `GET /categories` - Lista de categorías
- `GET /categories/{id}/tones?limit={limit}&offset={offset}` - Tonos por categoría

## Comandos de Desarrollo

### Análisis Estático
```bash
flutter analyze
```

### Formateo de Código
```bash
dart format .
```

### Tests (si se implementan)
```bash
flutter test
```

### Build para Producción
```bash
flutter build apk --release
```

## Características Técnicas

### Performance
- Widgets `const` para elementos estáticos
- `ListView` con `addAutomaticKeepAlives: false`
- `notifyListeners()` solo cuando cambian datos
- Paginación inteligente con offset por categoría

### UX
- Pull-to-refresh en listas
- Botones "Cargar más" con indicadores
- Estados de carga, error y vacío
- Caché transparente con refresh en background
- Material 3 con tema claro/oscuro

### Estructura de Datos
```dart
// Category
{
  "id": "string",
  "title": "string"
}

// Tone
{
  "id": "string", 
  "title": "string",
  "url": "string",
  "attribution_text": "string?",
  "requires_attribution": boolean
}
```

## Notas de Desarrollo

- El caché se refresca automáticamente cuando está al 75% de su TTL
- Los providers previenen cargas simultáneas de la misma categoría
- La navegación usa `MaterialPageRoute` estándar
- Los errores muestran UI consistente con botones de reintento