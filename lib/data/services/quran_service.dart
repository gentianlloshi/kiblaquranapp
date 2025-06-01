import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/translation.dart';

class QuranService {
  // Singleton pattern
  static final QuranService _instance = QuranService._internal();
  factory QuranService() => _instance;
  QuranService._internal();

  // Loaded data
  Map<String, Surah> _arabicQuran = {};
  final Map<String, Map<String, Surah>> _translations = {
    'sq.ahmeti': {},
    // Removing the other translations since we only have sq_ahmeti.json
  };
  final Map<String, Map<String, String>> _transliterations = {};

  // Getters
  Map<String, Surah> get arabicQuran => _arabicQuran;
  Map<String, Map<String, Surah>> get translations => _translations;
  Map<String, Map<String, String>> get transliterations => _transliterations;

  // Loading data
  Future<void> loadQuranData() async {
    try {
      // Load only available JSON files
      final arabicFuture = rootBundle.loadString('assets/data/arabic_quran.json');
      final ahmetiFuture = rootBundle.loadString('assets/data/sq_ahmeti.json');

      // Try to load transliterations if available, but make it optional
      Future<String> translitFuture;
      try {
        translitFuture = rootBundle.loadString('assets/data/transliterations.json');
        print('✅ Transliterations file found, loading...');
      } catch (e) {
        // Create an empty JSON object if file doesn't exist
        translitFuture = Future.value('{}');
        print('❌ Transliterations file not found: $e');
      }

      // Wait for available files to complete
      final results = await Future.wait([
        arabicFuture, ahmetiFuture, translitFuture
      ]);

      // Transform the data
      _arabicQuran = _transformQuranData(jsonDecode(results[0]), true);
      _translations['sq.ahmeti'] = _transformQuranData(jsonDecode(results[1]));

      // Handle transliterations if available
      try {
        Map<String, dynamic> rawTransliterationData = jsonDecode(results[2]);
        print('🔍 Raw transliteration data keys: ${rawTransliterationData.keys.toList()}');

        // Process transliteration data if not empty
        if (rawTransliterationData.isNotEmpty) {
          rawTransliterationData.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              _transliterations[key] = Map<String, String>.from(value);
            }
          });
        }
      } catch (e) {
        print('⚠️ Error loading transliterations: $e');
      }

      print('📚 Quran data loaded successfully');
    } catch (e) {
      print('❌ Error loading Quran data: $e');
      throw Exception('Failed to load Quran data: $e');
    }
  }

  // Helper method to transform raw JSON data into Surah objects
  Map<String, Surah> _transformQuranData(Map<String, dynamic> rawData, [bool isArabic = false]) {
    Map<String, Surah> result = {};

    rawData.forEach((surahKey, surahData) {
      if (surahData is Map<String, dynamic>) {
        final int surahNumber = int.tryParse(surahKey.replaceAll('surah_', '')) ?? 0;
        if (surahNumber > 0) {
          List<Ayah> ayahs = [];

          // Extract ayah data
          if (surahData.containsKey('ayahs') && surahData['ayahs'] is Map<String, dynamic>) {
            surahData['ayahs'].forEach((ayahKey, ayahData) {
              if (ayahData is Map<String, dynamic> && ayahData.containsKey('text')) {
                final int ayahNumber = int.tryParse(ayahKey.replaceAll('ayah_', '')) ?? 0;
                if (ayahNumber > 0) {
                  ayahs.add(Ayah(
                    numberInSurah: ayahNumber,
                    text: ayahData['text'].toString(),
                  ));
                }
              }
            });
          }

          // Create Surah object
          result[surahKey] = Surah(
            number: surahNumber,
            name: surahData['name']?.toString() ?? 'Surah $surahNumber',
            englishName: surahData['arabic_name']?.toString() ?? '',
            ayahs: ayahs,
          );
        }
      }
    });

    return result;
  }

  // Method to get Surah with translation
  Future<Map<String, dynamic>> getSurahWithTranslation(int surahNumber, String translatorId) async {
    final surahKey = 'surah_$surahNumber';

    // Ensure data is loaded
    if (_arabicQuran.isEmpty) {
      await loadQuranData();
    }

    // Get Arabic surah
    final arabicSurah = _arabicQuran[surahKey];
    if (arabicSurah == null) {
      throw Exception('Surah $surahNumber not found in Arabic Quran');
    }

    // Get translation
    final translationMap = _translations[translatorId];
    if (translationMap == null) {
      throw Exception('Translation $translatorId not found');
    }

    final translatedSurah = translationMap[surahKey];
    if (translatedSurah == null) {
      throw Exception('Surah $surahNumber not found in $translatorId translation');
    }

    // Get transliteration if available
    Map<String, String>? translit = {};
    if (_transliterations.containsKey('en') && _transliterations['en']!.containsKey(surahKey)) {
      translit = {'en': _transliterations['en']![surahKey]!};
    }

    // Return as a map with the required components
    return {
      'arabic': arabicSurah,
      'translation': translatedSurah,
      'transliteration': translit,
    };
  }
}
