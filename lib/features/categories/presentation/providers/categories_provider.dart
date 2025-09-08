import 'package:flutter/foundation.dart';
import '../../domain/entities/category.dart' as domain;
import '../../domain/usecases/get_categories.dart';

enum CategoriesProviderState { idle, loading, ready, error }

class CategoriesProvider with ChangeNotifier {
  final GetCategories _getCategories;

  CategoriesProviderState _state = CategoriesProviderState.idle;
  List<domain.Category> _categories = [];
  String? _errorMessage;

  CategoriesProvider(this._getCategories);

  // Getters
  CategoriesProviderState get state => _state;
  List<domain.Category> get categories => List.unmodifiable(_categories);
  String? get errorMessage => _errorMessage;

  bool get isIdle => _state == CategoriesProviderState.idle;
  bool get isLoading => _state == CategoriesProviderState.loading;
  bool get hasError => _state == CategoriesProviderState.error;
  bool get isReady => _state == CategoriesProviderState.ready;

  Future<void> load() async {
    if (_state == CategoriesProviderState.loading) return;

    try {
      _setState(CategoriesProviderState.loading, null, _categories);
      final categories = await _getCategories.call();
      _setState(CategoriesProviderState.ready, null, categories);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('CategoriesProvider error: $e');
        print('Stack trace: $stackTrace');
      }
      _setState(CategoriesProviderState.error, e.toString(), []);
    }
  }

  void _setState(
    CategoriesProviderState newState,
    String? newErrorMessage,
    List<domain.Category> newCategories,
  ) {
    if (_state != newState ||
        _errorMessage != newErrorMessage ||
        !_listsEqual(_categories, newCategories)) {
      _state = newState;
      _errorMessage = newErrorMessage;
      _categories = newCategories;
      notifyListeners();
    }
  }

  bool _listsEqual(List<domain.Category> list1, List<domain.Category> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  void retry() {
    load();
  }
}
