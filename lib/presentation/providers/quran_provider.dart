import 'package:flutter/material.dart';
import '../../data/services/quran_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_preferences_service.dart';
import '../../data/repositories/quran_repository.dart';

/// Provider for accessing Quran functionality throughout the app
class QuranProvider extends ChangeNotifier {
  late final QuranService _quranService;
  late final QuranAudioService _audioService;
  late final QuranPreferencesService _preferencesService;
  late final QuranRepository _repository;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  QuranProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Create services
      _quranService = QuranService();
      _audioService = QuranAudioService();
      _preferencesService = QuranPreferencesService();

      // Create repository with injected services
      _repository = QuranRepository(
        _quranService,
        _audioService,
        _preferencesService,
      );

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing QuranProvider: $e');
      // Still set initialized to true to avoid hanging
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Access to repository
  QuranRepository get repository => _repository;
}
