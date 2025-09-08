import '../repositories/favorites_repository.dart';

class ClearAllFavorites {
  final FavoritesRepository _repository;

  ClearAllFavorites(this._repository);

  Future<void> call() async {
    return await _repository.clearAllFavorites();
  }
}