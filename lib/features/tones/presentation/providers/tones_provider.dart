import 'package:flutter/foundation.dart';
import '../../domain/entities/tone.dart';
import '../../domain/usecases/get_tones_by_category.dart';

enum TonesProviderState { loading, ready, error }

class TonesProvider with ChangeNotifier {
  final GetTonesByCategory _getTonesByCategory;

  TonesProviderState _state = TonesProviderState.ready;
  final Map<String, List<Tone>> _tonesByCategory = {};
  final Map<String, int> _nextOffsetByCategory = {};
  final Map<String, bool> _loadingByCategory = {};
  String? _errorMessage;
  String? _currentLoadingCategory;

  TonesProvider(this._getTonesByCategory);

  // Getters
  TonesProviderState get state => _state;
  Map<String, List<Tone>> get tonesByCategory =>
      Map.unmodifiable(_tonesByCategory);
  String? get errorMessage => _errorMessage;
  String? get currentLoadingCategory => _currentLoadingCategory;

  bool get isLoading => _state == TonesProviderState.loading;
  bool get hasError => _state == TonesProviderState.error;
  bool get isReady => _state == TonesProviderState.ready;

  List<Tone> getTonesForCategory(String categoryId) {
    return _tonesByCategory[categoryId] ?? [];
  }

  bool isCategoryLoading(String categoryId) {
    return _loadingByCategory[categoryId] ?? false;
  }

  int getNextOffset(String categoryId) {
    return _nextOffsetByCategory[categoryId] ?? 0;
  }

  bool hasMoreTones(String categoryId) {
    // Si no tenemos nextOffset registrado, asumimos que hay más
    // Si nextOffset es -1, significa que no hay más
    final nextOffset = _nextOffsetByCategory[categoryId];
    return nextOffset == null || nextOffset != -1;
  }

  Future<void> load(
    String categoryId, {
    int limit = 100,
    int offset = 0,
  }) async {
    // Evitar múltiples cargas simultáneas para la misma categoría
    if (_loadingByCategory[categoryId] == true) {
      return;
    }

    bool shouldNotify = false;

    try {
      // Marcar esta categoría como cargando
      if (_loadingByCategory[categoryId] != true) {
        _loadingByCategory[categoryId] = true;
        _currentLoadingCategory = categoryId;
        shouldNotify = true;
      }

      if (offset == 0 && _state != TonesProviderState.loading) {
        _state = TonesProviderState.loading;
        shouldNotify = true;
      }

      if (_errorMessage != null) {
        _errorMessage = null;
        shouldNotify = true;
      }

      if (shouldNotify) {
        notifyListeners();
      }

      final tones = await _getTonesByCategory.call(
        categoryId,
        limit: limit,
        offset: offset,
      );

      shouldNotify = false;
      List<Tone> newTones;

      if (offset == 0) {
        // Reemplazar la lista completa
        newTones = tones;
        if (!_listsEqual(_tonesByCategory[categoryId] ?? [], newTones)) {
          _tonesByCategory[categoryId] = newTones;
          shouldNotify = true;
        }
      } else {
        // Concatenar a la lista existente
        final existingTones = _tonesByCategory[categoryId] ?? [];
        newTones = [...existingTones, ...tones];
        if (!_listsEqual(_tonesByCategory[categoryId] ?? [], newTones)) {
          _tonesByCategory[categoryId] = newTones;
          shouldNotify = true;
        }
      }

      // Calcular el siguiente offset
      final newNextOffset = tones.length < limit ? -1 : offset + tones.length;
      if (_nextOffsetByCategory[categoryId] != newNextOffset) {
        _nextOffsetByCategory[categoryId] = newNextOffset;
        shouldNotify = true;
      }

      _loadingByCategory[categoryId] = false;
      _currentLoadingCategory = null;
      if (_state != TonesProviderState.ready) {
        _state = TonesProviderState.ready;
        shouldNotify = true;
      }

      if (shouldNotify) {
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _state = TonesProviderState.error;
      _errorMessage = e.toString();
      _loadingByCategory[categoryId] = false;
      _currentLoadingCategory = null;

      if (kDebugMode) {
        print('TonesProvider error for category $categoryId: $e');
        print('Stack trace: $stackTrace');
      }

      notifyListeners();
    }
  }

  bool _listsEqual(List<Tone> list1, List<Tone> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  Future<void> loadMore(String categoryId, {int limit = 100}) async {
    if (!hasMoreTones(categoryId) || isCategoryLoading(categoryId)) {
      return;
    }

    final nextOffset = getNextOffset(categoryId);
    await load(categoryId, limit: limit, offset: nextOffset);
  }

  void retry(String categoryId) {
    load(categoryId);
  }

  void clearCategory(String categoryId) {
    final hadData =
        _tonesByCategory.containsKey(categoryId) ||
        _nextOffsetByCategory.containsKey(categoryId) ||
        _loadingByCategory.containsKey(categoryId);

    if (hadData) {
      _tonesByCategory.remove(categoryId);
      _nextOffsetByCategory.remove(categoryId);
      _loadingByCategory.remove(categoryId);
      notifyListeners();
    }
  }

  void clearAll() {
    final hasData =
        _tonesByCategory.isNotEmpty ||
        _nextOffsetByCategory.isNotEmpty ||
        _loadingByCategory.isNotEmpty ||
        _state != TonesProviderState.ready ||
        _errorMessage != null ||
        _currentLoadingCategory != null;

    if (hasData) {
      _tonesByCategory.clear();
      _nextOffsetByCategory.clear();
      _loadingByCategory.clear();
      _state = TonesProviderState.ready;
      _errorMessage = null;
      _currentLoadingCategory = null;
      notifyListeners();
    }
  }
}
