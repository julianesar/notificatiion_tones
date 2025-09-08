import '../entities/download_result.dart';
import '../repositories/download_repository.dart';
import '../../../tones/domain/entities/tone.dart';

class DownloadTone {
  final DownloadRepository repository;

  const DownloadTone(this.repository);

  Future<DownloadResult> call({
    required Tone tone,
    Function(double progress)? onProgress,
  }) async {
    return await repository.downloadTone(
      tone: tone,
      onProgress: onProgress,
    );
  }
}