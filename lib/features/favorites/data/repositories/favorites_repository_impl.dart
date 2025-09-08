import '../../domain/entities/favorite.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_ds.dart';
import '../models/favorite_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesLocalDS _localDataSource;

  FavoritesRepositoryImpl(this._localDataSource);

  @override
  Future<List<Favorite>> getAllFavorites() async {
    final favoriteModels = await _localDataSource.getAllFavorites();
    return favoriteModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> addFavorite(Favorite favorite) async {
    final favoriteModel = FavoriteModel.fromEntity(favorite);
    await _localDataSource.addFavorite(favoriteModel);
  }

  @override
  Future<void> removeFavorite(String toneId) async {
    await _localDataSource.removeFavorite(toneId);
  }

  @override
  Future<bool> isFavorite(String toneId) async {
    return await _localDataSource.isFavorite(toneId);
  }

  @override
  Future<void> clearAllFavorites() async {
    await _localDataSource.clearAllFavorites();
  }
}