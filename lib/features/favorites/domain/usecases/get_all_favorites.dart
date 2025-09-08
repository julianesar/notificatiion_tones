import '../entities/favorite.dart';
import '../repositories/favorites_repository.dart';

class GetAllFavorites {
  final FavoritesRepository _repository;

  GetAllFavorites(this._repository);

  Future<List<Favorite>> call() async {
    return await _repository.getAllFavorites();
  }
}