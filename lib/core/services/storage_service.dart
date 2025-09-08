import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum StorageLocation {
  publicMusic, // Para Android 11+ usando MediaStore API (más seguro)
  appPrivate, // Directorio privado de la app (siempre disponible)
  appExternalPrivate, // External storage privado de la app (se elimina al desinstalar)
}

class StorageInfo {
  final String path;
  final StorageLocation location;
  final bool requiresPermissions;
  final String userFriendlyPath;
  final String description;

  const StorageInfo({
    required this.path,
    required this.location,
    required this.requiresPermissions,
    required this.userFriendlyPath,
    required this.description,
  });
}

abstract class StorageService {
  Future<StorageInfo> getOptimalDownloadLocation();
  Future<StorageInfo> getFallbackLocation();
  Future<String> getAppPrivateDownloadsPath();
  Future<String> getAppExternalPrivateDownloadsPath();
  Future<bool> canUseMediaStore();
  Future<int> getAndroidSdkVersion();
}

class StorageServiceImpl implements StorageService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  Future<int> getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<bool> canUseMediaStore() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      // MediaStore API está disponible desde Android 10+ (API 29+)
      return sdkVersion >= 29;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> getAppPrivateDownloadsPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, 'downloads');
  }

  @override
  Future<String> getAppExternalPrivateDownloadsPath() async {
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return path.join(externalDir.path, 'downloads');
      }
    } catch (e) {
      print('External storage not available: $e');
    }

    // Fallback to internal storage
    return getAppPrivateDownloadsPath();
  }

  @override
  Future<StorageInfo> getOptimalDownloadLocation() async {
    if (!Platform.isAndroid) {
      // iOS - usar directorio de documentos de la app
      final appPrivatePath = await getAppPrivateDownloadsPath();
      return StorageInfo(
        path: appPrivatePath,
        location: StorageLocation.appPrivate,
        requiresPermissions: false,
        userFriendlyPath: 'Documentos de la app/downloads/',
        description:
            'Área privada de la aplicación (solo accesible desde la app)',
      );
    }

    final androidInfo = await _deviceInfo.androidInfo;
    final sdkVersion = androidInfo.version.sdkInt;

    // Estrategia segura: Usar siempre directorios privados de la app primero
    try {
      final externalPrivatePath = await getAppExternalPrivateDownloadsPath();
      return StorageInfo(
        path: externalPrivatePath,
        location: StorageLocation.appExternalPrivate,
        requiresPermissions: false,
        userFriendlyPath: 'Android/data/com.example.app/files/downloads/',
        description:
            'Área privada de la app en almacenamiento externo (accesible por exploradores de archivos)',
      );
    } catch (e) {
      // Fallback al directorio interno si falla el externo
      final appPrivatePath = await getAppPrivateDownloadsPath();
      return StorageInfo(
        path: appPrivatePath,
        location: StorageLocation.appPrivate,
        requiresPermissions: false,
        userFriendlyPath: 'Almacenamiento interno/downloads/',
        description: 'Área privada interna de la aplicación',
      );
    }
  }

  @override
  Future<StorageInfo> getFallbackLocation() async {
    // Siempre usar directorio interno privado como último recurso
    final appPrivatePath = await getAppPrivateDownloadsPath();

    return StorageInfo(
      path: appPrivatePath,
      location: StorageLocation.appPrivate,
      requiresPermissions: false,
      userFriendlyPath: Platform.isAndroid
          ? 'Almacenamiento interno de la app/downloads/'
          : 'Documentos de la app/downloads/',
      description:
          'Área privada interna de la aplicación (más segura, siempre disponible)',
    );
  }
}
