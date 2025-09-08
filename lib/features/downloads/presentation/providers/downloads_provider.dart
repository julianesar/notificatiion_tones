import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/download_info.dart';
import '../../domain/entities/download_result.dart';
import '../../domain/usecases/download_tone.dart';
import '../../domain/usecases/get_downloaded_files.dart';
import '../../domain/usecases/is_file_downloaded.dart';
import '../../domain/repositories/download_repository.dart';
import '../../../tones/domain/entities/tone.dart';

class DownloadsProvider extends ChangeNotifier {
  final DownloadTone _downloadTone;
  final GetDownloadedFiles _getDownloadedFiles;
  final IsFileDownloaded _isFileDownloaded;
  final DownloadRepository _downloadRepository;

  final Map<String, DownloadInfo> _downloads = {};
  final Map<String, StreamSubscription> _progressSubscriptions = {};
  final Set<String> _downloadedToneIds = {};
  final Set<String> _initiatingDownloads = {}; // Para mostrar feedback inmediato
  
  bool _isLoading = false;
  String? _error;

  DownloadsProvider({
    required DownloadTone downloadTone,
    required GetDownloadedFiles getDownloadedFiles,
    required IsFileDownloaded isFileDownloaded,
    required DownloadRepository downloadRepository,
  })  : _downloadTone = downloadTone,
        _getDownloadedFiles = getDownloadedFiles,
        _isFileDownloaded = isFileDownloaded,
        _downloadRepository = downloadRepository {
    _loadDownloadedFiles();
  }

  Map<String, DownloadInfo> get downloads => Map.unmodifiable(_downloads);
  List<DownloadInfo> get downloadsList => _downloads.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error;
  bool get hasError => _error != null;
  Set<String> get downloadedToneIds => Set.unmodifiable(_downloadedToneIds);
  String? get storageLocation => 'Download/NotificationSounds/';

  bool isDownloading(String toneId) {
    return _initiatingDownloads.contains(toneId) || 
           _downloads.values.any((download) =>
               download.fileName.contains(toneId) &&
               (download.status == DownloadStatus.downloading ||
                download.status == DownloadStatus.waiting));
  }

  bool isInitiatingDownload(String toneId) {
    return _initiatingDownloads.contains(toneId);
  }

  bool isDownloaded(String toneId) {
    return _downloadedToneIds.contains(toneId);
  }

  double getDownloadProgress(String toneId) {
    final download = _downloads.values.firstWhere(
      (d) => d.fileName.contains(toneId) && 
             (d.status == DownloadStatus.downloading || 
              d.status == DownloadStatus.waiting),
      orElse: () => DownloadInfo(
        id: '',
        fileName: '',
        url: '',
        localPath: '',
        status: DownloadStatus.completed,
        createdAt: DateTime.now(),
      ),
    );
    
    return download.progress;
  }

  Future<DownloadResult> downloadTone(Tone tone) async {
    // Feedback inmediato: mostrar que la descarga está iniciando
    _initiatingDownloads.add(tone.id);
    _error = null;
    notifyListeners();

    try {
      final result = await _downloadTone(
        tone: tone,
        onProgress: (progress) {
          // El progreso se maneja a través del stream
        },
      );

      // Remover del estado "iniciando" una vez que la descarga real comience
      _initiatingDownloads.remove(tone.id);

      if (result.isSuccess) {
        _downloadedToneIds.add(tone.id);
        _subscribeToProgress(tone.id);
      }

      notifyListeners();
      return result;
      
    } catch (e) {
      // Remover del estado "iniciando" si hay error
      _initiatingDownloads.remove(tone.id);
      _error = e.toString();
      notifyListeners();
      return DownloadResult.unknownError(_error!);
    }
  }

  Future<void> cancelDownload(String toneId) async {
    try {
      // Si está en estado "iniciando", simplemente removerlo
      if (_initiatingDownloads.contains(toneId)) {
        _initiatingDownloads.remove(toneId);
        notifyListeners();
        return;
      }

      final download = _downloads.values.firstWhere(
        (d) => d.fileName.contains(toneId),
        orElse: () => DownloadInfo(
          id: '',
          fileName: '',
          url: '',
          localPath: '',
          status: DownloadStatus.completed,
          createdAt: DateTime.now(),
        ),
      );

      if (download.id.isNotEmpty) {
        await _downloadRepository.cancelDownload(download.id);
        _cleanupProgressSubscription(download.id);
        _downloads.remove(download.id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDownloadedFile(String toneId) async {
    try {
      final filePath = await _downloadRepository.getDownloadedFilePath(toneId);
      if (filePath != null) {
        final deleted = await _downloadRepository.deleteDownloadedFile(filePath);
        if (deleted) {
          _downloadedToneIds.remove(toneId);
          
          final downloadToRemove = _downloads.values.where(
            (d) => d.localPath == filePath,
          );
          
          for (final download in downloadToRemove) {
            _downloads.remove(download.id);
            _cleanupProgressSubscription(download.id);
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshDownloadedFiles() async {
    await _loadDownloadedFiles();
  }
  
  Future<void> loadDownloads() async {
    await _loadDownloadedFiles();
  }
  
  Future<bool> deleteDownload(String filePath) async {
    try {
      final deleted = await _downloadRepository.deleteDownloadedFile(filePath);
      if (deleted) {
        // Buscar el download por path y removerlo
        final downloadToRemove = _downloads.values
            .where((d) => d.localPath == filePath)
            .toList();
        
        for (final download in downloadToRemove) {
          _downloads.remove(download.id);
          _cleanupProgressSubscription(download.id);
          
          // Remover de downloaded tone IDs también
          final toneId = _extractToneIdFromFileName(download.fileName);
          if (toneId.isNotEmpty) {
            _downloadedToneIds.remove(toneId);
          }
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _subscribeToProgress(String toneId) {
    try {
      final downloads = _downloads.values.where(
        (d) => d.fileName.contains(toneId),
      );

      for (final download in downloads) {
        if (_progressSubscriptions.containsKey(download.id)) {
          continue; 
        }

        final subscription = _downloadRepository
            .getDownloadProgress(download.id)
            .listen(
          (downloadInfo) {
            _downloads[downloadInfo.id] = downloadInfo;
            
            if (downloadInfo.status == DownloadStatus.completed) {
              _downloadedToneIds.add(toneId);
              _cleanupProgressSubscription(downloadInfo.id);
            } else if (downloadInfo.status == DownloadStatus.failed ||
                       downloadInfo.status == DownloadStatus.cancelled) {
              _cleanupProgressSubscription(downloadInfo.id);
            }
            
            notifyListeners();
          },
          onError: (error) {
            print('Error en progreso de descarga: $error');
            _cleanupProgressSubscription(download.id);
          },
        );

        _progressSubscriptions[download.id] = subscription;
      }
    } catch (e) {
      print('Error configurando progreso: $e');
    }
  }

  void _cleanupProgressSubscription(String downloadId) {
    final subscription = _progressSubscriptions[downloadId];
    subscription?.cancel();
    _progressSubscriptions.remove(downloadId);
  }

  Future<void> _loadDownloadedFiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allDownloads = await _downloadRepository.getAllDownloads();
      
      _downloads.clear();
      _downloadedToneIds.clear();
      
      for (final download in allDownloads) {
        _downloads[download.id] = download;
        
        if (download.status == DownloadStatus.completed) {
          final toneId = _extractToneIdFromFileName(download.fileName);
          if (toneId.isNotEmpty) {
            _downloadedToneIds.add(toneId);
          }
        } else if (download.status == DownloadStatus.downloading ||
                   download.status == DownloadStatus.waiting) {
          final toneId = _extractToneIdFromFileName(download.fileName);
          if (toneId.isNotEmpty) {
            _subscribeToProgress(toneId);
          }
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractToneIdFromFileName(String fileName) {
    return fileName.split('_').first;
  }

  @override
  void dispose() {
    for (final subscription in _progressSubscriptions.values) {
      subscription.cancel();
    }
    _progressSubscriptions.clear();
    super.dispose();
  }
}