import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_info_model.dart';

abstract class DownloadLocalDataSource {
  Future<List<DownloadInfoModel>> getAllDownloads();
  Future<void> saveDownload(DownloadInfoModel download);
  Future<void> updateDownload(DownloadInfoModel download);
  Future<void> deleteDownload(String downloadId);
  Future<DownloadInfoModel?> getDownload(String downloadId);
  Future<void> clearAllDownloads();
}

class DownloadLocalDataSourceImpl implements DownloadLocalDataSource {
  static const String _downloadsKey = 'downloads';

  @override
  Future<List<DownloadInfoModel>> getAllDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getStringList(_downloadsKey) ?? [];
      
      return downloadsJson
          .map((json) => DownloadInfoModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error getting downloads: $e');
      return [];
    }
  }

  @override
  Future<void> saveDownload(DownloadInfoModel download) async {
    try {
      final downloads = await getAllDownloads();
      final existingIndex = downloads.indexWhere((d) => d.id == download.id);
      
      if (existingIndex != -1) {
        downloads[existingIndex] = download;
      } else {
        downloads.add(download);
      }
      
      await _saveDownloads(downloads);
    } catch (e) {
      print('Error saving download: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateDownload(DownloadInfoModel download) async {
    await saveDownload(download);
  }

  @override
  Future<void> deleteDownload(String downloadId) async {
    try {
      final downloads = await getAllDownloads();
      downloads.removeWhere((d) => d.id == downloadId);
      await _saveDownloads(downloads);
    } catch (e) {
      print('Error deleting download: $e');
      rethrow;
    }
  }

  @override
  Future<DownloadInfoModel?> getDownload(String downloadId) async {
    try {
      final downloads = await getAllDownloads();
      return downloads.where((d) => d.id == downloadId).firstOrNull;
    } catch (e) {
      print('Error getting download: $e');
      return null;
    }
  }

  @override
  Future<void> clearAllDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_downloadsKey);
    } catch (e) {
      print('Error clearing downloads: $e');
      rethrow;
    }
  }

  Future<void> _saveDownloads(List<DownloadInfoModel> downloads) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadsJson = downloads
        .map((download) => jsonEncode(download.toJson()))
        .toList();
    
    await prefs.setStringList(_downloadsKey, downloadsJson);
  }
}