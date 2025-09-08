import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class PermissionsService {
  Future<bool> requestStoragePermissions();
  Future<bool> hasStoragePermissions();
  Future<int> getAndroidSdkVersion();
  Future<String> getRequiredPermissionMessage();
}

class PermissionsServiceImpl implements PermissionsService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  Future<int> getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    
    final androidInfo = await _deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  @override
  Future<bool> hasStoragePermissions() async {
    if (!Platform.isAndroid) return true;
    
    final sdkVersion = await getAndroidSdkVersion();
    
    if (sdkVersion >= 33) {
      // Android 13+ (API 33+) - Granular media permissions
      return await Permission.audio.isGranted;
    } else if (sdkVersion >= 30) {
      // Android 11-12 (API 30-32) - Scoped storage but still need storage
      return await Permission.storage.isGranted;
    } else {
      // Android 10 and below - Traditional storage
      return await Permission.storage.isGranted;
    }
  }

  @override
  Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final sdkVersion = await getAndroidSdkVersion();
      
      if (sdkVersion >= 33) {
        // Android 13+ (API 33+) - Request audio permission for media files
        final status = await Permission.audio.request();
        return status.isGranted;
      } else if (sdkVersion >= 30) {
        // Android 11-12 (API 30-32) - Still request storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      } else {
        // Android 10 and below - Traditional storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  @override
  Future<String> getRequiredPermissionMessage() async {
    if (!Platform.isAndroid) return '';
    
    final sdkVersion = await getAndroidSdkVersion();
    
    if (sdkVersion >= 33) {
      return 'Se requiere permiso de "Música y audio" para descargar tonos.\n\n'
             'Ve a Configuración > Aplicaciones > Sonidos de Notificaciones > Permisos > Música y audio';
    } else {
      return 'Se requiere permiso de almacenamiento para descargar tonos.\n\n'
             'Ve a Configuración > Aplicaciones > Sonidos de Notificaciones > Permisos > Almacenamiento';
    }
  }
}