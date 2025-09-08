import '../entities/favorite.dart';
import '../repositories/favorites_repository.dart';
import 'add_favorite.dart';
import 'remove_favorite.dart';
import 'is_favorite.dart';

class ToggleFavorite {
  final FavoritesRepository _repository;
  late final AddFavorite _addFavorite;
  late final RemoveFavorite _removeFavorite;
  late final IsFavorite _isFavorite;

  ToggleFavorite(this._repository) {
    _addFavorite = AddFavorite(_repository);
    _removeFavorite = RemoveFavorite(_repository);
    _isFavorite = IsFavorite(_repository);
  }

  Future<bool> call(String toneId, String title, String url) async {
    final isFav = await _isFavorite.call(toneId);
    
    if (isFav) {
      await _removeFavorite.call(toneId);
      return false;
    } else {
      final favorite = Favorite(
        toneId: toneId,
        title: title,
        url: url,
        createdAt: DateTime.now(),
      );
      await _addFavorite.call(favorite);
      return true;
    }
  }
}