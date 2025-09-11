import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../../../../core/services/permissions_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/media_store_service.dart';
import '../../../../core/services/filename_service.dart';
import '../../domain/entities/download_info.dart';
import '../../domain/entities/download_result.dart';
import '../../domain/repositories/download_repository.dart';
import '../../../tones/domain/entities/tone.dart';
import '../datasources/download_local_ds.dart';
import '../datasources/download_remote_ds.dart';
import '../models/download_info_model.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  final DownloadRemoteDataSource _remoteDataSource;
  final DownloadLocalDataSource _localDataSource;
  final PermissionsService _permissionsService;
  final StorageService _storageService;
  final MediaStoreService _mediaStoreService;
  final FilenameService _filenameService;
  
  final Map<String, StreamController<DownloadInfo>> _progressControllers = {};
  final Set<String> _activeDownloads = {};

  DownloadRepositoryImpl({
    required DownloadRemoteDataSource remoteDataSource,
    required DownloadLocalDataSource localDataSource,
    required PermissionsService permissionsService,
    required StorageService storageService,
    required MediaStoreService mediaStoreService,
    required FilenameService filenameService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _permissionsService = permissionsService,
        _storageService = storageService,
        _mediaStoreService = mediaStoreService,
        _filenameService = filenameService;

  @override
  Future<DownloadResult> downloadTone({
    required Tone tone,
    Function(double progress)? onProgress,
  }) async {
    // Verificar si ya existe una descarga activa para este tono
    if (_activeDownloads.contains(tone.id)) {
      print('DEBUG: Download already in progress for tone: ${tone.id}');
      return DownloadResult.unknownError('Ya existe una descarga en progreso para este tono');
    }

    // Verificar si el archivo ya está descargado
    final isAlreadyDownloaded = await isFileDownloaded(tone.id);
    if (isAlreadyDownloaded) {
      print('DEBUG: File already downloaded for tone: ${tone.id}');
      return DownloadResult.unknownError('El archivo ya está descargado');
    }

    // Marcar como descarga activa
    _activeDownloads.add(tone.id);
    
    final downloadId = '${tone.id}_${DateTime.now().millisecondsSinceEpoch}';

    StreamController<DownloadInfo>? progressController;
    if (_progressControllers.containsKey(downloadId)) {
      progressController = _progressControllers[downloadId];
    } else {
      progressController = StreamController<DownloadInfo>.broadcast();
      _progressControllers[downloadId] = progressController;
    }

    try {
      // Verificar permisos antes de continuar
      final hasPermissions = await _permissionsService.hasStoragePermissions();
      if (!hasPermissions) {
        final granted = await _permissionsService.requestStoragePermissions();
        if (!granted) {
          return DownloadResult.storageError('Permisos de almacenamiento requeridos');
        }
      }

      // Usar el nuevo servicio profesional de nomenclatura técnica para poder extraer el ID
      final fileName = _filenameService.generateTechnicalFilename(
        title: tone.title,
        url: tone.url,
        toneId: tone.id,
      );

      final downloadInfo = DownloadInfoModel(
        id: downloadId,
        fileName: fileName,
        originalTitle: tone.title, // Almacenar el título original para mostrar al usuario
        url: tone.url,
        localPath: '',
        status: DownloadStatus.waiting,
        createdAt: DateTime.now(),
        requiresAttribution: tone.requiresAttribution,
        attributionText: tone.attributionText,
      );

      await _localDataSource.saveDownload(downloadInfo);
      progressController?.add(downloadInfo);

      final fileSize = await _remoteDataSource.getFileSize(tone.url);
      final downloadInfoWithSize = downloadInfo.copyWith(
        totalBytes: fileSize,
        status: DownloadStatus.downloading,
      );
      
      await _localDataSource.updateDownload(downloadInfoWithSize);
      progressController?.add(downloadInfoWithSize);

      final audioBytes = await _remoteDataSource.downloadFile(
        url: tone.url,
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          final updatedInfo = downloadInfoWithSize.copyWith(
            progress: progress,
            downloadedBytes: received,
            totalBytes: total > 0 ? total : fileSize,
          );
          
          _localDataSource.updateDownload(updatedInfo);
          progressController?.add(updatedInfo);
          onProgress?.call(progress);
        },
      );

      // Usar el MediaStore Service para guardar en almacenamiento público
      final finalPath = await _mediaStoreService.saveAudioToPublicStorage(
        filename: fileName,
        audioBytes: audioBytes,
        subfolder: 'Tonos', // Subcarpeta para organizar
      );

      final completedInfo = downloadInfoWithSize.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        localPath: finalPath,
        completedAt: DateTime.now(),
      );
      
      await _localDataSource.updateDownload(completedInfo);
      progressController?.add(completedInfo);

      _cleanup(downloadId);
      // Remover de descargas activas al completar exitosamente
      _activeDownloads.remove(tone.id);

      final publicDir = await _mediaStoreService.getPublicAudioDirectory();
      final userFriendlyPath = publicDir.replaceAll('/storage/emulated/0/', '/');

      return DownloadResult.success(
        filePath: finalPath,
        userFriendlyPath: userFriendlyPath,
      );

    } catch (e) {
      await _handleDownloadError(downloadId, progressController, e);
      // Remover de descargas activas en caso de error
      _activeDownloads.remove(tone.id);
      
      if (e.toString().contains('cancelada')) {
        return DownloadResult.cancelled();
      } else if (e.toString().contains('conexión') || e.toString().contains('red')) {
        return DownloadResult.networkError('Error de red: $e');
      } else if (e.toString().contains('storage') || e.toString().contains('almacenamiento')) {
        return DownloadResult.storageError('Error de almacenamiento: $e');
      }
      
      return DownloadResult.unknownError('Error inesperado: $e');
    }
  }

  @override
  Future<bool> cancelDownload(String downloadId) async {
    try {
      await _remoteDataSource.cancelDownload();
      
      final download = await _localDataSource.getDownload(downloadId);
      if (download != null) {
        // Extraer el toneId del fileName para remover de descargas activas
        final toneId = _filenameService.extractTechnicalId(download.fileName);
        _activeDownloads.remove(toneId);
        
        final cancelledInfo = download.copyWith(
          status: DownloadStatus.cancelled,
        );
        await _localDataSource.updateDownload(cancelledInfo);
        
        final progressController = _progressControllers[downloadId];
        progressController?.add(cancelledInfo);
      }
      
      _cleanup(downloadId);
      return true;
    } catch (e) {
      print('Error cancelling download: $e');
      return false;
    }
  }

  @override
  Stream<DownloadInfo> getDownloadProgress(String downloadId) {
    if (!_progressControllers.containsKey(downloadId)) {
      _progressControllers[downloadId] = StreamController<DownloadInfo>.broadcast();
    }
    return _progressControllers[downloadId]!.stream;
  }

  @override
  Future<List<DownloadInfo>> getAllDownloads() async {
    final downloads = await _localDataSource.getAllDownloads();
    return downloads.cast<DownloadInfo>();
  }

  @override
  Future<List<DownloadInfo>> getActiveDownloads() async {
    final allDownloads = await getAllDownloads();
    return allDownloads.where((download) => 
      download.status == DownloadStatus.downloading ||
      download.status == DownloadStatus.waiting
    ).toList();
  }

  @override
  Future<bool> deleteDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        
        // El nuevo servicio maneja la eliminación de archivos de forma segura
        await _mediaStoreService.deleteAudioFile(filePath);
        
        final downloads = await getAllDownloads();
        for (final download in downloads) {
          if (download.localPath == filePath) {
            await _localDataSource.deleteDownload(download.id);
            break;
          }
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getDownloadedFiles() async {
    // Usar el MediaStore Service para obtener archivos descargados
    final audioFiles = await _mediaStoreService.getDownloadedAudioFiles();
    return audioFiles.map((audioFile) => audioFile.filePath).toList();
  }

  @override
  Future<bool> isFileDownloaded(String toneId) async {
    final downloads = await getAllDownloads();
    for (final download in downloads) {
      if (download.fileName.contains(toneId) && 
          download.status == DownloadStatus.completed) {
        final file = File(download.localPath);
        if (await file.exists()) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Future<String?> getDownloadedFilePath(String toneId) async {
    final downloads = await getAllDownloads();
    for (final download in downloads) {
      if (download.fileName.contains(toneId) && 
          download.status == DownloadStatus.completed) {
        final file = File(download.localPath);
        if (await file.exists()) {
          return download.localPath;
        }
      }
    }
    return null;
  }

  // Método removido - ahora se usa FilenameService para nomenclatura profesional

  Future<void> _ensureDirectoryExists(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<void> _handleDownloadError(
    String downloadId,
    StreamController<DownloadInfo>? progressController,
    dynamic error,
  ) async {
    try {
      final download = await _localDataSource.getDownload(downloadId);
      if (download != null) {
        final errorInfo = download.copyWith(
          status: DownloadStatus.failed,
          errorMessage: error.toString(),
        );
        await _localDataSource.updateDownload(errorInfo);
        progressController?.add(errorInfo);
      }
    } catch (e) {
      print('Error handling download error: $e');
    }
    
    _cleanup(downloadId);
  }

  void _cleanup(String downloadId) {
    _progressControllers[downloadId]?.close();
    _progressControllers.remove(downloadId);
  }

  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _activeDownloads.clear();
  }
}