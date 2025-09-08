import '../entities/download_info.dart';
import '../entities/download_result.dart';
import '../../../tones/domain/entities/tone.dart';

abstract class DownloadRepository {
  Future<DownloadResult> downloadTone({
    required Tone tone,
    Function(double progress)? onProgress,
  });
  
  Future<bool> cancelDownload(String downloadId);
  
  Stream<DownloadInfo> getDownloadProgress(String downloadId);
  
  Future<List<DownloadInfo>> getAllDownloads();
  
  Future<List<DownloadInfo>> getActiveDownloads();
  
  Future<bool> deleteDownloadedFile(String filePath);
  
  Future<List<String>> getDownloadedFiles();
  
  Future<bool> isFileDownloaded(String toneId);
  
  Future<String?> getDownloadedFilePath(String toneId);
}