import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

/// Professional audio service for managing ringtone playback using just_audio
/// Follows singleton pattern for app-wide audio management
class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static AudioService get instance => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
  bool _isLoading = false;
  String? _errorMessage;
  Duration? _duration;
  Duration _position = Duration.zero;

  // Getters
  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  Duration? get duration => _duration;
  Duration get position => _position;
  bool get isPlaying => _audioPlayer.playing;

  /// Check if a specific tone is currently playing
  bool isTonePlaying(String toneId) {
    return _currentlyPlayingId == toneId && _audioPlayer.playing;
  }

  /// Initialize the audio service with proper stream subscriptions
  Future<void> initialize() async {
    try {
      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((playerState) {
        _handlePlayerStateChanged(playerState);
      });

      // Listen to duration changes
      _audioPlayer.durationStream.listen((duration) {
        _duration = duration;
        notifyListeners();
      });

      // Listen to position changes
      _audioPlayer.positionStream.listen((position) {
        _position = position;
        notifyListeners();
      });

      // Listen to playback completion
      _audioPlayer.playerStateStream
          .where((state) => state.processingState == ProcessingState.completed)
          .listen((_) {
        _handlePlaybackComplete();
      });

      debugPrint('AudioService: Initialized successfully');
    } catch (e) {
      _setError('Failed to initialize audio service: $e');
      debugPrint('AudioService initialization error: $e');
    }
  }

  /// Play a ringtone from URL
  Future<void> playTone(String toneId, String url) async {
    try {
      _clearError();
      _setLoading(true);

      // Stop current playback if any
      if (_currentlyPlayingId != null && _currentlyPlayingId != toneId) {
        await _audioPlayer.stop();
        _currentlyPlayingId = null;
      }

      // Set the audio source and play
      await _audioPlayer.setUrl(url);
      _currentlyPlayingId = toneId;
      await _audioPlayer.play();
      
      _setLoading(false);
      debugPrint('AudioService: Playing tone $toneId from $url');
      
    } catch (e) {
      _currentlyPlayingId = null;
      _setError('Failed to play audio: $e');
      debugPrint('AudioService play error: $e');
    }
  }

  /// Stop the currently playing tone
  Future<void> stopCurrentTone() async {
    try {
      await _audioPlayer.stop();
      _currentlyPlayingId = null;
      _clearError();
      debugPrint('AudioService: Stopped current tone');
      notifyListeners();
      
    } catch (e) {
      _setError('Failed to stop audio: $e');
      debugPrint('AudioService stop error: $e');
    }
  }

  /// Pause the currently playing tone
  Future<void> pauseCurrentTone() async {
    try {
      await _audioPlayer.pause();
      debugPrint('AudioService: Paused current tone');
    } catch (e) {
      _setError('Failed to pause audio: $e');
      debugPrint('AudioService pause error: $e');
    }
  }

  /// Resume the currently paused tone
  Future<void> resumeCurrentTone() async {
    try {
      await _audioPlayer.play();
      debugPrint('AudioService: Resumed current tone');
    } catch (e) {
      _setError('Failed to resume audio: $e');
      debugPrint('AudioService resume error: $e');
    }
  }

  /// Toggle play/stop for a specific tone
  Future<void> toggleTone(String toneId, String url) async {
    if (isTonePlaying(toneId)) {
      await stopCurrentTone();
    } else {
      await playTone(toneId, url);
    }
  }

  /// Seek to a specific position in the current track
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _setError('Failed to seek: $e');
      debugPrint('AudioService seek error: $e');
    }
  }

  /// Set playback speed (0.5 to 2.0)
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed.clamp(0.5, 2.0));
    } catch (e) {
      _setError('Failed to set speed: $e');
      debugPrint('AudioService speed error: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      _setError('Failed to set volume: $e');
      debugPrint('AudioService volume error: $e');
    }
  }

  /// Handle playback completion
  void _handlePlaybackComplete() {
    _currentlyPlayingId = null;
    _position = Duration.zero;
    _duration = null;
    _clearError();
    _setLoading(false);
    debugPrint('AudioService: Playback completed');
    notifyListeners();
  }

  /// Handle player state changes
  void _handlePlayerStateChanged(PlayerState state) {
    switch (state.processingState) {
      case ProcessingState.idle:
        _setLoading(false);
        break;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        _setLoading(true);
        break;
      case ProcessingState.ready:
        _setLoading(false);
        break;
      case ProcessingState.completed:
        _handlePlaybackComplete();
        break;
    }
    
    // Notify listeners of any state changes
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Stop all playback (useful for app lifecycle management)
  Future<void> stopAll() async {
    await stopCurrentTone();
  }

  /// Get current playback progress (0.0 to 1.0)
  double get progress {
    if (_duration == null || _duration!.inMilliseconds <= 0) {
      return 0.0;
    }
    return (_position.inMilliseconds / _duration!.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Format duration to MM:SS format
  String formatDuration(Duration duration) {
    // Ensure minimum duration of 1 second to avoid showing 00:00
    final adjustedDuration = duration.inSeconds < 1 ? const Duration(seconds: 1) : duration;
    final minutes = adjustedDuration.inMinutes;
    final seconds = adjustedDuration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}