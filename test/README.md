# Tests

Esta carpeta contiene todos los tests de la aplicación, organizados siguiendo la misma estructura que el código fuente.

## 📁 Estructura de Tests

### 🔬 **Unit Tests**
Tests unitarios para lógica de negocio pura
```
test/unit/
├── core/                 # Tests para funcionalidades core
│   ├── network/         # Tests para cliente API
│   ├── storage/         # Tests para almacenamiento
│   ├── audio/           # Tests para funcionalidades de audio
│   ├── utils/           # Tests para utilidades
│   └── extensions/      # Tests para extensiones
└── features/            # Tests por feature
    ├── categories/      # Tests de casos de uso de categorías
    ├── sounds/          # Tests de casos de uso de sonidos
    ├── downloads/       # Tests de casos de uso de descargas
    ├── notifications/   # Tests de casos de uso de notificaciones
    └── settings/        # Tests de casos de uso de configuración
```

### 🧩 **Widget Tests**
Tests para componentes de UI individuales
```
test/widget/
├── shared/              # Tests de widgets compartidos
│   ├── common/         # Tests de widgets básicos
│   ├── audio/          # Tests de widgets de audio
│   └── forms/          # Tests de elementos de formulario
└── features/           # Tests de widgets por feature
    ├── categories/     # Tests de widgets de categorías
    ├── sounds/         # Tests de widgets de sonidos
    ├── downloads/      # Tests de widgets de descargas
    ├── notifications/  # Tests de widgets de notificaciones
    └── settings/       # Tests de widgets de configuración
```

### 🔗 **Integration Tests**
Tests de flujos completos end-to-end
```
test/integration/
├── user_flows/         # Flujos completos de usuario
│   ├── onboarding/    # Tests de onboarding
│   ├── browse_sounds/ # Tests de navegación y búsqueda
│   ├── download/      # Tests de descarga de sonidos
│   └── set_ringtone/  # Tests de configuración de tonos
├── api/               # Tests de integración con API
└── platform/          # Tests de funcionalidades específicas de plataforma
```

## 🛠️ Configuración de Tests

### Dependencias necesarias
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  test: ^1.24.0
  integration_test:
    sdk: flutter
```

### Helpers y Mocks
```
test/
├── helpers/
│   ├── test_helpers.dart        # Utilidades para tests
│   ├── mock_data.dart          # Datos de prueba
│   └── test_app.dart           # App wrapper para tests
└── mocks/
    ├── mock_repositories.dart   # Mocks de repositorios
    ├── mock_datasources.dart   # Mocks de fuentes de datos
    └── mock_services.dart      # Mocks de servicios
```

## 🎯 Estrategia de Testing

### 1. **Pirámide de Testing**
- **70%** Unit Tests (lógica de negocio, casos de uso)
- **20%** Widget Tests (componentes UI)
- **10%** Integration Tests (flujos completos)

### 2. **Coverage Target**
- Mínimo 80% de cobertura de código
- 100% para casos de uso críticos
- 100% para utilidades core

### 3. **Principios**
- **F.I.R.S.T**: Fast, Independent, Repeatable, Self-validating, Timely
- **AAA Pattern**: Arrange, Act, Assert
- **Given-When-Then**: Estructura clara de tests

## 🚀 Comandos útiles

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage

# Ejecutar solo unit tests
flutter test test/unit

# Ejecutar solo widget tests
flutter test test/widget

# Ejecutar integration tests
flutter test integration_test

# Generar mocks
flutter packages pub run build_runner build
```