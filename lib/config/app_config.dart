class AppConfig {
  static AppConfig? _instance;

  AppConfig._internal();

  static AppConfig I() {
    _instance ??= AppConfig._internal();
    return _instance!;
  }

  final String baseUrl = 'https://api.notificationsounds.mobapps.site';

  // Cache TTL diferenciado por tipo de contenido
  final Duration staticContentCacheTtl = const Duration(hours: 2); // Categorías
  final Duration dynamicContentCacheTtl = const Duration(minutes: 15); // Tonos
  final Duration defaultCacheTtl = const Duration(minutes: 5); // Fallback

  final bool enableLogging = true;

  // Método para obtener TTL según el endpoint
  Duration getCacheTtlForEndpoint(String endpoint) {
    if (endpoint.contains('/categories')) {
      return staticContentCacheTtl;
    } else if (endpoint.contains('/tones')) {
      return dynamicContentCacheTtl;
    }
    return defaultCacheTtl;
  }
}
