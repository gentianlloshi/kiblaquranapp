import 'dart:developer' as developer;
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
  bool _isLoading = true;
  String? _errorMessage;
  int _initAttempts = 0;
  static const int _maxInitAttempts = 3;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  QuranProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _initAttempts++;
      notifyListeners();

      // Create services
      developer.log('Initializing Quran services... (attempt $_initAttempts)', name: 'QuranProvider');
      _quranService = QuranService();
      _audioService = QuranAudioService();
      _preferencesService = QuranPreferencesService();

      // Create repository with injected services
      _repository = QuranRepository(
        _quranService,
        _audioService,
        _preferencesService,
      );

      // Force the repository to initialize data
      developer.log('Loading Quran data...', name: 'QuranProvider');
      await _repository.initialize();

      // Verify the data was actually loaded
      final surahs = _repository.getAllSurahs();
      developer.log('Loaded ${surahs.length} surahs', name: 'QuranProvider');

      if (surahs.isEmpty && _initAttempts < _maxInitAttempts) {
        // No surahs loaded, retry initialization
        developer.log('No surahs loaded, retrying initialization', name: 'QuranProvider');
        _isLoading = false;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 500));
        return _initialize();
      }

      _isInitialized = surahs.isNotEmpty;
      developer.log(
        _isInitialized
          ? 'Quran provider initialized successfully with ${surahs.length} surahs'
          : 'Failed to initialize Quran data (empty surahs list)',
        name: 'QuranProvider'
      );
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to initialize Quran data: $e';
      developer.log('Error initializing QuranProvider: $e',
          name: 'QuranProvider', error: e, stackTrace: stackTrace);

      // Retry initialization if we haven't reached max attempts
      if (_initAttempts < _maxInitAttempts) {
        developer.log('Retrying initialization (attempt $_initAttempts of $_maxInitAttempts)', name: 'QuranProvider');
        _isLoading = false;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
        return _initialize();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force reinitialization if needed
  Future<void> reinitialize() async {
    _isInitialized = false;
    _initAttempts = 0;
    await _initialize();
  }

  // Access to repository
  QuranRepository get repository => _repository;
}
