import '../repositories/favorites_repository.dart';

class RemoveFavorite {
  final FavoritesRepository _repository;

  RemoveFavorite(this._repository);

  Future<void> call(String toneId) async {
    return await _repository.removeFavorite(toneId);
  }
}