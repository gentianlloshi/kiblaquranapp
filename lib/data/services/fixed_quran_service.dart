import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranService {
  // Singleton pattern
  static final QuranService _instance = QuranService._internal();
  factory QuranService() => _instance;
  QuranService._internal();

  // Loaded data
  Map<String, Surah> _arabicQuran = {};
  final Map<String, Map<String, Surah>> _translations = {
    'sq.ahmeti': {},
    'sq.mehdiu': {},  // Add Mehdiu translation
    'sq.nahi': {},    // Add Nahi translation
  };
  final Map<String, Map<String, String>> _transliterations = {};

  // Getters
  Map<String, Surah> get arabicQuran => _arabicQuran;
  Map<String, Map<String, Surah>> get translations => _translations;
  Map<String, Map<String, String>> get transliterations => _transliterations;

  // Loading data
  Future<void> loadQuranData() async {
    try {
      // Check if data is already loaded to avoid re-loading
      if (_arabicQuran.isNotEmpty) {
        print('✅ Quran data already loaded, skipping load');
        return;
      }

      print('📖 Loading Quran data from assets...');

      // Load only available JSON files with error handling
      String arabicData;
      String ahmetiData;
      String mehdiuData;
      String nahiData;

      try {
        // Add timeouts to prevent hanging
        arabicData = await rootBundle.loadString('assets/data/arabic_quran.json')
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('Timeout loading arabic_quran.json');
        });
        print('✅ Arabic Quran loaded successfully');
      } catch (e) {
        print('❌ Error loading Arabic Quran: $e');
        arabicData = '{}';  // Empty placeholder to prevent crashes
      }

      try {
        ahmetiData = await rootBundle.loadString('assets/data/sq_ahmeti.json')
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('Timeout loading sq_ahmeti.json');
        });
        print('✅ Albanian translation loaded successfully');
      } catch (e) {
        print('❌ Error loading Albanian translation: $e');
        ahmetiData = '{}';  // Empty placeholder to prevent crashes
      }

      try {
        mehdiuData = await rootBundle.loadString('assets/data/sq_mehdiu.json')
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('Timeout loading sq_mehdiu.json');
        });
        print('✅ Mehdiu translation loaded successfully');
      } catch (e) {
        print('❌ Error loading Mehdiu translation: $e');
        mehdiuData = '{}';  // Empty placeholder to prevent crashes
      }

      try {
        nahiData = await rootBundle.loadString('assets/data/sq_nahi.json')
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('Timeout loading sq_nahi.json');
        });
        print('✅ Nahi translation loaded successfully');
      } catch (e) {
        print('❌ Error loading Nahi translation: $e');
        nahiData = '{}';  // Empty placeholder to prevent crashes
      }

      // Try to load transliterations if available, but make it optional
      String translitData = '{}';
      try {
        translitData = await rootBundle.loadString('assets/data/transliterations.json')
            .timeout(const Duration(seconds: 5), onTimeout: () {
          throw TimeoutException('Timeout loading transliterations.json');
        });
        print('✅ Transliterations loaded successfully');
      } catch (e) {
        // Create an empty JSON object if file doesn't exist
        print('ℹ️ Transliterations not loaded: $e');
      }

      // Parse JSON with error handling
      try {
        _arabicQuran = _transformQuranData(jsonDecode(arabicData));
        print('✅ Arabic Quran parsed successfully: ${_arabicQuran.length} surahs');
      } catch (e) {
        print('❌ Error parsing Arabic Quran: $e');
        _arabicQuran = {}; // Empty map to prevent crashes
      }

      try {
        _translations['sq.ahmeti'] = _transformQuranData(jsonDecode(ahmetiData));
        print('✅ Albanian translation parsed successfully');
      } catch (e) {
        print('❌ Error parsing Albanian translation: $e');
        _translations['sq.ahmeti'] = {}; // Empty map to prevent crashes
      }

      try {
        _translations['sq.mehdiu'] = _transformQuranData(jsonDecode(mehdiuData));
        print('✅ Mehdiu translation parsed successfully');
      } catch (e) {
        print('❌ Error parsing Mehdiu translation: $e');
        _translations['sq.mehdiu'] = {}; // Empty map to prevent crashes
      }

      try {
        _translations['sq.nahi'] = _transformQuranData(jsonDecode(nahiData));
        print('✅ Nahi translation parsed successfully');
      } catch (e) {
        print('❌ Error parsing Nahi translation: $e');
        _translations['sq.nahi'] = {}; // Empty map to prevent crashes
      }

      try {
        final translitJson = jsonDecode(translitData);
        _processTransliterations(translitJson);
        print('✅ Transliterations processed successfully');
      } catch (e) {
        print('ℹ️ Error processing transliterations: $e');
      }
    } catch (e) {
      print('❌❌ Critical error in loadQuranData: $e');
      // Don't rethrow to prevent app crashes
    }
  }

  void _processTransliterations(Map<String, dynamic> translitJson) {
    translitJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        _transliterations[key] = Map<String, String>.from(value);
      }
    });
  }

  // Helper method to transform raw JSON data into Surah objects
  Map<String, Surah> _transformQuranData(Map<String, dynamic> jsonData) {
    try {
      print('🔍 Starting to transform Quran data');

      if (!jsonData.containsKey('quran')) {
        print('❌ JSON missing "quran" key. Raw JSON keys: ${jsonData.keys.join(', ')}');
        return {};
      }

      // Group verses by chapter
      Map<int, List<Ayah>> chapterVerses = {};
      List<dynamic> verses = jsonData['quran'];

      print('📊 Processing ${verses.length} verses from JSON');

      for (var verse in verses) {
        try {
          int chapter = verse['chapter'];
          int verseNumber = verse['verse'];
          String text = verse['text'];

          if (chapterVerses[chapter] == null) {
            chapterVerses[chapter] = [];
          }

          chapterVerses[chapter]!.add(Ayah(
            numberInSurah: verseNumber,
            text: text,
          ));
        } catch (e) {
          print('⚠️ Error processing verse: $e');
        }
      }

      // Create Surahs from grouped verses
      Map<String, Surah> result = {};

      // Surah names in Arabic and English (basic, can be expanded)
      Map<int, String> surahNames = {
        1: 'Al-Fatihah',
        2: 'Al-Baqarah',
        3: 'Aal-Imran',
        // Add more as needed, or load from a separate file
      };

      chapterVerses.forEach((chapter, ayahs) {
        // Sort ayahs by verse number
        ayahs.sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah));

        result[chapter.toString()] = Surah(
          number: chapter,
          name: surahNames[chapter] ?? 'Surah $chapter',
          englishName: 'Chapter $chapter',
          ayahs: ayahs,
        );
      });

      print('✅ Successfully transformed ${result.length} surahs');
      return result;
    } catch (e) {
      print('❌❌ Critical error in _transformQuranData: $e');
      return {};
    }
  }

  // Complete rewrite with robust error handling to fix the RangeError
  Map<String, dynamic> getSurahWithTranslation(int surahNumber, String translatorId) {
    try {
      final surahKey = surahNumber.toString();

      // Create safe placeholder for errors
      final placeholderSurah = Surah(
        number: surahNumber,
        name: 'Surah $surahNumber',
        englishName: 'Error Loading',
        ayahs: []
      );

      // Load data if not loaded yet
      if (_arabicQuran.isEmpty) {
        print('⚠️ Arabic Quran not loaded, trying to load now');
        loadQuranData();
      }

      // Get the Arabic surah safely
      final arabicSurah = _arabicQuran[surahKey] ?? placeholderSurah;

      // Get the translation safely
      final translationMap = _translations[translatorId] ?? {};
      final translationSurah = translationMap[surahKey] ?? placeholderSurah;

      // Generate transliterations manually for safety
      final transliterations = <String, String>{};
      if (arabicSurah.ayahs.isNotEmpty) {
        for (var ayah in arabicSurah.ayahs) {
          if (ayah.text.isNotEmpty) {
            transliterations[ayah.numberInSurah.toString()] = _generateTransliteration(ayah.text);
          } else {
            transliterations[ayah.numberInSurah.toString()] = '';
          }
        }
      }

      return {
        'arabic': arabicSurah,
        'translation': translationSurah,
        'transliteration': transliterations,
      };
    } catch (e, stackTrace) {
      print('❌ Error in getSurahWithTranslation: $e');
      print('Stack trace: $stackTrace');

      // Return safe default values
      final placeholderSurah = Surah(
        number: surahNumber,
        name: 'Surah $surahNumber',
        englishName: 'Error Loading',
        ayahs: []
      );

      return {
        'arabic': placeholderSurah,
        'translation': placeholderSurah,
        'transliteration': <String, String>{},
      };
    }
  }

  // Create a dedicated method for transliteration with robust error handling
  String _generateTransliteration(String arabicText) {
    try {
      if (arabicText.isEmpty) {
        return '';
      }

      // Map of Arabic characters to their Latin transliteration
      final arabicToLatin = {
        'ا': 'a', 'أ': 'a', 'إ': 'i', 'آ': 'ā',
        'ب': 'b', 'ت': 't', 'ث': 'th',
        'ج': 'j', 'ح': 'ḥ', 'خ': 'kh',
        'د': 'd', 'ذ': 'dh', 'ر': 'r', 'ز': 'z',
        'س': 's', 'ش': 'sh', 'ص': 'ṣ', 'ض': 'ḍ',
        'ط': 'ṭ', 'ظ': 'ẓ', 'ع': 'ʿ', 'غ': 'gh',
        'ف': 'f', 'ق': 'q', 'ك': 'k', 'ل': 'l',
        'م': 'm', 'ن': 'n', 'ه': 'h', 'و': 'w',
        'ي': 'y', 'ى': 'ā', 'ئ': 'ʾ', 'ء': 'ʾ',
        'ؤ': 'ʾ', 'ة': 'h',
        // Vowel marks
        'َ': 'a', 'ِ': 'i', 'ُ': 'u',
        'ً': 'an', 'ٍ': 'in', 'ٌ': 'un',
        'ّ': '', // Shadda - handled specially below
        'ْ': '', // Sukun
        '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
        '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
      };

      // Replace each Arabic character with its Latin equivalent
      String result = '';
      String previousChar = '';
      bool previousCharHasShadda = false;

      for (int i = 0; i < arabicText.length; i++) {
        final char = arabicText[i];

        // Check for shadda (consonant doubling)
        if (char == 'ّ') {
          previousCharHasShadda = true;
          continue;
        }

        // Get transliteration for current character
        String latinChar = arabicToLatin[char] ?? char;

        // Handle shadda (consonant doubling)
        if (previousCharHasShadda && latinChar.isNotEmpty) {
          // Don't double vowels or special characters
          if (!['a', 'i', 'u', 'ā', 'ī', 'ū', ' ', '.', ',', '?', '!', ':', ';', '-'].contains(latinChar)) {
            result += latinChar;
          }
          previousCharHasShadda = false;
        }

        // Add the character to result
        result += latinChar;
        previousChar = char;
      }

      return result;
    } catch (e, stackTrace) {
      print('❌ Error generating transliteration: $e');
      print('Stack trace: $stackTrace');
      return arabicText; // Return original text on error
    }
  }
}
