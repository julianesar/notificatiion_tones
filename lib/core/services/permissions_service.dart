import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class PermissionsService {
  Future<bool> requestStoragePermissions();
  Future<bool> hasStoragePermissions();
  Future<bool> requestSystemSettingsPermissions();
  Future<bool> hasSystemSettingsPermissions();
  Future<int> getAndroidSdkVersion();
  Future<String> getRequiredPermissionMessage();
  Future<String> getSystemSettingsPermissionMessage();
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

  @override
  Future<bool> hasSystemSettingsPermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // Use Permission.manageExternalStorage or check if we can modify system settings
      // For Android API 23+, we need to check Settings.System.canWrite permission
      return await Permission.manageExternalStorage.isGranted;
    } catch (e) {
      print('Error checking system settings permission: $e');
      return false;
    }
  }

  @override
  Future<bool> requestSystemSettingsPermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // This will redirect to system settings where user needs to manually enable
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting system settings permission: $e');
      return false;
    }
  }

  @override
  Future<String> getSystemSettingsPermissionMessage() async {
    if (!Platform.isAndroid) return '';
    
    return 'Necesitas activar "Modificar configuración del sistema" para personalizar tonos de llamada, notificaciones y alarmas.\n\n'
           'Toca "Permitir" para ir a configuración y activar este permiso.';
  }
}