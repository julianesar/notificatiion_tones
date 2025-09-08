# Features - Módulos de Funcionalidades

Esta carpeta contiene todos los módulos de funcionalidades de la aplicación, organizados siguiendo los principios de Clean Architecture.

## 📁 Estructura por Feature

Cada feature sigue la misma estructura de 3 capas:

### 🎯 **Categories** 
Gestión de categorías de sonidos
- **Data**: Fuentes de datos (API, local storage)
- **Domain**: Lógica de negocio y reglas
- **Presentation**: UI y manejo de estado

### 🔊 **Sounds**
Reproducción y gestión de archivos de audio
- Reproducir sonidos MP3
- Gestión de archivos de audio
- Control de reproducción

### ⬇️ **Downloads**
Sistema de descargas y almacenamiento local
- Descarga de archivos MP3
- Gestión de almacenamiento
- Cache de archivos

### 🔔 **Notifications**
Configuración como tonos de notificación/llamada
- Establecer como tono de notificación
- Configurar sonidos de llamada
- Permisos del sistema Android

### ⚙️ **Settings**
Configuración de la aplicación
- Preferencias de usuario
- Permisos y configuración del sistema
- Temas y personalización

## 🏗️ Arquitectura por Feature

```
feature_name/
├── data/
│   ├── datasources/     # Fuentes de datos (API, local)
│   ├── models/          # Modelos de datos
│   └── repositories/    # Implementación de repositorios
├── domain/
│   ├── entities/        # Entidades de negocio
│   ├── repositories/    # Interfaces de repositorios
│   └── usecases/        # Casos de uso
└── presentation/
    ├── pages/           # Páginas/Pantallas
    ├── providers/       # Estado (BLoC/Provider)
    └── widgets/         # Widgets específicos del feature
```

## 🔄 Flujo de Datos

**UI → Provider → UseCase → Repository → DataSource → API/Storage**

Cada feature mantiene su independencia y se comunica con el core y otros features a través de interfaces bien definidas.