import '../../domain/entities/tone.dart';
import '../../domain/repositories/tones_repository.dart';
import '../datasources/tones_remote_ds.dart';

class TonesRepositoryImpl implements TonesRepository {
  final TonesRemoteDS _remoteDataSource;

  TonesRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Tone>> getByCategory(String id, {int? limit, int? offset}) async {
    final toneModels = await _remoteDataSource.fetchTones(
      id,
      limit: limit ?? 100,
      offset: offset ?? 0,
    );
    return toneModels.map((model) => model.toEntity()).toList();
  }
}
