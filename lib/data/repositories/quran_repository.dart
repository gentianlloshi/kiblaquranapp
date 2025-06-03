import 'dart:developer' as developer;
import '../services/quran_service.dart';
import '../services/quran_audio_service.dart';
import '../services/quran_preferences_service.dart';
import '../models/surah.dart';
import '../../utils/asset_debugger.dart';

class QuranRepository {
  final QuranService _quranService;
  final QuranAudioService _audioService;
  final QuranPreferencesService _preferencesService;

  bool _isDataLoaded = false;

  QuranRepository(
    this._quranService,
    this._audioService,
    this._preferencesService,
  );

  // Getter to check if data is loaded
  bool get isDataLoaded => _isDataLoaded;

  // Initialize all data
  Future<void> initialize() async {
    if (!_isDataLoaded) {
      try {
        developer.log('Initializing QuranRepository...', name: 'QuranRepository');

        // Load Quran data from local JSON files
        await _quranService.loadQuranData();

        // Get saved preferences
        final currentReciter = await _preferencesService.getCurrentReciter();
        _audioService.currentReciter = currentReciter;

        _isDataLoaded = true;
        developer.log('QuranRepository initialized successfully', name: 'QuranRepository');
      } catch (e, stack) {
        developer.log('Error initializing QuranRepository: $e',
            name: 'QuranRepository', error: e, stackTrace: stack);
        // Don't throw, just log the error
        _isDataLoaded = false;
      }
    }
  }

  // Get all surahs
  List<Surah> getAllSurahs() {
    try {
      // Always try to load data, even if not initialized
      final surahs = _quranService.arabicQuran.values.toList();
      developer.log('Returning ${surahs.length} surahs', name: 'QuranRepository');

      // If we have surahs, consider the repository loaded
      if (surahs.isNotEmpty && !_isDataLoaded) {
        _isDataLoaded = true;
      }

      // Sort by surah number
      surahs.sort((a, b) => a.number.compareTo(b.number));
      return surahs;
    } catch (e, stack) {
      developer.log('Error getting all surahs: $e',
          name: 'QuranRepository', error: e, stackTrace: stack);
      return []; // Return empty list instead of throwing exception
    }
  }

  // Get a specific surah with translation
  Future<Map<String, dynamic>> getSurahWithTranslation(int surahNumber) async {
    try {
      // Always try to initialize if not already initialized
      if (!_isDataLoaded) {
        developer.log('Data not loaded, initializing first...', name: 'QuranRepository');
        await initialize();
      }

      // Get translator ID and fix format if needed
      String translatorId = await _preferencesService.getCurrentTranslator();

      // Ensure consistent format (convert dots to underscores)
      translatorId = translatorId.replaceAll('.', '_');
      developer.log('Getting surah $surahNumber with translator: $translatorId', name: 'QuranRepository');

      // Get the surah with translation
      final result = await _quranService.getSurahWithTranslation(surahNumber, translatorId);

      // Check if we got valid results
      if (result['arabic'] == null) {
        developer.log('Failed to get Arabic text for surah $surahNumber', name: 'QuranRepository');
      } else {
        developer.log('Successfully loaded surah $surahNumber with ${(result['arabic'] as Surah).ayahs.length} ayahs',
            name: 'QuranRepository');
      }

      return result;
    } catch (e, stack) {
      developer.log('Error in getSurahWithTranslation: $e',
          name: 'QuranRepository', error: e, stackTrace: stack);

      // Return a fallback result with error information
      return {
        'arabic': null,
        'translation': null,
        'transliteration': <String, String>{},
        'error': 'Failed to load surah: $e'
      };
    }
  }

  // Get audio URL for a verse
  Future<String> getVerseAudioUrl(int surahNumber, int ayahNumber) async {
    return await _audioService.getVerseAudioUrl(surahNumber, ayahNumber);
  }

  // Get available reciters
  List<Map<String, String>> getAvailableReciters() {
    return _audioService.getAvailableReciters();
  }

  // Change the current reciter
  Future<void> setCurrentReciter(String reciterId) async {
    await _preferencesService.setCurrentReciter(reciterId);
    _audioService.currentReciter = reciterId;
  }

  // Change the current translator
  Future<void> setCurrentTranslator(String translatorId) async {
    await _preferencesService.setCurrentTranslator(translatorId);
  }

  // Get the last read position
  Future<Map<String, dynamic>?> getLastReadPosition() async {
    return await _preferencesService.getLastRead();
  }

  // Save the last read position
  Future<void> saveLastReadPosition(int surahNumber, int ayahNumber) async {
    await _preferencesService.setLastRead(surahNumber, ayahNumber);
  }

  // Toggle a verse as favorite
  Future<void> toggleFavoriteVerse(int surahNumber, int ayahNumber) async {
    await _preferencesService.toggleFavorite(surahNumber, ayahNumber);
  }

  // Check if a verse is a favorite
  Future<bool> isVerseFavorite(int surahNumber, int ayahNumber) async {
    return await _preferencesService.isFavorite(surahNumber, ayahNumber);
  }

  // Get all favorite verses
  Future<List<Map<String, dynamic>>> getFavoriteVerses() async {
    return await _preferencesService.getFavorites();
  }

  // Get display preferences
  Future<Map<String, dynamic>> getDisplayPreferences() async {
    return {
      'showArabic': await _preferencesService.getShowArabic(),
      'showTransliteration': await _preferencesService.getShowTransliteration(),
      'showTranslation': await _preferencesService.getShowTranslation(),
      'arabicFontFamily': await _preferencesService.getArabicFontFamily(),
      'arabicFontSize': await _preferencesService.getArabicFontSize(),
      'translationFontSize': await _preferencesService.getTranslationFontSize(),
      'transliterationFontSize': await _preferencesService.getTransliterationFontSize(),
    };
  }

  // Save display preferences
  Future<void> updateDisplayPreferences({
    bool? showArabic,
    bool? showTransliteration,
    bool? showTranslation,
    String? arabicFontFamily,
    double? arabicFontSize,
    double? translationFontSize,
    double? transliterationFontSize,
  }) async {
    if (showArabic != null) {
      await _preferencesService.setShowArabic(showArabic);
    }
    if (showTransliteration != null) {
      await _preferencesService.setShowTransliteration(showTransliteration);
    }
    if (showTranslation != null) {
      await _preferencesService.setShowTranslation(showTranslation);
    }
    if (arabicFontFamily != null) {
      await _preferencesService.setArabicFontFamily(arabicFontFamily);
    }
    if (arabicFontSize != null) {
      await _preferencesService.setArabicFontSize(arabicFontSize);
    }
    if (translationFontSize != null) {
      await _preferencesService.setTranslationFontSize(translationFontSize);
    }
    if (transliterationFontSize != null) {
      await _preferencesService.setTransliterationFontSize(transliterationFontSize);
    }
  }

  // Run diagnostic checks to help troubleshoot loading issues
  Future<void> runDiagnostics() async {
    print('🔬 QuranRepository: Starting diagnostics');
    print('🔬 QuranRepository: Data loaded flag: $_isDataLoaded');

    // Check if Quran data is loaded
    if (_quranService.arabicQuran.isEmpty) {
      print('🔬 QuranRepository: Arabic Quran not loaded');
    } else {
      print('🔬 QuranRepository: Arabic Quran loaded with ${_quranService.arabicQuran.length} surahs');
    }

    // Check translation status
    print('🔬 QuranRepository: Translation status:');
    _quranService.translations.forEach((key, value) {
      print('🔬 QuranRepository: - $key: ${value.length} surahs');
    });

    print('🔬 QuranRepository: Diagnostics complete');
  }

  // Run comprehensive diagnostic checks and attempt to fix asset issues
  Future<Map<String, dynamic>> runComprehensiveDiagnostics() async {
    developer.log('Starting comprehensive diagnostics', name: 'QuranRepository');

    Map<String, dynamic> report = {};

    // Step 1: Check asset files
    report['assets'] = await AssetDebugger.checkQuranAssets();

    // Step 2: Check Quran service data status
    report['service_status'] = {
      'arabic_quran_loaded': _quranService.arabicQuran.isNotEmpty,
      'arabic_surah_count': _quranService.arabicQuran.length,
      'has_error': _quranService.hasError,
      'error_message': _quranService.errorMessage,
      'translations': {},
    };

    // Check translations
    _quranService.translations.forEach((key, value) {
      report['service_status']['translations'][key] = value.length;
    });

    // Step 3: Try to reload quran data if needed
    if (_quranService.arabicQuran.length <= 1) {
      developer.log('Only fallback surah found. Attempting to reload data...', name: 'QuranRepository');
      try {
        await _quranService.loadQuranData();
        report['reload_attempt'] = 'Executed';
        report['after_reload'] = {
          'arabic_quran_loaded': _quranService.arabicQuran.isNotEmpty,
          'arabic_surah_count': _quranService.arabicQuran.length,
        };
      } catch (e) {
        report['reload_attempt'] = 'Failed: $e';
      }
    } else {
      report['reload_attempt'] = 'Not needed';
    }

    // Step 4: Determine the root cause and propose solutions
    if (report['assets']['all_assets_exist'] == false) {
      report['diagnosis'] = 'MISSING_ASSET_FILES';
      report['solution'] = 'Make sure all required JSON files are in assets/data/ and properly declared in pubspec.yaml';
    } else if (_quranService.arabicQuran.length <= 1) {
      report['diagnosis'] = 'JSON_FORMAT_ERROR';
      report['solution'] = 'Quran JSON files exist but could not be parsed. Check the format of your JSON files. They should contain a "quran" key with an array of surah objects.';
    } else {
      report['diagnosis'] = 'DATA_LOADED';
      report['solution'] = 'Data appears to be loaded correctly. If issues persist, check specific surah access logic.';
    }

    _isDataLoaded = _quranService.arabicQuran.length > 1;

    developer.log('Comprehensive diagnostics completed: ${report['diagnosis']}', name: 'QuranRepository');
    return report;
  }
}
