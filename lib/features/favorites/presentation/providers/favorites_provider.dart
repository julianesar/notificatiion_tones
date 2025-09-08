import 'package:flutter/foundation.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/usecases/get_all_favorites.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../../domain/usecases/is_favorite.dart';
import '../../domain/usecases/clear_all_favorites.dart';

class FavoritesProvider extends ChangeNotifier {
  final GetAllFavorites _getAllFavorites;
  final ToggleFavorite _toggleFavorite;
  final IsFavorite _isFavorite;
  final ClearAllFavorites _clearAllFavorites;

  FavoritesProvider({
    required GetAllFavorites getAllFavorites,
    required ToggleFavorite toggleFavorite,
    required IsFavorite isFavorite,
    required ClearAllFavorites clearAllFavorites,
  })  : _getAllFavorites = getAllFavorites,
        _toggleFavorite = toggleFavorite,
        _isFavorite = isFavorite,
        _clearAllFavorites = clearAllFavorites;

  List<Favorite> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, bool> _favoriteStatus = {};

  List<Favorite> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFavorites() async {
    _setLoading(true);
    try {
      _favorites = await _getAllFavorites();
      _updateFavoriteStatusMap();
      _clearError();
    } catch (e) {
      _setError('Error al cargar favoritos: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleFavoriteStatus(String toneId, String title, String url) async {
    try {
      final newStatus = await _toggleFavorite(toneId, title, url);
      _favoriteStatus[toneId] = newStatus;
      
      // Reload favorites to keep the list updated
      await loadFavorites();
      
      return newStatus;
    } catch (e) {
      _setError('Error al cambiar estado de favorito: $e');
      return false;
    }
  }

  Future<bool> checkFavoriteStatus(String toneId) async {
    // Return cached status if available
    if (_favoriteStatus.containsKey(toneId)) {
      return _favoriteStatus[toneId]!;
    }

    try {
      final isFav = await _isFavorite(toneId);
      _favoriteStatus[toneId] = isFav;
      return isFav;
    } catch (e) {
      _setError('Error al verificar estado de favorito: $e');
      return false;
    }
  }

  bool isFavoriteSync(String toneId) {
    return _favoriteStatus[toneId] ?? false;
  }

  Future<void> clearAllFavorites() async {
    _setLoading(true);
    try {
      await _clearAllFavorites();
      _favorites.clear();
      _favoriteStatus.clear();
      _clearError();
    } catch (e) {
      _setError('Error al limpiar favoritos: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _updateFavoriteStatusMap() {
    _favoriteStatus.clear();
    for (final favorite in _favorites) {
      _favoriteStatus[favorite.toneId] = true;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _favorites.clear();
    _favoriteStatus.clear();
    super.dispose();
  }
}