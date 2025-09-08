import '../repositories/download_repository.dart';

class IsFileDownloaded {
  final DownloadRepository repository;

  const IsFileDownloaded(this.repository);

  Future<bool> call(String toneId) async {
    return await repository.isFileDownloaded(toneId);
  }
}