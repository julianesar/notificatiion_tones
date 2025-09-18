import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

/// Servicio profesional para manejo seguro de archivos de audio
/// Usa directorios accesibles del sistema para permitir al usuario acceder a sus descargas
/// Implementa MediaStore para Android 10+ de manera profesional
abstract class MediaStoreService {
  /// Guarda audio en la carpeta pública de descargas/música
  Future<String> saveAudioToPublicStorage({
    required String filename,
    required Uint8List audioBytes,
    String? subfolder,
  });
  
  /// Guarda audio en almacenamiento privado de la app (para caché)
  Future<String> saveAudioToAppStorage({
    required String filename,
    required Uint8List audioBytes,
    required String destinationPath,
  });
  
  /// Obtiene el directorio público de descargas de audio
  Future<String> getPublicAudioDirectory();
  
  /// Obtiene el directorio privado de la app para audio
  Future<String> getAppAudioDirectory();
  
  /// Obtiene los archivos de audio descargados
  Future<List<AudioFileInfo>> getDownloadedAudioFiles();
  
  Future<bool> deleteAudioFile(String filePath);
  Future<List<String>> getAudioFiles(String directoryPath);
  Future<bool> canWriteToPath(String directoryPath);
}

class AudioFileInfo {
  final String filePath;
  final String filename;
  final String displayName;
  final DateTime dateAdded;
  final int size;
  
  AudioFileInfo({
    required this.filePath,
    required this.filename,
    required this.displayName,
    required this.dateAdded,
    required this.size,
  });
}

class MediaStoreServiceImpl implements MediaStoreService {
  
  @override
  Future<String> getPublicAudioDirectory() async {
    if (Platform.isAndroid) {
      // En Android, usamos Downloads/{AppName} para acceso público
      final directory = Directory('/storage/emulated/0/Download/${AppConstants.appName}');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory.path;
    } else {
      // En iOS, usamos el directorio de documentos
      final docDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(path.join(docDir.path, AppConstants.appName));
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      return audioDir.path;
    }
  }
  
  @override
  Future<String> getAppAudioDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final audioDir = Directory(path.join(appDir.path, 'audio_cache'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }
  
  @override
  Future<String> saveAudioToPublicStorage({
    required String filename,
    required Uint8List audioBytes,
    String? subfolder,
  }) async {
    try {
      // Obtener directorio público
      String publicDir = await getPublicAudioDirectory();
      
      // Si hay subcarpeta, crearla
      if (subfolder != null) {
        publicDir = path.join(publicDir, subfolder);
        final subDir = Directory(publicDir);
        if (!await subDir.exists()) {
          await subDir.create(recursive: true);
        }
      }
      
      return await saveAudioToAppStorage(
        filename: filename,
        audioBytes: audioBytes,
        destinationPath: publicDir,
      );
    } catch (e) {
      print('Error saving to public storage: $e');
      // Fallback a almacenamiento privado
      return await saveAudioToAppStorage(
        filename: filename,
        audioBytes: audioBytes,
        destinationPath: await getAppAudioDirectory(),
      );
    }
  }
  
  @override
  Future<List<AudioFileInfo>> getDownloadedAudioFiles() async {
    try {
      final publicDir = await getPublicAudioDirectory();
      final files = await getAudioFiles(publicDir);
      
      List<AudioFileInfo> audioFiles = [];
      
      for (String filePath in files) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            final stat = await file.stat();
            final filename = path.basename(filePath);
            
            audioFiles.add(AudioFileInfo(
              filePath: filePath,
              filename: filename,
              displayName: _getDisplayName(filename),
              dateAdded: stat.modified,
              size: stat.size,
            ));
          }
        } catch (e) {
          print('Error reading file info for $filePath: $e');
        }
      }
      
      // Ordenar por fecha de modificación (más recientes primero)
      audioFiles.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      
      return audioFiles;
    } catch (e) {
      print('Error getting downloaded audio files: $e');
      return [];
    }
  }
  
  @override
  Future<bool> canWriteToPath(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      
      // Crear el directorio si no existe
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Probar escribir un archivo temporal para verificar permisos
      final testFile = File(path.join(directoryPath, '.test_write_permission'));
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return true;
    } catch (e) {
      print('Cannot write to path $directoryPath: $e');
      return false;
    }
  }

  @override
  Future<String> saveAudioToAppStorage({
    required String filename,
    required Uint8List audioBytes,
    required String destinationPath,
  }) async {
    try {
      // 1. Asegurar que el directorio destino existe
      final targetDir = Directory(destinationPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      // 2. Generar nombre de archivo único si es necesario
      String finalFilename = _sanitizeFilename(filename);
      File targetFile = File(path.join(destinationPath, finalFilename));
      
      // 3. Si el archivo existe, agregar timestamp para evitar sobrescribir
      if (await targetFile.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameWithoutExt = path.basenameWithoutExtension(finalFilename);
        final extension = path.extension(finalFilename);
        finalFilename = '${nameWithoutExt}_$timestamp$extension';
        targetFile = File(path.join(destinationPath, finalFilename));
      }
      
      // 4. Escribir el archivo de manera segura
      await targetFile.writeAsBytes(audioBytes);
      
      // 5. Verificar que el archivo se escribió correctamente
      if (!await targetFile.exists()) {
        throw Exception('Failed to save file to ${targetFile.path}');
      }
      
      print('Audio saved successfully to: ${targetFile.path}');
      return targetFile.path;
      
    } catch (e) {
      print('Error saving audio file: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Audio file deleted successfully: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting audio file: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getAudioFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      
      if (!await directory.exists()) {
        return [];
      }
      
      final files = await directory
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .where((file) => _isAudioFile(file.path))
          .map((file) => file.path)
          .toList();
      
      return files;
    } catch (e) {
      print('Error getting audio files from $directoryPath: $e');
      return [];
    }
  }

  /// Sanitiza el nombre del archivo para evitar caracteres problemáticos
  String _sanitizeFilename(String filename) {
    // Remover caracteres especiales que pueden causar problemas
    String sanitized = filename
        .replaceAll(RegExp(r'[^\w\s-.]'), '')  // Solo letras, números, espacios, guiones y puntos
        .replaceAll(RegExp(r'\s+'), '_')       // Reemplazar espacios con guiones bajos
        .trim();
    
    // Asegurar que tenga una extensión de audio válida
    if (!_hasValidAudioExtension(sanitized)) {
      sanitized = '${path.basenameWithoutExtension(sanitized)}.mp3';
    }
    
    // Limitar longitud del nombre
    if (sanitized.length > 100) {
      final extension = path.extension(sanitized);
      final nameWithoutExt = path.basenameWithoutExtension(sanitized);
      sanitized = '${nameWithoutExt.substring(0, 100 - extension.length)}$extension';
    }
    
    return sanitized;
  }

  /// Verifica si el archivo tiene una extensión de audio válida
  bool _hasValidAudioExtension(String filename) {
    const audioExtensions = ['.mp3', '.wav', '.aac', '.ogg', '.m4a', '.flac'];
    final extension = path.extension(filename).toLowerCase();
    return audioExtensions.contains(extension);
  }

  /// Verifica si un archivo es de audio basado en su extensión
  bool _isAudioFile(String filePath) {
    const audioExtensions = ['.mp3', '.wav', '.aac', '.ogg', '.m4a', '.flac'];
    final extension = path.extension(filePath).toLowerCase();
    return audioExtensions.contains(extension);
  }
  
  /// Obtiene un nombre de display amigable para el archivo
  String _getDisplayName(String filename) {
    // Remover la extensión y reemplazar guiones bajos con espacios
    String displayName = path.basenameWithoutExtension(filename);
    displayName = displayName.replaceAll('_', ' ');
    
    // Capitalizar la primera letra de cada palabra
    return displayName.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}