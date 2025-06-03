import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/quran_audio_service.dart';

class SurahPlaybackController {
  final int surahNumber;
  final int totalAyahs;
  final Function(int) onAyahChange;
  final QuranAudioService _audioService = QuranAudioService();

  // Use a single audio player instance for the entire controller lifecycle
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Playlist that will hold all ayahs for the surah
  ConcatenatingAudioSource? _playlist;

  // Track the current ayah being played
  int _currentAyah = 1;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isPaused = false;
  bool _userInitiatedStop = false;
  bool _isInitialized = false;

  // Stream subscriptions
  StreamSubscription? _playerIndexSubscription;
  StreamSubscription? _playerStateSubscription;

  SurahPlaybackController({
    required this.surahNumber,
    required this.totalAyahs,
    required this.onAyahChange,
  }) {
    _initPlayer();
  }

  void _initPlayer() {
    debugPrint('Initializing SurahPlaybackController for Surah $surahNumber with $totalAyahs ayahs');

    // Configure the player
    _audioPlayer.setLoopMode(LoopMode.off);

    // Listen to current playback index changes
    _playerIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _isPlaying && !_userInitiatedStop) {
        // Index is 0-based, but ayah numbers are 1-based
        final ayahNumber = index + 1;

        debugPrint('Audio index changed to $index, corresponding to ayah $ayahNumber');

        if (ayahNumber != _currentAyah) {
          _currentAyah = ayahNumber;
          onAyahChange(_currentAyah);
        }
      }
    });

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      debugPrint('Player state changed: ${state.processingState} - Playing: ${state.playing}');
      
      // Handle completion of the entire playlist
      if (state.processingState == ProcessingState.completed) {
        debugPrint('Playlist completed');
        _isPlaying = false;
        _currentAyah = 1;
      }

      // Update loading state based on processing state
      _isLoading = state.processingState == ProcessingState.loading ||
                   state.processingState == ProcessingState.buffering;
    });
  }

  // Initialize the playlist with all audio URLs for the surah
  Future<void> _initPlaylist() async {
    debugPrint('Initializing playlist for Surah $surahNumber');
    _isLoading = true;

    try {
      // Clear existing playlist
      if (_playlist != null) {
        await _audioPlayer.stop();
        _playlist = null;
      }

      final audioSources = <AudioSource>[];

      // Load audio for each ayah - no skipping any ayahs
      for (int ayah = 1; ayah <= totalAyahs; ayah++) {
        try {
          final url = await _audioService.getVerseAudioUrl(surahNumber, ayah);
          debugPrint('Adding ayah $ayah to playlist: $url');

          audioSources.add(AudioSource.uri(Uri.parse(url)));
        } catch (e) {
          debugPrint('Error loading audio for ayah $ayah: $e');
          // Try fallback if available, or continue with next ayah
        }
      }

      if (audioSources.isEmpty) {
        throw Exception('Could not load any audio sources');
      }

      // Create and set the playlist
      _playlist = ConcatenatingAudioSource(children: audioSources);
      await _audioPlayer.setAudioSource(_playlist!);
      _isInitialized = true;
      _isLoading = false;

    } catch (e) {
      debugPrint('Error initializing playlist: $e');
      _isLoading = false;
      _isInitialized = false;
      rethrow;
    }
  }

  // Start playback of the entire surah
  Future<void> startPlayback() async {
    if (_isPlaying && !_isPaused) return;
    
    debugPrint('Starting playback of Surah $surahNumber');
    _userInitiatedStop = false;
    _isPaused = false;

    // Initialize the playlist if needed
    if (!_isInitialized || _playlist == null) {
      await _initPlaylist();
    }

    if (_isPaused) {
      // Resume playback
      await _audioPlayer.play();
    } else {
      // Start from the beginning
      _currentAyah = 1;
      await _audioPlayer.seek(Duration.zero, index: 0);
      await _audioPlayer.play();
    }
    
    _isPlaying = true;
    onAyahChange(_currentAyah);
  }

  // Pause the current playback
  Future<void> pausePlayback() async {
    if (!_isPlaying) return;
    
    debugPrint('Pausing playback at ayah $_currentAyah');
    await _audioPlayer.pause();
    _isPaused = true;
  }

  // Resume playback from where it was paused
  Future<void> resumePlayback() async {
    if (!_isPaused) return;
    
    debugPrint('Resuming playback from ayah $_currentAyah');
    _isPaused = false;
    await _audioPlayer.play();
  }

  // Skip to a specific ayah
  Future<void> skipToAyah(int ayahNumber) async {
    if (!_isInitialized || _playlist == null) {
      debugPrint('Player not initialized yet, initializing first');
      await _initPlaylist();
    }

    if (ayahNumber < 1 || ayahNumber > totalAyahs) {
      debugPrint('Invalid ayah number: $ayahNumber');
      return;
    }

    // Calculate the playlist index (0-based) from the ayah number (1-based)
    final playlistIndex = ayahNumber - 1;
    debugPrint('Skipping to ayah $ayahNumber (playlist index: $playlistIndex)');

    // Seek to the beginning of the specified ayah
    await _audioPlayer.seek(Duration.zero, index: playlistIndex);
    _currentAyah = ayahNumber;

    // If not already playing, start playback
    if (!_isPlaying) {
      _isPlaying = true;
      _isPaused = false;
      await _audioPlayer.play();
    }

    onAyahChange(_currentAyah);
  }

  // Stop playback completely
  Future<void> stopPlayback() async {
    debugPrint('Stopping playback');
    _userInitiatedStop = true;
    await _audioPlayer.stop();
    _isPlaying = false;
    _isPaused = false;
    _currentAyah = 1;
  }

  // Public getters
  bool get isPlaying => _isPlaying && !_isPaused;
  bool get isLoading => _isLoading;
  bool get isPaused => _isPaused;
  int get currentAyah => _currentAyah;

  // Clean up resources
  void dispose() {
    debugPrint('Disposing SurahPlaybackController');
    _playerIndexSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
  }
}
