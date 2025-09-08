class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.notification-sounds.com';
  static const String apiVersion = 'v1';
  static const String apiKey = 'YOUR_API_KEY_HERE';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Storage
  static const String databaseName = 'notification_sounds.db';
  static const int databaseVersion = 1;
  static const String soundsTableName = 'sounds';
  static const String categoriesTableName = 'categories';
  static const String favoritesTableName = 'favorites';

  // File paths
  static const String soundsDirectoryName = 'sounds';
  static const String cacheDirectoryName = 'cache';
  static const String tempDirectoryName = 'temp';

  // Audio formats
  static const List<String> supportedAudioFormats = [
    'mp3',
    'wav',
    'aac',
    'ogg',
  ];

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Download
  static const int maxConcurrentDownloads = 3;
  static const int downloadRetryAttempts = 3;

  // Audio player
  static const double defaultVolume = 1.0;
  static const double fadeInDuration = 0.5;
  static const double fadeOutDuration = 0.5;

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Permissions (Android)
  static const List<String> requiredPermissions = [
    'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.WRITE_SETTINGS',
    'android.permission.INTERNET',
  ];

  // SharedPreferences keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';
  static const String downloadQualityKey = 'download_quality';
}

class ApiEndpoints {
  static const String categories = '/categories';
  static const String sounds = '/sounds';
  static const String popular = '/sounds/popular';
  static const String trending = '/sounds/trending';
  static const String search = '/sounds/search';
  static const String download = '/sounds/{id}/download';
  static const String favorites = '/user/favorites';
}
