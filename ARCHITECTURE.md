# 🏗️ Arquitectura - App Sonidos de Notificaciones

Documentación de la arquitectura profesional de la aplicación de sonidos de notificaciones para Android, siguiendo los principios de **Clean Architecture** y las mejores prácticas de Flutter.

## 📋 Índice

- [Visión General](#visión-general)
- [Principios Arquitectónicos](#principios-arquitectónicos)
- [Estructura de Capas](#estructura-de-capas)
- [Organización por Features](#organización-por-features)
- [Flujo de Datos](#flujo-de-datos)
- [Tecnologías y Dependencias](#tecnologías-y-dependencias)
- [Estructura de Carpetas](#estructura-de-carpetas)

## 🎯 Visión General

Esta aplicación permite a los usuarios:
- Explorar categorías de sonidos desde una API
- Reproducir y descargar archivos MP3
- Establecer sonidos como tonos de notificación/llamada
- Gestionar sonidos descargados localmente
- Configurar preferencias y permisos

## 📐 Principios Arquitectónicos

### 🧩 Clean Architecture
- **Separación de responsabilidades** en capas bien definidas
- **Inversión de dependencias** - las capas internas no conocen las externas
- **Independencia de frameworks** - lógica de negocio aislada
- **Testabilidad** - cada capa es testeable de forma independiente

### 🔄 SOLID Principles
- **S**ingle Responsibility: Cada clase tiene una responsabilidad específica
- **O**pen/Closed: Extensible sin modificar código existente
- **L**iskov Substitution: Interfaces intercambiables
- **I**nterface Segregation: Interfaces específicas por necesidad
- **D**ependency Inversion: Depender de abstracciones, no implementaciones

## 🏢 Estructura de Capas

### 1. **Presentation Layer** (`presentation/`)
**Responsabilidad**: Interfaz de usuario y manejo de estado
```
├── pages/           # Pantallas de la aplicación
├── providers/       # Estado con Provider/BLoC
└── widgets/         # Componentes UI específicos
```
**Tecnologías**: Flutter Widgets, Provider/BLoC, Navigator

### 2. **Domain Layer** (`domain/`)
**Responsabilidad**: Lógica de negocio pura
```
├── entities/        # Modelos de negocio (sin dependencias externas)
├── repositories/    # Interfaces de repositorios
└── usecases/        # Casos de uso de la aplicación
```
**Tecnologías**: Dart puro, sin dependencias de Flutter

### 3. **Data Layer** (`data/`)
**Responsabilidad**: Acceso y gestión de datos
```
├── datasources/     # Fuentes de datos (API, DB, cache)
├── models/          # Modelos de datos con serialización
└── repositories/    # Implementación de interfaces del domain
```
**Tecnologías**: HTTP, SQLite, SharedPreferences, File System

## 🎪 Organización por Features

Cada funcionalidad principal está organizada como un módulo independiente:

### 🎵 **Categories**
Gestión de categorías de sonidos
- Obtener categorías desde API
- Cache local de categorías
- Filtrado y búsqueda

### 🔊 **Sounds**
Reproducción y gestión de audio
- Streaming de audio desde URLs
- Control de reproducción (play, pause, stop)
- Visualización de metadatos

### ⬇️ **Downloads**
Sistema de descargas
- Descarga de archivos MP3
- Gestión de progreso
- Almacenamiento local organizado

### 🔔 **Notifications**
Configuración de tonos
- Establecer como tono de notificación
- Configurar sonido de llamada
- Gestión de permisos Android

### ⚙️ **Settings**
Configuración global
- Preferencias de usuario
- Gestión de permisos
- Temas y personalización

## 🌊 Flujo de Datos

```
UI (Widget) 
    ↓ User Action
Provider/BLoC
    ↓ Business Logic
UseCase
    ↓ Data Request
Repository Interface
    ↓ Implementation
Repository
    ↓ Data Source
API / Database / Cache
    ↓ Response
Repository
    ↓ Domain Entity
UseCase
    ↓ State Update
Provider/BLoC
    ↓ UI Update
Widget (Rebuild)
```

### Principios del flujo:
1. **Unidireccional**: Los datos fluyen en una dirección
2. **Inmutable**: Los estados son inmutables
3. **Reactivo**: La UI reacciona a cambios de estado
4. **Separado**: Lógica separada de la presentación

## 🛠️ Tecnologías y Dependencias

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # Network
  dio: ^5.3.2
  
  # Local Storage
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  
  # File Management
  path_provider: ^2.1.1
  
  # Audio
  audioplayers: ^5.2.1
  
  # Permissions (Android)
  permission_handler: ^11.0.1
  
  # Dependency Injection
  get_it: ^7.6.4
  
  # Utilities
  equatable: ^2.0.5
  dartz: ^0.10.1
```

### Dev Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
  test: ^1.24.0
```

## 📁 Estructura de Carpetas

```
lib/
├── 📁 config/                    # Configuración global
│   ├── app_config.dart          # Configuración por entorno
│   └── theme_config.dart        # Configuración de temas
│
├── 📁 core/                     # Funcionalidades compartidas
│   ├── 📁 network/              # Cliente HTTP y red
│   ├── 📁 storage/              # Base de datos y cache
│   ├── 📁 audio/                # Utilidades de audio
│   ├── 📁 platform/             # Código específico Android
│   ├── 📁 di/                   # Inyección de dependencias
│   ├── 📁 error/                # Manejo de errores
│   ├── 📁 constants/            # Constantes globales
│   ├── 📁 extensions/           # Extensiones Dart
│   └── 📁 utils/                # Utilidades generales
│
├── 📁 features/                 # Módulos por funcionalidad
│   ├── 📁 categories/           # Gestión de categorías
│   │   ├── 📁 data/
│   │   │   ├── datasources/     # API + Cache
│   │   │   ├── models/          # Modelos de datos
│   │   │   └── repositories/    # Implementación
│   │   ├── 📁 domain/
│   │   │   ├── entities/        # Entidades de negocio
│   │   │   ├── repositories/    # Interfaces
│   │   │   └── usecases/        # Casos de uso
│   │   └── 📁 presentation/
│   │       ├── pages/           # Pantallas
│   │       ├── providers/       # Estado
│   │       └── widgets/         # Componentes UI
│   │
│   ├── 📁 sounds/              # [Misma estructura]
│   ├── 📁 downloads/           # [Misma estructura]
│   ├── 📁 notifications/       # [Misma estructura]
│   └── 📁 settings/            # [Misma estructura]
│
├── 📁 shared/                  # Componentes UI compartidos
│   ├── 📁 widgets/             # Widgets reutilizables
│   ├── 📁 theme/               # Sistema de temas
│   └── 📁 navigation/          # Navegación
│
└── main.dart                   # Punto de entrada
```

## 🧪 Testing Strategy

```
test/
├── 📁 unit/                    # Tests unitarios (70%)
│   ├── core/                   # Tests de core
│   └── features/               # Tests por feature
├── 📁 widget/                  # Tests de widgets (20%)
└── 📁 integration/             # Tests E2E (10%)
```

### Coverage Target
- **Mínimo**: 80% cobertura general
- **Core**: 90% cobertura
- **Use Cases**: 100% cobertura
- **Critical Paths**: 100% cobertura

## 🚀 Beneficios de esta Arquitectura

### ✅ **Mantenibilidad**
- Código organizado y predecible
- Fácil localización de funcionalidades
- Cambios aislados por feature

### ✅ **Escalabilidad**
- Nuevos features sin afectar existentes
- Fácil agregar nuevas fuentes de datos
- Arquitectura preparada para crecimiento

### ✅ **Testabilidad**
- Cada capa testeable independientemente
- Mocks e interfaces bien definidas
- Coverage alto y confiable

### ✅ **Reutilización**
- Core reutilizable entre features
- Componentes UI compartidos
- Lógica de negocio independiente

### ✅ **Separación de Responsabilidades**
- UI separada de lógica de negocio
- Datos separados de presentación
- Cada clase con propósito específico

---

**Autor**: Arquitectura diseñada siguiendo las mejores prácticas de Flutter y Clean Architecture  
**Fecha**: 2024  
**Versión**: 1.0.0