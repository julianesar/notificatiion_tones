import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/tones/domain/entities/tone.dart';

/// Professional sharing service for tones and app content
/// Provides reusable sharing functionality across all modals and screens
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  static ShareService get instance => _instance;

  /// Share a tone with title and URL
  /// Includes app branding and professional message formatting
  Future<void> shareTone({
    required String title,
    required String url,
    String? additionalMessage,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final message = _buildToneShareMessage(
        title: title,
        url: url,
        additionalMessage: additionalMessage,
      );

      await Share.share(
        message,
        subject: 'Escucha este tono en Sonidos de Notificaciones',
        sharePositionOrigin: sharePositionOrigin,
      );
      
      // Provide haptic feedback for better UX
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('ShareService: Error sharing tone: $e');
      throw ShareException('Error al compartir el tono: $e');
    }
  }

  /// Share a tone from a Tone entity object
  Future<void> shareToneFromEntity({
    required Tone tone,
    String? additionalMessage,
    Rect? sharePositionOrigin,
  }) async {
    String message = _buildToneShareMessage(
      title: tone.title,
      url: tone.url,
      additionalMessage: additionalMessage,
    );

    try {
      await Share.share(
        message,
        subject: 'Escucha este tono en Sonidos de Notificaciones',
        sharePositionOrigin: sharePositionOrigin,
      );
      
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('ShareService: Error sharing tone entity: $e');
      throw ShareException('Error al compartir el tono: $e');
    }
  }

  /// Share the app itself with download links and description
  Future<void> shareApp({
    Rect? sharePositionOrigin,
  }) async {
    try {
      const message = '''🎵 ¡Descubre Sonidos de Notificaciones!

Una app increíble con miles de tonos de notificación únicos y de calidad.

✨ Características:
• Gran variedad de tonos profesionales
• Descarga y guarda tus favoritos
• Categorías organizadas
• Reproducción instantánea
• Interfaz intuitiva

¡Descárgala gratis y personaliza tus notificaciones!

#SonidosDeNotificaciones #Tonos #Notificaciones''';

      await Share.share(
        message,
        subject: 'Sonidos de Notificaciones - App de Tonos',
        sharePositionOrigin: sharePositionOrigin,
      );
      
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('ShareService: Error sharing app: $e');
      throw ShareException('Error al compartir la aplicación: $e');
    }
  }

  /// Share multiple tones at once
  Future<void> shareMultipleTones({
    required List<Tone> tones,
    String? collectionName,
    Rect? sharePositionOrigin,
  }) async {
    if (tones.isEmpty) {
      throw ShareException('No hay tonos para compartir');
    }

    try {
      final message = _buildMultipleTonesShareMessage(
        tones: tones,
        collectionName: collectionName,
      );

      await Share.share(
        message,
        subject: collectionName != null 
          ? 'Colección de tonos: $collectionName'
          : 'Colección de ${tones.length} tonos',
        sharePositionOrigin: sharePositionOrigin,
      );
      
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('ShareService: Error sharing multiple tones: $e');
      throw ShareException('Error al compartir los tonos: $e');
    }
  }

  /// Get share position origin from a widget context (useful for iPads)
  static Rect? getSharePositionOrigin(BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Build formatted message for a single tone
  String _buildToneShareMessage({
    required String title,
    required String url,
    String? additionalMessage,
  }) {
    String message = '🎵 ¡Escucha este increíble tono: "$title"!';
    
    if (additionalMessage != null && additionalMessage.isNotEmpty) {
      message += '\n\n$additionalMessage';
    }
    
    message += '\n\n📱 Descarga "Sonidos de Notificaciones" y disfruta de cientos de tonos únicos para personalizar tu teléfono.';
    message += '\n\n✨ Encuentra este tono y muchos más en nuestra app gratuita.';
    message += '\n\n🔗 Descárgala aquí: https://play.google.com/store/apps/details?id=com.example.my_new_app';
    message += '\n\n#SonidosDeNotificaciones #Tonos #PersonalizaTuTelefono';
    
    return message;
  }

  /// Build formatted message for multiple tones
  String _buildMultipleTonesShareMessage({
    required List<Tone> tones,
    String? collectionName,
  }) {
    String message = '🎵 ¡Mira esta increíble colección de tonos!';
    
    if (collectionName != null) {
      message += '\n📂 $collectionName';
    }
    
    message += '\n\n🎶 Tonos incluidos:';
    
    for (int i = 0; i < tones.length && i < 5; i++) {
      message += '\n${i + 1}. ${tones[i].title}';
    }
    
    if (tones.length > 5) {
      message += '\n... y ${tones.length - 5} tonos más';
    }
    
    message += '\n\n📱 Descarga "Sonidos de Notificaciones" y disfruta de cientos de tonos únicos para personalizar tu teléfono.';
    message += '\n\n✨ Encuentra estos tonos y muchos más en nuestra app gratuita.';
    message += '\n\n🔗 Descárgala aquí: https://play.google.com/store/apps/details?id=com.example.my_new_app';
    message += '\n\n#SonidosDeNotificaciones #Tonos #PersonalizaTuTelefono';
    
    return message;
  }
}

/// Custom exception for sharing operations
class ShareException implements Exception {
  final String message;
  
  const ShareException(this.message);
  
  @override
  String toString() => 'ShareException: $message';
}

/// Extension to make sharing easier from any widget
extension ShareContextExtension on BuildContext {
  /// Get share position origin for this widget context
  Rect? get sharePositionOrigin => ShareService.getSharePositionOrigin(this);
  
  /// Share a tone with automatic position origin
  Future<void> shareTone({
    required String title,
    required String url,
    String? additionalMessage,
  }) async {
    await ShareService.instance.shareTone(
      title: title,
      url: url,
      additionalMessage: additionalMessage,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
  
  /// Share a tone entity with automatic position origin
  Future<void> shareToneEntity({
    required Tone tone,
    String? additionalMessage,
  }) async {
    await ShareService.instance.shareToneFromEntity(
      tone: tone,
      additionalMessage: additionalMessage,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}