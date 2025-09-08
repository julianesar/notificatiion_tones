import '../entities/favorite.dart';

abstract class FavoritesRepository {
  Future<List<Favorite>> getAllFavorites();
  Future<void> addFavorite(Favorite favorite);
  Future<void> removeFavorite(String toneId);
  Future<bool> isFavorite(String toneId);
  Future<void> clearAllFavorites();
}