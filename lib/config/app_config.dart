class AppConfig {
  static AppConfig? _instance;

  AppConfig._internal();

  static AppConfig I() {
    _instance ??= AppConfig._internal();
    return _instance!;
  }

  final String baseUrl = 'https://sounds-api.mobapps.workers.dev';
  final Duration cacheTtl = const Duration(minutes: 5);
  final bool enableLogging = true;
}
