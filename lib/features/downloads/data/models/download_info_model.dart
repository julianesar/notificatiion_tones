import '../../domain/entities/download_info.dart';

class DownloadInfoModel extends DownloadInfo {
  const DownloadInfoModel({
    required super.id,
    required super.fileName,
    required super.originalTitle,
    required super.url,
    required super.localPath,
    required super.status,
    super.progress = 0.0,
    super.totalBytes,
    super.downloadedBytes,
    super.errorMessage,
    required super.createdAt,
    super.completedAt,
    super.requiresAttribution = false,
    super.attributionText,
  });

  factory DownloadInfoModel.fromJson(Map<String, dynamic> json) {
    return DownloadInfoModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      originalTitle: json['originalTitle'] as String? ?? json['fileName'] as String, // Fallback para compatibilidad
      url: json['url'] as String,
      localPath: json['localPath'] as String,
      status: DownloadStatus.values[json['status'] as int],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      totalBytes: json['totalBytes'] as int?,
      downloadedBytes: json['downloadedBytes'] as int?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      requiresAttribution: json['requiresAttribution'] == true,
      attributionText: json['attributionText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'originalTitle': originalTitle,
      'url': url,
      'localPath': localPath,
      'status': status.index,
      'progress': progress,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'requiresAttribution': requiresAttribution,
      'attributionText': attributionText,
    };
  }

  @override
  DownloadInfoModel copyWith({
    String? id,
    String? fileName,
    String? originalTitle,
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
    return DownloadInfoModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      originalTitle: originalTitle ?? this.originalTitle,
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
}