/// Centralized Method Channel constants to ensure consistency
/// between Flutter and native Android code.
///
/// When changing the package name, only update [_packageName] and
/// all channels will be automatically updated.
class MethodChannels {
  /// The base package name - update this when changing the app package name
  static const String _packageName = 'com.sonidosdenotificaciones.notificationsounds';

  /// Ringtone configuration channel for system settings permissions and ringtone management
  static const String ringtoneConfig = '$_packageName/ringtone_config';

  /// Add other channels here as needed following the same pattern
  // static const String exampleChannel = '$_packageName/example';

  /// Private constructor to prevent instantiation
  MethodChannels._();
}