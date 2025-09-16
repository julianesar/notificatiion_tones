# Package Name Change Guide

Esta guía explica cómo cambiar el nombre del paquete de la aplicación de forma centralizada y eficiente.

## 🎯 Solución Centralizada Profesional

El proyecto utiliza un sistema **centralizado** de Method Channels que requiere actualizar **solo 2 constantes** cuando se cambia el nombre del paquete. Esto garantiza consistencia y previene errores de sincronización.

### 🚀 Sistema Centralizado

- **Flutter**: `lib/core/constants/method_channels.dart` - Constantes centralizadas
- **Android**: `MainActivity.kt` - Hardcoded pero consistente con Flutter

## 🔧 Pasos para Cambiar el Nombre del Paquete

### 1. Actualizar Constantes Centralizadas (Solo 2 cambios)

#### En Flutter (`lib/core/constants/method_channels.dart`):
```dart
class MethodChannels {
  // ✅ Solo cambiar esta línea:
  static const String _packageName = 'tu.nuevo.paquete';

  // ✅ Los channels se actualizan automáticamente
  static const String ringtoneConfig = '$_packageName/ringtone_config';
}
```

#### En Android (`MainActivity.kt`):
```kotlin
// ✅ Solo cambiar esta línea:
private val CHANNEL = "tu.nuevo.paquete/ringtone_config"
```

### 2. Cambios Estándar de Flutter

#### 2.1 Android Manifest
- `android/app/src/main/AndroidManifest.xml`: Actualizar el atributo `package`

#### 2.2 Estructura de Directorios
- Renombrar el directorio Kotlin: `android/app/src/main/kotlin/[nuevo/path]`
- Actualizar imports en `MainActivity.kt`

#### 2.3 Gradle
- `android/app/build.gradle`: Actualizar `applicationId`

### 3. Verificación

Después de los cambios, verificar que todos los Method Channels funcionen:
- ✅ Permisos de write settings
- ✅ Permisos de contactos
- ✅ Configuración de tonos

## 🛡️ Ventajas de esta Solución

1. **Solo 2 Cambios**: Cambiar únicamente 2 constantes
2. **Consistencia Garantizada**: Los channels siempre estarán sincronizados
3. **Mantenimiento Fácil**: Solo 2 líneas de código que cambiar
4. **Escalabilidad**: Fácil agregar nuevos channels siguiendo el patrón
5. **Prevención de Errores**: Imposible tener channels desincronizados

## 🔍 Cómo Funciona Internamente

### Flutter (`lib/core/constants/method_channels.dart`):
```dart
class MethodChannels {
  // Una sola constante para el package name
  static const String _packageName = 'com.sonidosdenotificaciones.notificationsounds';

  // Los channels se construyen automáticamente
  static const String ringtoneConfig = '$_packageName/ringtone_config';
}
```

### Servicios que usan las constantes:
- `RingtoneConfigurationService` usa `MethodChannels.ringtoneConfig`
- `ContactsNativeDataSource` usa `MethodChannels.ringtoneConfig`

## 📋 Checklist para Cambio de Paquete

### Cambios en Código (Solo 2):
- [ ] Actualizar `_packageName` en `method_channels.dart`
- [ ] Actualizar `CHANNEL` en `MainActivity.kt`

### Cambios Estándar de Flutter:
- [ ] Cambiar `package` en `AndroidManifest.xml`
- [ ] Actualizar `applicationId` en `build.gradle`
- [ ] Renombrar directorio Kotlin
- [ ] Probar permisos de write settings
- [ ] Probar funcionalidad de contactos
- [ ] Verificar configuración de tonos

## 🎉 Resultado

**Sistema robusto que previene problemas de Method Channels al cambiar package name!**