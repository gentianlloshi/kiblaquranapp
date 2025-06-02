import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/quran_audio_service.dart';

class SurahPlaybackController {
  final int surahNumber;
  final int totalAyahs;
  final Function(int) onAyahChange;
  final QuranAudioService _audioService = QuranAudioService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentAyah = 1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isTransitioning = false;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _processingStateSubscription;
  
  SurahPlaybackController({
    required this.surahNumber,
    required this.totalAyahs,
    required this.onAyahChange,
  }) {
    _initPlayer();
  }

  void _initPlayer() {
    _audioPlayer.setLoopMode(LoopMode.off);
    
    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      debugPrint('Player state changed: ${state.processingState}');
      
      if (state.processingState == ProcessingState.completed && !_isTransitioning) {
        _isTransitioning = true;
        // Add a small delay before playing the next ayah to ensure clean transition
        Future.delayed(const Duration(milliseconds: 500), () {
          _playNextAyah();
        });
      }
    });
    
    // Listen to processing state changes for more detailed control
    _processingStateSubscription = _audioPlayer.processingStateStream.listen((state) {
      debugPrint('Processing state changed: $state');
    });
    
    // Listen to position changes to debug playback
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      // Only log every second to avoid flooding the console
      if (position.inMilliseconds % 1000 < 50) {
        debugPrint('Position: ${position.inSeconds}s / ${_audioPlayer.duration?.inSeconds ?? 0}s');
      }
    });
  }

  Future<void> startPlayback() async {
    if (_isPlaying) return;
    
    _currentAyah = 1;
    await _playCurrentAyah();
  }

  Future<void> pausePlayback() async {
    if (!_isPlaying) return;
    
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  Future<void> resumePlayback() async {
    if (_isPlaying) return;
    
    await _audioPlayer.play();
    _isPlaying = true;
  }

  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _isTransitioning = false;
    _currentAyah = 1;
  }

  Future<void> _playCurrentAyah() async {
    if (_currentAyah > totalAyahs) {
      _isPlaying = false;
      _isTransitioning = false;
      return;
    }

    _isLoading = true;
    
    try {
      // Notify listeners that we're changing ayah
      onAyahChange(_currentAyah);
      
      debugPrint('Loading ayah $surahNumber:$_currentAyah');
      
      // Get audio URL for current ayah
      final audioUrl = await _audioService.getVerseAudioUrl(
        surahNumber, 
        _currentAyah
      );
      
      debugPrint('Got audio URL: $audioUrl');
      
      // Stop any current playback
      await _audioPlayer.stop();
      
      // Set the audio source and play
      await _audioPlayer.setUrl(audioUrl);
      final duration = await _audioPlayer.duration;
      debugPrint('Audio duration: ${duration?.inSeconds ?? 0} seconds');
      
      await _audioPlayer.play();
      
      _isPlaying = true;
      _isLoading = false;
      _isTransitioning = false;
    } catch (e) {
      debugPrint('Error playing ayah $surahNumber:$_currentAyah - $e');
      _isLoading = false;
      _isTransitioning = false;
      
      // Add a delay before trying the next ayah
      await Future.delayed(const Duration(seconds: 1));
      
      // Skip to next ayah if this one fails
      _playNextAyah();
    }
  }

  Future<void> _playNextAyah() async {
    debugPrint('Moving to next ayah: ${_currentAyah + 1}');
    _currentAyah++;
    if (_currentAyah <= totalAyahs) {
      await _playCurrentAyah();
    } else {
      // We've reached the end of the surah
      debugPrint('Reached end of surah');
      _isPlaying = false;
      _isTransitioning = false;
      _currentAyah = 1;
    }
  }

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  int get currentAyah => _currentAyah;

  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _audioPlayer.dispose();
  }
}
