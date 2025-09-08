abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

class AudioFailure extends Failure {
  const AudioFailure({required super.message, super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}
