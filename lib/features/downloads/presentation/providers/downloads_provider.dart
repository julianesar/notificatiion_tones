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
    // Primary check: direct ID match
    if (_downloadedToneIds.contains(toneId)) {
      print('DEBUG: isDownloaded($toneId) = true (direct match)');
      return true;
    }
    
    // Secondary check: look through actual download files
    for (final download in _downloads.values) {
      if (download.status == DownloadStatus.completed) {
        // Strategy 1: fileName contains toneId
        if (download.fileName.contains(toneId)) {
          print('DEBUG: isDownloaded($toneId) = true (fileName contains)');
          return true;
        }
        
        // Strategy 2: extract toneId from fileName
        final extractedId = _extractToneIdFromFileName(download.fileName);
        if (extractedId == toneId) {
          print('DEBUG: isDownloaded($toneId) = true (extracted ID match)');
          return true;
        }
        
        // Strategy 3: fileName starts with toneId
        if (download.fileName.startsWith(toneId + '_')) {
          print('DEBUG: isDownloaded($toneId) = true (startsWith match)');
          return true;
        }
      }
    }
    
    print('DEBUG: isDownloaded($toneId) = false. Downloaded IDs: $_downloadedToneIds');
    print('DEBUG: Available files: ${_downloads.values.where((d) => d.status == DownloadStatus.completed).map((d) => d.fileName).toList()}');
    
    return false;
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
          print('DEBUG: Archivo ${download.fileName} -> toneId: $toneId'); // Debug
          print('DEBUG: ToneId extracted length: ${toneId.length}, bytes: ${toneId.codeUnits}'); // Debug
          print('DEBUG: Download info - requiresAttribution: ${download.requiresAttribution}, attributionText: ${download.attributionText}'); // Debug
          if (toneId.isNotEmpty) {
            _downloadedToneIds.add(toneId);
            print('DEBUG: Agregado toneId $toneId a downloadedToneIds'); // Debug
          } else {
            print('DEBUG: ERROR: ToneId is empty for file: ${download.fileName}'); // Debug
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
    // El nombre del archivo tiene formato: toneId_cleanTitle.extension
    // Estrategia mejorada: priorizar métodos más confiables
    
    // Remover la extensión primero
    final nameWithoutExtension = fileName.contains('.') 
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    
    print('DEBUG: Extracting toneId from: $nameWithoutExtension');
    
    // Método 1: Buscar el primer _ que separe un ID válido de un título
    final parts = nameWithoutExtension.split('_');
    if (parts.length >= 2) {
      final potentialId = parts[0];
      final remainingParts = parts.skip(1).join('_');
      
      // Verificar si el primer parte parece ser un toneId válido
      final hasNumbers = RegExp(r'\d').hasMatch(potentialId);
      final hasValidIdChars = RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(potentialId);
      final remainingStartsWithCapital = remainingParts.isNotEmpty && 
                                        remainingParts[0].toUpperCase() == remainingParts[0] &&
                                        remainingParts[0].toLowerCase() != remainingParts[0];
      
      if (hasNumbers && hasValidIdChars && (remainingStartsWithCapital || potentialId.contains('-') || potentialId.contains('__'))) {
        print('DEBUG: Extracted toneId using Method 1: $potentialId');
        return potentialId;
      }
    }
    
    // Método 2: Buscar patrones específicos de IDs como freesound__123456-7
    final freesoundPattern = RegExp(r'^([a-zA-Z0-9_-]+__\d+-?\d*)_');
    final freesoundMatch = freesoundPattern.firstMatch(nameWithoutExtension);
    if (freesoundMatch != null) {
      final extractedId = freesoundMatch.group(1)!;
      print('DEBUG: Extracted toneId using Method 2 (freesound pattern): $extractedId');
      return extractedId;
    }
    
    // Método 3: Buscar cualquier secuencia que termine con números antes de _
    final numberPattern = RegExp(r'^([a-zA-Z0-9_-]*\d+[a-zA-Z0-9_-]*)_');
    final numberMatch = numberPattern.firstMatch(nameWithoutExtension);
    if (numberMatch != null) {
      final extractedId = numberMatch.group(1)!;
      print('DEBUG: Extracted toneId using Method 3 (number pattern): $extractedId');
      return extractedId;
    }
    
    // Método 4: Fallback simple - primer segmento
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      print('DEBUG: Extracted toneId using Method 4 (fallback): ${parts[0]}');
      return parts[0];
    }
    
    print('DEBUG: Could not extract toneId from: $fileName');
    return '';
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