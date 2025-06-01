import '../services/quran_service.dart';
import '../services/quran_audio_service.dart';
import '../services/quran_preferences_service.dart';
import '../models/surah.dart';

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
        // Load Quran data from local JSON files
        await _quranService.loadQuranData();

        // Get saved preferences
        final currentReciter = await _preferencesService.getCurrentReciter();
        _audioService.currentReciter = currentReciter;

        _isDataLoaded = true;
      } catch (e) {
        print('Error initializing QuranRepository: $e');
        throw Exception('Failed to initialize Quran data: $e');
      }
    }
  }

  // Get all surahs
  List<Surah> getAllSurahs() {
    if (!_isDataLoaded) {
      throw Exception('Quran data not loaded. Call initialize() first.');
    }

    final surahs = _quranService.arabicQuran.values.toList();
    surahs.sort((a, b) => a.number.compareTo(b.number));
    return surahs;
  }

  // Get a specific surah with translation
  Future<Map<String, dynamic>> getSurahWithTranslation(int surahNumber) async {
    if (!_isDataLoaded) {
      throw Exception('Quran data not loaded. Call initialize() first.');
    }

    final translatorId = await _preferencesService.getCurrentTranslator();
    return _quranService.getSurahWithTranslation(surahNumber, translatorId);
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
}
