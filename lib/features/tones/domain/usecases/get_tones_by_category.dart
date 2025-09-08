import '../entities/tone.dart';
import '../repositories/tones_repository.dart';

class GetTonesByCategory {
  final TonesRepository _repository;

  GetTonesByCategory(this._repository);

  Future<List<Tone>> call(String categoryId, {int? limit, int? offset}) async {
    return await _repository.getByCategory(
      categoryId,
      limit: limit,
      offset: offset,
    );
  }
}
