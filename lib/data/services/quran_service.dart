import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranService {
  // Singleton implementation
  static final QuranService _instance = QuranService._internal();
  factory QuranService() => _instance;
  QuranService._internal();

  // Loaded data
  Map<String, Surah> _arabicQuran = {};
  final Map<String, Map<String, Surah>> _translations = {
    'sq_ahmeti': {},
    'sq_mehdiu': {},
    'sq_nahi': {},
  };

  // Transliterations map
  final Map<String, Map<String, String>> _transliterations = {};

  // State tracking
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = "";

  // Getters
  Map<String, Surah> get arabicQuran => _arabicQuran;
  Map<String, Map<String, Surah>> get translations => _translations;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  // Helper method for logging that works in both debug and release
  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'QuranService', error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      print(message);
      if (error != null) print('Error: $error');
    }
  }

  // Helper method to check if an asset exists
  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      _log('Asset does not exist: $path', error: e);
      return false;
    }
  }

  // Method to log asset info for debugging
  Future<Map<String, bool>> debugAssetInfo() async {
    _log('Checking assets availability...');

    // Check key files
    bool arabicExists = await _assetExists('assets/data/arabic_quran.json');
    bool ahmetiExists = await _assetExists('assets/data/sq_ahmeti.json');
    bool mehdiuExists = await _assetExists('assets/data/sq_mehdiu.json');
    bool nahiExists = await _assetExists('assets/data/sq_nahi.json');
    bool transliterationsExists = await _assetExists('assets/data/transliterations.json');

    _log('Asset check results:');
    _log('- arabic_quran.json: ${arabicExists ? 'EXISTS' : 'MISSING'}');
    _log('- sq_ahmeti.json: ${ahmetiExists ? 'EXISTS' : 'MISSING'}');
    _log('- sq_mehdiu.json: ${mehdiuExists ? 'EXISTS' : 'MISSING'}');
    _log('- sq_nahi.json: ${nahiExists ? 'EXISTS' : 'MISSING'}');
    _log('- transliterations.json: ${transliterationsExists ? 'EXISTS' : 'MISSING'}');

    if (!arabicExists) {
      _errorMessage = "Missing required asset: assets/data/arabic_quran.json";
      _hasError = true;
    }

    return {
      'arabic_quran.json': arabicExists,
      'sq_ahmeti.json': ahmetiExists,
      'sq_mehdiu.json': mehdiuExists,
      'sq_nahi.json': nahiExists,
      'transliterations.json': transliterationsExists,
    };
  }

  // Loading data
  Future<void> loadQuranData() async {
    // Don't attempt to load if already loading or already loaded successfully
    if (_isLoading) {
      _log('Already loading Quran data, skipping duplicate load request');
      return;
    }

    if (_arabicQuran.isNotEmpty) {
      _log('Quran data already loaded, skipping load');
      return;
    }

    _isLoading = true;
    _hasError = false;
    _errorMessage = "";

    try {
      _log('Starting to load Quran data from assets...');

      // First, check if assets exist
      Map<String, bool> assetCheck = await debugAssetInfo();
      if (!assetCheck['arabic_quran.json']!) {
        throw Exception('Required Arabic Quran file not found. Please verify your assets.');
      }

      // STEP 1: LOAD ARABIC QURAN (MOST IMPORTANT)
      _log('Loading Arabic Quran...');
      try {
        String arabicData = await rootBundle.loadString('assets/data/arabic_quran.json');
        _log('Arabic data loaded, length: ${arabicData.length}');

        if (arabicData.isEmpty) {
          throw Exception('Arabic Quran file is empty');
        }

        Map<String, dynamic> arabicMap;
        try {
          arabicMap = jsonDecode(arabicData);
          _log('Arabic JSON parsed successfully');
        } catch (parseError) {
          _log('JSON parse error: $parseError');
          // Try to show the first part of the file to diagnose JSON issues
          _log('First 100 chars of file: ${arabicData.substring(0, arabicData.length > 100 ? 100 : arabicData.length)}');
          throw Exception('Invalid JSON format in Arabic Quran file: $parseError');
        }

        if (!arabicMap.containsKey('quran')) {
          _log('Missing "quran" key in Arabic Quran JSON');
          _log('Available keys: ${arabicMap.keys.toList()}');
          throw Exception('Invalid JSON format for Arabic Quran - missing "quran" key');
        }

        _arabicQuran = _transformQuranData(arabicMap);
        _log('Arabic Quran transformed, surahs: ${_arabicQuran.length}');

        // Verify we actually got some data
        if (_arabicQuran.isEmpty) {
          throw Exception('No surahs found in Arabic Quran data');
        }

        // Verify we have the expected number of surahs (114)
        if (_arabicQuran.length < 114) {
          _log('Warning: Incomplete Arabic Quran data. Expected 114 surahs, got ${_arabicQuran.length}');
        }

      } catch (e) {
        _log('Error loading Arabic Quran: $e');
        // Create fallback data for at least Surah Al-Fatiha
        _log('Creating fallback data for Al-Fatiha');
        _arabicQuran = {
          "1": Surah(
            number: 1,
            name: "Al-Fatiha",
            englishName: "The Opening",
            ayahs: [
              Ayah(numberInSurah: 1, text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"),
              Ayah(numberInSurah: 2, text: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ"),
              Ayah(numberInSurah: 3, text: "الرَّحْمَٰنِ الرَّحِيمِ"),
              Ayah(numberInSurah: 4, text: "مَالِكِ يَوْمِ الدِّينِ"),
              Ayah(numberInSurah: 5, text: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ"),
              Ayah(numberInSurah: 6, text: "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ"),
              Ayah(numberInSurah: 7, text: "صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ"),
            ]
          )
        };
        _hasError = true;
        _errorMessage = "Failed to load complete Arabic Quran: $e. Using fallback data for Al-Fatiha.";
      }

      // STEP 2: LOAD TRANSLATIONS
      if (!_hasError) {
        _log('Loading translations...');

        // Load Ahmeti translation
        try {
          String ahmetiData = await rootBundle.loadString('assets/data/sq_ahmeti.json');
          Map<String, dynamic> ahmetiMap = jsonDecode(ahmetiData);
          if (ahmetiMap.containsKey('quran')) {
            _translations['sq_ahmeti'] = _transformQuranData(ahmetiMap);
            _log('Ahmeti translation loaded');
          }
        } catch (e) {
          _log('Error loading Ahmeti translation: $e');
        }

        // Load Mehdiu translation
        try {
          String mehdiuData = await rootBundle.loadString('assets/data/sq_mehdiu.json');
          Map<String, dynamic> mehdiuMap = jsonDecode(mehdiuData);
          if (mehdiuMap.containsKey('quran')) {
            _translations['sq_mehdiu'] = _transformQuranData(mehdiuMap);
            _log('Mehdiu translation loaded');
          }
        } catch (e) {
          _log('Error loading Mehdiu translation: $e');
        }

        // Load Nahi translation
        try {
          String nahiData = await rootBundle.loadString('assets/data/sq_nahi.json');
          Map<String, dynamic> nahiMap = jsonDecode(nahiData);
          if (nahiMap.containsKey('quran')) {
            _translations['sq_nahi'] = _transformQuranData(nahiMap);
            _log('Nahi translation loaded');
          }
        } catch (e) {
          _log('Error loading Nahi translation: $e');
        }
      }

      // STEP 3: LOAD TRANSLITERATIONS
      _log('Loading transliterations...');
      try {
        String translitData = await rootBundle.loadString('assets/data/transliterations.json');
        Map<String, dynamic> translitMap = jsonDecode(translitData);

        // Process transliterations - extract surah by surah
        translitMap.forEach((surahKey, surahData) {
          int surahNum = int.tryParse(surahKey) ?? 0;
          if (surahNum > 0) {
            Map<String, String> ayahTransliterations = {};

            // Extract ayah by ayah
            (surahData as Map<String, dynamic>).forEach((ayahKey, ayahTranslit) {
              ayahTransliterations[ayahKey] = ayahTranslit.toString();
            });

            _transliterations[surahKey] = ayahTransliterations;
          }
        });
        _log('Transliterations loaded, surahs: ${_transliterations.length}');
      } catch (e) {
        _log('Error loading transliterations: $e');
      }

      // Complete loading
      _log('Quran data loading complete!');
    } catch (e) {
      _hasError = true;
      _errorMessage = "Error loading Quran data: $e";
      _log('Overall error loading Quran data: $e');
    } finally {
      _isLoading = false;
    }
  }

  // Transform flat Quran JSON into a map of Surah objects, each containing its ayahs
  Map<String, Surah> _transformQuranData(Map<String, dynamic> data) {
    final Map<String, Surah> quranMap = {};
    final List<dynamic> quranList = data['quran'] as List;
    final Map<int, List<Ayah>> chapterAyahs = {};

    // Group all verses by chapter number
    for (var entry in quranList) {
      final chapterNum = entry['chapter'] ?? entry['number'] ?? 0;
      if (chapterNum == 0) continue;
      final ayah = Ayah(
        numberInSurah: entry['verse'] ?? entry['numberInSurah'],
        text: entry['text'],
      );
      chapterAyahs.putIfAbsent(chapterNum, () => []).add(ayah);
    }

    // Create Surah objects for each chapter
    chapterAyahs.forEach((chapter, ayahs) {
      quranMap[chapter.toString()] = Surah(
        number: chapter,
        name: 'Surah $chapter',
        englishName: 'Chapter $chapter',
        ayahs: ayahs,
      );
    });

    return quranMap;
  }

  // Get a specific surah with translation and transliteration
  Future<Map<String, dynamic>> getSurahWithTranslation(int surahNumber, String translatorId) async {
    if (_arabicQuran.isEmpty) {
      await loadQuranData();
    }

    final surahKey = surahNumber.toString();

    // Get Arabic surah
    final arabicSurah = _arabicQuran[surahKey];

    // Get translation
    final translationSurah = _translations[translatorId]?[surahKey];

    if (arabicSurah == null) {
      _log('Arabic surah $surahNumber not found');
      return {
        'arabic': null,
        'translation': null,
        'transliteration': <String, String>{},
        'error': 'Surah not found'
      };
    }

    // Create transliteration for each ayah
    Map<String, String> transliterations = {};

    // Check if we have pre-loaded transliterations for this surah
    final surahTransliterations = _transliterations[surahKey];

    if (surahTransliterations != null && surahTransliterations.isNotEmpty) {
      _log('Using pre-loaded transliterations for surah $surahNumber');

      // Use pre-loaded transliterations
      for (var ayah in arabicSurah.ayahs) {
        final ayahKey = ayah.numberInSurah.toString();
        final transliteration = surahTransliterations[ayahKey] ?? '';
        transliterations[ayahKey] = transliteration;
      }
    } else {
      _log('No transliterations available for surah $surahNumber');
    }

    _log('✅ Successfully prepared surah $surahNumber with ${transliterations.length} transliterations');

    return {
      'arabic': arabicSurah,
      'translation': translationSurah,
      'transliteration': transliterations,
    };
  }
}
