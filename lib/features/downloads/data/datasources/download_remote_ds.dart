import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;

abstract class DownloadRemoteDataSource {
  Future<Uint8List> downloadFile({
    required String url,
    Function(int received, int total)? onReceiveProgress,
  });
  
  Future<int?> getFileSize(String url);
  Future<void> cancelDownload();
}

class DownloadRemoteDataSourceImpl implements DownloadRemoteDataSource {
  http.Client? _client;
  bool _isCancelled = false;

  @override
  Future<void> cancelDownload() async {
    _isCancelled = true;
    _client?.close();
    _client = null;
  }

  @override
  Future<Uint8List> downloadFile({
    required String url,
    Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      _isCancelled = false;
      _client = http.Client();
      
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);
      request.headers['User-Agent'] = 'NotificationSounds/1.0.0';
      
      final streamedResponse = await _client!.send(request);
      
      if (_isCancelled) {
        throw Exception('Descarga cancelada');
      }
      
      if (streamedResponse.statusCode != 200) {
        final errorMessage = _getErrorMessage(streamedResponse.statusCode);
        throw Exception(errorMessage);
      }
      
      final contentLength = streamedResponse.contentLength ?? 0;
      final bytes = <int>[];
      int downloadedBytes = 0;
      
      await for (final chunk in streamedResponse.stream) {
        if (_isCancelled) {
          throw Exception('Descarga cancelada');
        }
        
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;
        
        if (onReceiveProgress != null && contentLength > 0) {
          onReceiveProgress(downloadedBytes, contentLength);
        }
      }
      
      return Uint8List.fromList(bytes);
      
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } on TimeoutException {
      throw Exception('Tiempo de descarga agotado');
    } on FormatException {
      throw Exception('URL inválida');
    } catch (e) {
      if (e.toString().contains('cancelada')) {
        rethrow;
      }
      throw Exception('Error inesperado: $e');
    } finally {
      _client?.close();
      _client = null;
    }
  }

  @override
  Future<int?> getFileSize(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.head(
        uri,
        headers: {'User-Agent': 'NotificationSounds/1.0.0'},
      ).timeout(const Duration(seconds: 10));
      
      final contentLength = response.headers['content-length'];
      if (contentLength != null) {
        return int.tryParse(contentLength);
      }
      
      return null;
    } on SocketException {
      print('Error de red obteniendo tamaño del archivo');
      return null;
    } on TimeoutException {
      print('Tiempo agotado obteniendo tamaño del archivo');
      return null;
    } catch (e) {
      print('Error inesperado obteniendo tamaño: $e');
      return null;
    }
  }
  
  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 404:
        return 'Archivo no encontrado (404)';
      case 403:
        return 'Acceso denegado al archivo (403)';
      case 401:
        return 'No autorizado (401)';
      case 500:
        return 'Error del servidor (500)';
      case 503:
        return 'Servicio no disponible (503)';
      default:
        return 'Error descargando archivo: $statusCode';
    }
  }
}