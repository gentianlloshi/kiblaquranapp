import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuranPreferencesService {
  // Singleton pattern
  static final QuranPreferencesService _instance = QuranPreferencesService._internal();
  factory QuranPreferencesService() => _instance;
  QuranPreferencesService._internal();

  // Constants for preference keys
  static const String _kCurrentTranslator = 'currentTranslator';
  static const String _kCurrentReciter = 'audioReciter';
  static const String _kFavorites = 'quran-favorites';
  static const String _kLastRead = 'quran-last-read';
  static const String _kShowArabic = 'showArabic';
  static const String _kShowTransliteration = 'showTransliteration';
  static const String _kShowTranslation = 'showTranslation';
  static const String _kArabicFontFamily = 'arabicFontFamily';
  static const String _kArabicFontSize = 'arabicFontSize';
  static const String _kTranslationFontSize = 'translationFontSize';
  static const String _kTransliterationFontSize = 'transliterationFontSize';

  // Default values
  static const String _defaultTranslator = 'sq.ahmeti';
  static const String _defaultReciter = 'ar.alafasy';
  static const String _defaultArabicFontFamily = 'ScheherazadeNew';
  static const double _defaultArabicFontSize = 2.0;
  static const double _defaultTranslationFontSize = 1.0;
  static const double _defaultTransliterationFontSize = 0.95;

  // Methods to get and set preferences
  Future<String> getCurrentTranslator() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentTranslator) ?? _defaultTranslator;
  }

  Future<void> setCurrentTranslator(String translatorId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentTranslator, translatorId);
  }

  Future<String> getCurrentReciter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentReciter) ?? _defaultReciter;
  }

  Future<void> setCurrentReciter(String reciterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentReciter, reciterId);
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String favoritesJson = prefs.getString(_kFavorites) ?? '[]';
    List<dynamic> favoritesList = jsonDecode(favoritesJson);
    return favoritesList.cast<Map<String, dynamic>>();
  }

  Future<void> toggleFavorite(int surahNumber, int ayahNumber) async {
    final favorites = await getFavorites();
    final index = favorites.indexWhere((f) =>
      f['surah'] == surahNumber && f['ayah'] == ayahNumber
    );

    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.add({
        'surah': surahNumber,
        'ayah': ayahNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFavorites, jsonEncode(favorites));
  }

  Future<bool> isFavorite(int surahNumber, int ayahNumber) async {
    final favorites = await getFavorites();
    return favorites.any((f) =>
      f['surah'] == surahNumber && f['ayah'] == ayahNumber
    );
  }

  Future<Map<String, dynamic>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastReadJson = prefs.getString(_kLastRead);
    if (lastReadJson == null) return null;
    return jsonDecode(lastReadJson);
  }

  Future<void> setLastRead(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRead = {
      'surah': surahNumber,
      'ayah': ayahNumber,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_kLastRead, jsonEncode(lastRead));
  }

  // Display options methods
  Future<bool> getShowArabic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowArabic) ?? true;
  }

  Future<void> setShowArabic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowArabic, value);
  }

  Future<bool> getShowTransliteration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowTransliteration) ?? true;
  }

  Future<void> setShowTransliteration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowTransliteration, value);
  }

  Future<bool> getShowTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowTranslation) ?? true;
  }

  Future<void> setShowTranslation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowTranslation, value);
  }

  // Font style methods
  Future<String> getArabicFontFamily() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kArabicFontFamily) ?? _defaultArabicFontFamily;
  }

  Future<void> setArabicFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kArabicFontFamily, fontFamily);
  }

  Future<double> getArabicFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kArabicFontSize) ?? _defaultArabicFontSize;
  }

  Future<void> setArabicFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kArabicFontSize, size);
  }

  Future<double> getTranslationFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kTranslationFontSize) ?? _defaultTranslationFontSize;
  }

  Future<void> setTranslationFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTranslationFontSize, size);
  }

  Future<double> getTransliterationFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kTransliterationFontSize) ?? _defaultTransliterationFontSize;
  }

  Future<void> setTransliterationFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTransliterationFontSize, size);
  }
}
