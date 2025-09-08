import 'package:flutter/foundation.dart';

enum DownloadStatus {
  waiting,
  downloading,
  completed,
  failed,
  cancelled,
}

@immutable
class DownloadInfo {
  final String id;
  final String fileName;
  final String url;
  final String localPath;
  final DownloadStatus status;
  final double progress;
  final int? totalBytes;
  final int? downloadedBytes;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool requiresAttribution;
  final String? attributionText;

  const DownloadInfo({
    required this.id,
    required this.fileName,
    required this.url,
    required this.localPath,
    required this.status,
    this.progress = 0.0,
    this.totalBytes,
    this.downloadedBytes,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    this.requiresAttribution = false,
    this.attributionText,
  });

  DownloadInfo copyWith({
    String? id,
    String? fileName,
    String? url,
    String? localPath,
    DownloadStatus? status,
    double? progress,
    int? totalBytes,
    int? downloadedBytes,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? requiresAttribution,
    String? attributionText,
  }) {
    return DownloadInfo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      requiresAttribution: requiresAttribution ?? this.requiresAttribution,
      attributionText: attributionText ?? this.attributionText,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DownloadInfo(id: $id, fileName: $fileName, status: $status, progress: $progress, requiresAttribution: $requiresAttribution, attributionText: $attributionText)';
}