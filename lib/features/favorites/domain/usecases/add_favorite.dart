import '../entities/favorite.dart';
import '../repositories/favorites_repository.dart';

class AddFavorite {
  final FavoritesRepository _repository;

  AddFavorite(this._repository);

  Future<void> call(Favorite favorite) async {
    return await _repository.addFavorite(favorite);
  }
}