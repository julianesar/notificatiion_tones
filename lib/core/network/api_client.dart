import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class ApiClient {
  static ApiClient? _instance;
  late SharedPreferences _prefs;

  ApiClient._internal();

  static Future<ApiClient> getInstance() async {
    if (_instance == null) {
      _instance = ApiClient._internal();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  void _log(String message) {
    if (AppConfig.I().enableLogging) {
      print('[ApiClient] $message');
    }
  }

  Future<http.Response> _get(Uri uri) async {
    _log('GET $uri');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      _log('Response ${response.statusCode}: ${response.body.length} chars');
      return response;
    } on SocketException catch (e) {
      _log('Network error: $e. Retrying...');
      // Reintento simple en caso de error de red
      await Future.delayed(const Duration(seconds: 1));
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      _log(
        'Retry response ${response.statusCode}: ${response.body.length} chars',
      );
      return response;
    } on HttpException catch (e) {
      _log('HTTP error: $e. Retrying...');
      // Reintento simple en caso de error HTTP
      await Future.delayed(const Duration(seconds: 1));
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      _log(
        'Retry response ${response.statusCode}: ${response.body.length} chars',
      );
      return response;
    } catch (e) {
      // Si el primer intento falla con error 5xx o timeout, reintentamos
      if (e.toString().contains('TimeoutException')) {
        _log('Timeout error: $e. Retrying...');
        await Future.delayed(const Duration(seconds: 1));
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 8));
        _log(
          'Retry response ${response.statusCode}: ${response.body.length} chars',
        );
        return response;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    String? cacheKey,
    Duration? customTtl,
  }) async {
    // Construir URI usando AppConfig.I().baseUrl
    final baseUri = Uri.parse(AppConfig.I().baseUrl);
    final uri = baseUri.replace(
      path: '${baseUri.path}$path',
      queryParameters: query,
    );

    _log('getJson: $path, cacheKey: $cacheKey, query: $query');

    // Intentar leer del caché si cacheKey está definido
    if (cacheKey != null) {
      final cachedData = _prefs.getString('cache:$cacheKey');
      final cachedTimestamp = _prefs.getInt('cache:$cacheKey:ts');

      if (cachedData != null && cachedTimestamp != null) {
        final cacheAge =
            DateTime.now().millisecondsSinceEpoch - cachedTimestamp;

        // Usar TTL personalizado o determinarlo por endpoint
        final effectiveTtl = customTtl ?? AppConfig.I().getCacheTtlForEndpoint(path);
        final isExpired = cacheAge > effectiveTtl.inMilliseconds;

        if (!isExpired) {
          _log('Cache hit for $cacheKey (age: ${cacheAge}ms, TTL: ${effectiveTtl.inMinutes}min)');
          final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;

          // Refrescar en background si el caché está próximo a expirar (75% de TTL)
          final shouldRefresh = cacheAge > (effectiveTtl.inMilliseconds * 0.75);
          if (shouldRefresh) {
            _log('Background refresh for $cacheKey (age: ${(cacheAge / 60000).toStringAsFixed(1)}min)');
            _refreshInBackground(uri, cacheKey);
          }

          return jsonData;
        } else {
          _log('Cache expired for $cacheKey (age: ${(cacheAge / 60000).toStringAsFixed(1)}min, TTL: ${effectiveTtl.inMinutes}min)');
        }
      } else {
        _log('No cache found for $cacheKey');
      }
    }

    // Hacer la petición HTTP
    final response = await _get(uri);

    // Verificar si hay error 5xx y reintentar
    if (response.statusCode >= 500 && response.statusCode < 600) {
      _log('Server error ${response.statusCode}. Retrying...');
      await Future.delayed(const Duration(seconds: 1));
      final retryResponse = await _get(uri);
      return _processResponse(retryResponse, cacheKey);
    }

    return _processResponse(response, cacheKey);
  }

  Map<String, dynamic> _processResponse(
    http.Response response,
    String? cacheKey,
  ) {
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      // Guardar en caché si cacheKey está definido
      if (cacheKey != null) {
        _saveToCache(cacheKey, response.body);
        _log('Saved to cache: $cacheKey');
      }

      return jsonData;
    } else {
      _log('HTTP Error ${response.statusCode}: ${response.body}');
      throw HttpException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }

  void _saveToCache(String cacheKey, String data) {
    _prefs.setString('cache:$cacheKey', data);
    _prefs.setInt('cache:$cacheKey:ts', DateTime.now().millisecondsSinceEpoch);
  }

  void _refreshInBackground(Uri uri, String cacheKey) {
    // No await - ejecutar en background
    _get(uri)
        .then((response) {
          if (response.statusCode == 200) {
            _saveToCache(cacheKey, response.body);
            _log('Background refresh completed for $cacheKey');
          }
        })
        .catchError((error) {
          _log('Background refresh failed for $cacheKey: $error');
        });
  }
}
