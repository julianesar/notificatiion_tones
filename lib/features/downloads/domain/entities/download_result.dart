import 'package:flutter/foundation.dart';

enum DownloadResultType {
  success,
  permissionDenied,
  networkError,
  storageError,
  cancelled,
  unknownError,
}

@immutable
class DownloadResult {
  final DownloadResultType type;
  final String? filePath;
  final String? message;
  final String? userFriendlyPath;

  const DownloadResult({
    required this.type,
    this.filePath,
    this.message,
    this.userFriendlyPath,
  });

  bool get isSuccess => type == DownloadResultType.success;
  bool get isError => !isSuccess;
  bool get isPermissionError => type == DownloadResultType.permissionDenied;
  bool get isNetworkError => type == DownloadResultType.networkError;
  bool get isStorageError => type == DownloadResultType.storageError;
  bool get isCancelled => type == DownloadResultType.cancelled;

  factory DownloadResult.success({
    required String filePath,
    String? userFriendlyPath,
  }) {
    return DownloadResult(
      type: DownloadResultType.success,
      filePath: filePath,
      userFriendlyPath: userFriendlyPath,
    );
  }

  factory DownloadResult.permissionDenied(String message) {
    return DownloadResult(
      type: DownloadResultType.permissionDenied,
      message: message,
    );
  }

  factory DownloadResult.networkError(String message) {
    return DownloadResult(
      type: DownloadResultType.networkError,
      message: message,
    );
  }

  factory DownloadResult.storageError(String message) {
    return DownloadResult(
      type: DownloadResultType.storageError,
      message: message,
    );
  }

  factory DownloadResult.cancelled() {
    return const DownloadResult(
      type: DownloadResultType.cancelled,
      message: 'Descarga cancelada por el usuario',
    );
  }

  factory DownloadResult.unknownError(String message) {
    return DownloadResult(
      type: DownloadResultType.unknownError,
      message: message,
    );
  }

  @override
  String toString() =>
      'DownloadResult(type: $type, filePath: $filePath, message: $message)';
}