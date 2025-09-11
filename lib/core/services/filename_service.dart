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
    final shortId = _generateShortId(toneId);
    
    // Formato técnico: [ID_corto]_Titulo_Limpio.ext
    final technicalName = '${shortId}_$cleanTitle$extension';
    
    return _limitLength(technicalName, extension);
  }

  @override
  String extractTechnicalId(String filename) {
    try {
      // Remover extensión
      final nameWithoutExt = path.basenameWithoutExtension(filename);
      
      // Buscar patrón [ID]_Titulo
      final parts = nameWithoutExt.split('_');
      if (parts.isNotEmpty) {
        final firstPart = parts[0];
        
        // Verificar si parece un ID técnico (contiene letras y números)
        if (_looksLikeTechnicalId(firstPart)) {
          return firstPart;
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

  /// Genera un ID corto y único a partir del ID técnico original
  String _generateShortId(String originalId) {
    try {
      // Si el ID es corto y limpio, usarlo tal como está
      if (originalId.length <= 8 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(originalId)) {
        return originalId;
      }
      
      // Para IDs complejos como "freesound__123456-7", extraer la parte numérica
      final numericMatch = RegExp(r'(\d+)').firstMatch(originalId);
      if (numericMatch != null) {
        final numericPart = numericMatch.group(1)!;
        
        // Si la parte numérica es suficiente, usarla
        if (numericPart.length >= 4) {
          return 'T$numericPart'; // Prefijo "T" de "Tone"
        }
      }
      
      // Fallback: generar hash corto del ID original
      final hash = originalId.hashCode.abs();
      return 'T${hash.toString().substring(0, 6)}';
      
    } catch (e) {
      // Fallback final: usar timestamp
      return 'T${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  /// Verifica si una cadena parece un ID técnico
  bool _looksLikeTechnicalId(String value) {
    // IDs técnicos típicamente:
    // - Empiezan con T (nuestro prefijo)
    // - Contienen números
    // - Son relativamente cortos (< 15 caracteres)
    return value.length <= 15 && 
           (value.startsWith('T') || RegExp(r'\d').hasMatch(value));
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