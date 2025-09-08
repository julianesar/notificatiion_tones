import '../repositories/favorites_repository.dart';

class IsFavorite {
  final FavoritesRepository _repository;

  IsFavorite(this._repository);

  Future<bool> call(String toneId) async {
    return await _repository.isFavorite(toneId);
  }
}