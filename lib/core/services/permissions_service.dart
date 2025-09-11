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
    
    if (sdkVersion >= 29) {
      // Android 10+ (API 29+) - No permission needed for MediaStore downloads
      return true;
    } else {
      // Android 9 and below (API 28 and below) - Traditional storage permission required
      return await Permission.storage.isGranted;
    }
  }

  @override
  Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final sdkVersion = await getAndroidSdkVersion();
      
      if (sdkVersion >= 29) {
        // Android 10+ (API 29+) - No permission needed for MediaStore downloads
        return true;
      } else {
        // Android 9 and below (API 28 and below) - Traditional storage permission required
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
    
    if (sdkVersion >= 29) {
      return 'Error: No se debería solicitar permisos en Android 10+';
    } else {
      return 'Se requiere permiso de almacenamiento para descargar tonos.\n\n'
             'Ve a Configuración > Aplicaciones > Sonidos de Notificaciones > Permisos > Almacenamiento';
    }
  }
}