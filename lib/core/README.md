# Core - Funcionalidades Compartidas

Esta carpeta contiene todas las funcionalidades compartidas y de infraestructura de la aplicación.

## 📁 Módulos Core

### 🌐 **Network**
Cliente HTTP y gestión de conexiones
- HTTP client (Dio/http)
- Interceptors (auth, logging, error)
- Configuración de red
- Manejo de timeouts y reintentos

### 💾 **Storage**
Gestión de almacenamiento de datos
- Base de datos local (SQLite/Hive)
- Almacenamiento de archivos
- SharedPreferences
- Cache management

### 🔊 **Audio**
Funcionalidades de audio
- Reproductores de audio
- Gestión de códecs
- Utilidades de audio
- Control de reproducción

### 📱 **Platform**
Código específico de plataforma
- Permisos Android/iOS
- Integraciones nativas
- Platform channels
- Configuraciones específicas

### 💉 **DI (Dependency Injection)**
Inyección de dependencias
- Service locator (GetIt)
- Configuración de dependencias
- Factory patterns
- Singleton management

### ❌ **Error**
Manejo de errores y excepciones
- Excepciones personalizadas
- Error handlers globales
- Logging de errores
- Error recovery

### 📊 **Constants**
Constantes globales
- URLs de API
- Configuraciones
- Strings estáticos
- Valores por defecto

### 🔧 **Extensions**
Extensiones de Dart
- String extensions
- DateTime extensions
- BuildContext extensions
- Utilidades comunes

### 🛠️ **Utils**
Utilidades generales
- Helpers
- Formatters
- Validators
- Funciones auxiliares

## 🎯 Principios

1. **Reutilización**: Código compartido entre features
2. **Abstracción**: Interfaces para implementaciones específicas
3. **Configuración**: Centralizados los ajustes globales
4. **Utilidades**: Funciones comunes y helpers