import '../repositories/download_repository.dart';

class GetDownloadedFiles {
  final DownloadRepository repository;

  const GetDownloadedFiles(this.repository);

  Future<List<String>> call() async {
    return await repository.getDownloadedFiles();
  }
}