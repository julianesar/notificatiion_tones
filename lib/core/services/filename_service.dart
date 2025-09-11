import 'dart:math';
import 'package:path/path.dart' as path;

/// Servicio profesional para generar nombres de archivo amigables y únicos
/// Respeta la arquitectura Clean y proporciona nomenclatura consistente
abstract class FilenameService {
  /// Genera un nombre de archivo amigable para usuario
  String generateUserFriendlyFilename({
    required String title,
    required String url,
    String? toneId,
  });
  
  /// Genera un nombre técnico único para identificación interna
  String generateTechnicalFilename({
    required String title,
    required String url,
    required String toneId,
  });
  
  /// Genera nombre de visualización limpio para mostrar al usuario
  String generateDisplayName(String originalTitle);
  
  /// Extrae el ID técnico de un nombre de archivo
  String extractTechnicalId(String filename);
  
  /// Valida si un nombre de archivo es válido
  bool isValidFilename(String filename);
  
  /// Obtiene la extensión apropiada desde una URL
  String extractExtension(String url);
}

class FilenameServiceImpl implements FilenameService {
  static const int _maxFilenameLength = 80;
  static const List<String> _validAudioExtensions = [
    '.mp3', '.wav', '.aac', '.ogg', '.m4a', '.flac'
  ];

  @override
  String generateUserFriendlyFilename({
    required String title,
    required String url,
    String? toneId,
  }) {
    // Limpiar y procesar el título
    final cleanTitle = _cleanTitle(title);
    final extension = extractExtension(url);
    
    // Generar nombre amigable sin ID técnico visible
    final friendlyName = '$cleanTitle$extension';
    
    // Aplicar límite de longitud
    return _limitLength(friendlyName, extension);
  }

  @override
  String generateTechnicalFilename({
    required String title,
    required String url,
    required String toneId,
  }) {
    final cleanTitle = _cleanTitle(title);
    final extension = extractExtension(url);
    final safeToneId = _sanitizeToneId(toneId);
    
    // Formato técnico: [ToneID_Original]_Titulo_Limpio.ext
    final technicalName = '${safeToneId}_$cleanTitle$extension';
    
    return _limitLength(technicalName, extension);
  }

  @override
  String generateDisplayName(String originalTitle) {
    try {
      // Limpiar el título para visualización
      String displayName = originalTitle
          .trim()
          .replaceAll(RegExp(r'[_\-]+'), ' ')     // Reemplazar guiones y underscores con espacios
          .replaceAll(RegExp(r'\s+'), ' ')        // Múltiples espacios -> uno solo
          .trim();
      
      if (displayName.isEmpty) {
        return 'Tono de audio';
      }
      
      // Capitalizar la primera letra de cada palabra para mejor presentación
      return displayName.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
      
    } catch (e) {
      return originalTitle.isNotEmpty ? originalTitle : 'Tono de audio';
    }
  }

  @override
  String extractTechnicalId(String filename) {
    try {
      // Remover extensión
      final nameWithoutExt = path.basenameWithoutExtension(filename);
      
      // Buscar patrón [ToneID]_Titulo
      final parts = nameWithoutExt.split('_');
      if (parts.isNotEmpty) {
        final firstPart = parts[0];
        
        // El primer componente es el toneId sanitizado
        // Solo verificar que no esté vacío
        if (firstPart.isNotEmpty) {
          return _unsanitizeToneId(firstPart);
        }
      }
      
      // Fallback: usar el nombre completo sin extensión
      return nameWithoutExt;
    } catch (e) {
      print('Error extracting technical ID: $e');
      return filename;
    }
  }

  @override
  bool isValidFilename(String filename) {
    if (filename.isEmpty) return false;
    
    // Verificar caracteres válidos
    final validPattern = RegExp(r'^[a-zA-Z0-9_\-\.\s]+$');
    if (!validPattern.hasMatch(filename)) return false;
    
    // Verificar extensión válida
    final extension = path.extension(filename).toLowerCase();
    return _validAudioExtensions.contains(extension);
  }

  @override
  String extractExtension(String url) {
    try {
      final extension = path.extension(url).toLowerCase();
      
      // Si la extensión es válida, usarla
      if (_validAudioExtensions.contains(extension)) {
        return extension;
      }
      
      // Buscar extensión en query parameters (ej: ?format=mp3)
      final uri = Uri.tryParse(url);
      if (uri != null && uri.queryParameters.containsKey('format')) {
        final format = uri.queryParameters['format']!.toLowerCase();
        final formatExt = '.$format';
        if (_validAudioExtensions.contains(formatExt)) {
          return formatExt;
        }
      }
      
      // Fallback a MP3
      return '.mp3';
    } catch (e) {
      print('Error extracting extension from URL: $e');
      return '.mp3';
    }
  }

  /// Limpia el título para uso en nombres de archivo
  String _cleanTitle(String title) {
    // Remover caracteres especiales y espacios extra
    String cleaned = title
        .trim()
        .replaceAll(RegExp(r'[^\w\s\-]'), '') // Solo letras, números, espacios y guiones
        .replaceAll(RegExp(r'\s+'), '_')      // Espacios -> guiones bajos
        .replaceAll(RegExp(r'_+'), '_')       // Múltiples _ -> uno solo
        .replaceAll(RegExp(r'^_+|_+$'), '');  // Remover _ al inicio/final
    
    if (cleaned.isEmpty) {
      cleaned = 'audio_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Capitalizar palabras para mejor legibilidad
    return _capitalizeWords(cleaned);
  }

  /// Sanitiza el toneId para uso seguro en nombres de archivo
  String _sanitizeToneId(String toneId) {
    try {
      // Reemplazar caracteres problemáticos con equivalentes seguros
      String sanitized = toneId
          .replaceAll(':', '_COLON_')
          .replaceAll('/', '_SLASH_')
          .replaceAll('\\', '_BACKSLASH_')
          .replaceAll('*', '_STAR_')
          .replaceAll('?', '_QUESTION_')
          .replaceAll('"', '_QUOTE_')
          .replaceAll('<', '_LT_')
          .replaceAll('>', '_GT_')
          .replaceAll('|', '_PIPE_')
          .replaceAll(' ', '_SPACE_');
      
      // Asegurar que no esté vacío
      if (sanitized.isEmpty) {
        sanitized = 'UNKNOWN_ID';
      }
      
      return sanitized;
    } catch (e) {
      return 'ERROR_ID';
    }
  }

  /// Restaura el toneId original desde la versión sanitizada
  String _unsanitizeToneId(String sanitizedId) {
    try {
      // Revertir las transformaciones de sanitización
      String original = sanitizedId
          .replaceAll('_COLON_', ':')
          .replaceAll('_SLASH_', '/')
          .replaceAll('_BACKSLASH_', '\\')
          .replaceAll('_STAR_', '*')
          .replaceAll('_QUESTION_', '?')
          .replaceAll('_QUOTE_', '"')
          .replaceAll('_LT_', '<')
          .replaceAll('_GT_', '>')
          .replaceAll('_PIPE_', '|')
          .replaceAll('_SPACE_', ' ');
      
      return original;
    } catch (e) {
      return sanitizedId; // Fallback al valor sanitizado
    }
  }

  /// Capitaliza las palabras separadas por guiones bajos
  String _capitalizeWords(String text) {
    return text.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join('_');
  }

  /// Limita la longitud del nombre de archivo
  String _limitLength(String filename, String extension) {
    if (filename.length <= _maxFilenameLength) {
      return filename;
    }
    
    final nameWithoutExt = path.basenameWithoutExtension(filename);
    final maxNameLength = _maxFilenameLength - extension.length;
    
    if (nameWithoutExt.length > maxNameLength) {
      final truncatedName = nameWithoutExt.substring(0, maxNameLength);
      return '$truncatedName$extension';
    }
    
    return filename;
  }
}