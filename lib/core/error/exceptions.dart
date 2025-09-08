abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(String message, [String? code])
    : super(message: message, code: code);
}

class ServerException extends AppException {
  const ServerException(String message, [String? code])
    : super(message: message, code: code);
}

class CacheException extends AppException {
  const CacheException(String message, [String? code])
    : super(message: message, code: code);
}

class AudioException extends AppException {
  const AudioException(String message, [String? code])
    : super(message: message, code: code);
}

class PermissionException extends AppException {
  const PermissionException(String message, [String? code])
    : super(message: message, code: code);
}

class StorageException extends AppException {
  const StorageException(String message, [String? code])
    : super(message: message, code: code);
}

class ValidationException extends AppException {
  const ValidationException(String message, [String? code])
    : super(message: message, code: code);
}
